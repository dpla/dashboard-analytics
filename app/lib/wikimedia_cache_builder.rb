require "net/http"
require "json"
require "time"

class WikimediaCacheBuilder
  INSTITUTIONS_URL  = "https://raw.githubusercontent.com/dpla/ingestion3/main/src/main/resources/wiki/institutions_v2.json"
  WIKIDATA_API_URL  = "https://www.wikidata.org/w/api.php"
  CIM_BASE_URL      = "https://wikimedia.org/api/rest_v1/metrics/commons-analytics"
  # Fetch all months in one call by using a wide date window.
  # Snapshot: /{category}/{start}/{end}  — date format YYYYMMDD
  # Pageviews: /{category}/deep/all-wikis/{start}/{end}
  CIM_SNAPSHOT_URL  = "#{CIM_BASE_URL}/category-metrics-snapshot/%s/20231101/99991231"
  CIM_PAGEVIEWS_URL = "#{CIM_BASE_URL}/pageviews-per-category-monthly/%s/deep/all-wikis/00000101/99991231"
  THREAD_POOL_SIZE  = 20
  BATCH_SIZE        = 50  # MediaWiki anonymous API limit
  # Serialises all CIM HTTP requests to a single in-flight connection.
  # The CIM API has no published rate limit and throttles at the storage layer;
  # since the rebuild only runs monthly, throughput is not a concern and
  # sequential access is the safest way to avoid 429s entirely.
  CIM_CONCURRENCY   = 1
  CIM_MAX_RETRIES   = 3

  def self.rebuild
    new.rebuild
  end

  def rebuild
    Rails.logger.error "[WikimediaCacheBuilder] Starting rebuild"
    @cim_semaphore = SizedQueue.new(CIM_CONCURRENCY)
    CIM_CONCURRENCY.times { @cim_semaphore << true }
    institutions = fetch_json(INSTITUTIONS_URL)

    # Sync contributor participant flags to DB first (fast, DB-only, no external calls).
    sync_participant_flags(institutions)

    work_items   = build_work_items(institutions)

    Rails.logger.error "[WikimediaCacheBuilder] #{work_items.size} work items to process"

    # Resolve each unique Wikidata ID to a Commons category in batches of 50
    # via the anonymous MediaWiki API (~55 requests for Phase 1, ~8 for Phase 2).
    unique_ids      = work_items.map { |i| i[:wikidata_id] }.uniq
    wikidata_to_cat = batch_resolve_commons_categories(unique_ids)

    processable = work_items.select { |i| wikidata_to_cat.key?(i[:wikidata_id]) }
    Rails.logger.error "[WikimediaCacheBuilder] #{processable.size}/#{work_items.size} items have resolvable Commons categories"

    queue = Queue.new
    processable.each { |item| queue << item }
    THREAD_POOL_SIZE.times { queue << :stop }

    threads = THREAD_POOL_SIZE.times.map do
      Thread.new do
        loop do
          item = queue.pop
          break if item == :stop
          process_item(item, wikidata_to_cat[item[:wikidata_id]])
        end
      end
    end

    threads.each(&:join)
    Rails.logger.error "[WikimediaCacheBuilder] Rebuild complete"
  end

  private

  # Writes each contributor's participant status to the wikimedia_participants
  # table based on the upload flag in institutions_v2.json. Hub-level
  # upload: true cascades to all contributors in that hub. Called at the start
  # of every rebuild so the page-load path never needs to make external API
  # calls to determine participant status.
  def sync_participant_flags(institutions)
    rows = []
    institutions.each do |hub_name, hub_data|
      hub_upload = hub_data["upload"] == true
      (hub_data["institutions"] || {}).each do |contributor_name, contributor_data|
        next unless contributor_data["Wikidata"].present?
        contrib_upload = contributor_data["upload"] == true
        rows << {
          hub:         hub_name,
          contributor: contributor_name,
          participant: hub_upload || contrib_upload
        }
      end
    end

    # Delete-then-insert inside a transaction so stale rows (contributors removed
    # from institutions_v2.json) are cleaned up atomically with no window where
    # the table is empty.
    ActiveRecord::Base.connection_pool.with_connection do
      ActiveRecord::Base.transaction do
        WikimediaParticipant.delete_all
        rows.each_slice(100) do |batch|
          WikimediaParticipant.upsert_all(batch, unique_by: [:hub, :contributor])
        end
      end
    end

    Rails.logger.error "[WikimediaCacheBuilder] Synced participant flags for #{rows.size} contributors"
  end

  def build_work_items(institutions)
    items = []
    institutions.each do |hub_name, hub_data|
      hub_wikidata = hub_data["Wikidata"]&.strip
      items << { hub: hub_name, contributor: "", wikidata_id: hub_wikidata } if hub_wikidata.present?

      (hub_data["institutions"] || {}).each do |contributor_name, contributor_data|
        contrib_wikidata = contributor_data["Wikidata"]&.strip
        items << { hub: hub_name, contributor: contributor_name, wikidata_id: contrib_wikidata } if contrib_wikidata.present?
      end
    end
    items
  end

  # Resolves an array of Wikidata IDs to Commons category names in two batched
  # phases via the Wikidata API (50 IDs per request):
  #   Phase 1 — fetch P8464 claims: each institution's Wikidata item carries a
  #              P8464 value that is the Q-id of the Wikidata item for its
  #              Commons category (e.g. Q112194444 → Q113547185).
  #   Phase 2 — fetch sitelinks for those category Q-ids: the commonswiki
  #              sitelink title gives the Commons category name
  #              (e.g. "Category:Media contributed by Northwest Digital Heritage").
  # Returns { wikidata_id => category_name } for all successfully resolved IDs.
  def batch_resolve_commons_categories(wikidata_ids)
    # Phase 1: resolve each institution/hub Wikidata ID to its Commons category Q-id via P8464
    wikidata_to_cat_qid = batch_fetch_entities(WIKIDATA_API_URL, wikidata_ids, "claims") do |entity|
      (entity.dig("claims", "P8464") || [])
        .first&.dig("mainsnak", "datavalue", "value", "id")
    end

    Rails.logger.error "[WikimediaCacheBuilder] Phase 1: #{wikidata_to_cat_qid.size}/#{wikidata_ids.size} Wikidata IDs resolved to P8464 category Q-ids"

    # Phase 2: resolve each category Q-id to its Commons category name via commonswiki sitelink
    unique_cat_qids  = wikidata_to_cat_qid.values.uniq
    cat_qid_to_name  = batch_fetch_entities(WIKIDATA_API_URL, unique_cat_qids, "sitelinks") do |entity|
      title = entity.dig("sitelinks", "commonswiki", "title")
      title&.sub(/\ACategory:/i, "")&.gsub(" ", "_")
    end

    Rails.logger.error "[WikimediaCacheBuilder] Phase 2: #{cat_qid_to_name.size}/#{unique_cat_qids.size} category Q-ids resolved to Commons category names"

    wikidata_to_cat_qid.each_with_object({}) do |(wikidata_id, cat_qid), result|
      cat = cat_qid_to_name[cat_qid]
      result[wikidata_id] = cat if cat
    end
  end

  # Fetches entities from a MediaWiki API in batches of 50, reusing a single
  # TCP connection per invocation. Yields each entity hash; stores the return
  # value if non-nil. Returns { entity_id => value }.
  def batch_fetch_entities(api_url, ids, props, &extractor)
    uri    = URI(api_url)
    result = {}
    failed = 0

    Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 30) do |http|
      ids.each_slice(BATCH_SIZE) do |batch|
        params   = { action: "wbgetentities", ids: batch.join("|"),
                     format: "json", props: props }
        headers  = { "User-Agent" => "DPLA Analytics Dashboard/1.0" }
        response = http_get_with_retry(http, "#{uri.path}?#{URI.encode_www_form(params)}", headers)
        response.value
        data = JSON.parse(response.body)

        if data["error"]
          Rails.logger.error "[WikimediaCacheBuilder] #{uri.host} API error: #{data['error']['code']}: #{data['error']['info']}"
          failed += 1
          next
        end

        (data["entities"] || {}).each do |id, entity|
          next if entity["missing"]
          value = extractor.call(entity)
          result[id] = value if value
        end
      rescue StandardError => e
        failed += 1
        Rails.logger.error "[WikimediaCacheBuilder] #{uri.host} batch failed: #{e.message}"
      end
    end

    Rails.logger.error "[WikimediaCacheBuilder] #{uri.host}: #{result.size} resolved, #{failed} batches failed" if failed > 0
    result
  end

  # category is pre-resolved by the caller to avoid redundant API calls.
  def process_item(item, category)
    fetch_and_upsert(item[:hub], item[:contributor], category)
  rescue StandardError => e
    Rails.logger.error "[WikimediaCacheBuilder] Error processing #{item.inspect}: #{e.message}"
  end

  def fetch_and_upsert(hub, contributor, category)
    # Each fetch acquires its own semaphore slot so actual in-flight HTTP
    # requests are capped at CIM_CONCURRENCY, not CIM_CONCURRENCY × 2.
    snap_t = Thread.new { with_cim_slot { fetch_snapshot(category) } }
    pv_t   = Thread.new { with_cim_slot { fetch_pageviews(category) } }
    snapshot_data  = snap_t.value
    pageviews_data = pv_t.value

    return if snapshot_data.empty? && pageviews_data.empty?

    # Upsert snapshot and pageview data separately so that a failed API call
    # (returning {}) never overwrites previously cached values with nil.
    if snapshot_data.any?
      # Snapshot fields use hyphenated names matching the API response keys.
      # -deep variants include subcategories (category-scope=deep).
      snap_rows = snapshot_data.map do |month, snap|
        {
          hub:            hub,
          contributor:    contributor,
          month:          month,
          upload_count:   snap["media-file-count-deep"],
          files_used:     snap["used-media-file-count-deep"],
          pages_enhanced: snap["leveraging-page-count-deep"]
        }
      end
      upsert_cache_rows(snap_rows, [:upload_count, :files_used, :pages_enhanced])
    end

    if pageviews_data.any?
      pv_rows = pageviews_data.map do |month, views|
        { hub: hub, contributor: contributor, month: month, page_views: views }
      end
      upsert_cache_rows(pv_rows, [:page_views])
    end

    Rails.logger.debug "[WikimediaCacheBuilder] Upserted for #{hub} / #{contributor.presence || 'hub'}: #{snapshot_data.size} snap months, #{pageviews_data.size} pv months"
  end

  # Returns { "YYYY-MM" => { "media-file-count-deep" => N, ... } }
  # Makes a single API call covering all months.
  def fetch_snapshot(category)
    url  = format(CIM_SNAPSHOT_URL, URI.encode_www_form_component(category))
    data = fetch_json(url)

    return {} unless data.is_a?(Hash) && data["items"].is_a?(Array)

    data["items"].each_with_object({}) do |item, hash|
      month = timestamp_to_month(item["timestamp"])
      hash[month] = item if month
    end
  rescue StandardError => e
    Rails.logger.error "[WikimediaCacheBuilder] fetch_snapshot failed for #{category}: #{e.message}"
    {}
  end

  # Returns { "YYYY-MM" => page_view_count }
  # Makes a single API call covering all months.
  def fetch_pageviews(category)
    url  = format(CIM_PAGEVIEWS_URL, URI.encode_www_form_component(category))
    data = fetch_json(url)

    return {} unless data.is_a?(Hash) && data["items"].is_a?(Array)

    data["items"].each_with_object({}) do |entry, hash|
      month = timestamp_to_month(entry["timestamp"])
      views = entry["pageview-count"]
      hash[month] = views.to_i if month && views
    end
  rescue StandardError => e
    Rails.logger.error "[WikimediaCacheBuilder] fetch_pageviews failed for #{category}: #{e.message}"
    {}
  end

  # "2025-01-01 00:00:00.000Z" → "2025-01"
  def timestamp_to_month(ts)
    ts&.slice(0, 7)
  end

  def fetch_json(url)
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: 30) do |http|
      fetch_json_via(http, url)
    end
  end

  # Upserts rows into wikimedia_cache, borrowing a DB connection only for the
  # duration of the write so the pool isn't exhausted by idle worker threads.
  def upsert_cache_rows(rows, update_only_cols)
    ActiveRecord::Base.connection_pool.with_connection do
      WikimediaCache.upsert_all(
        rows,
        unique_by: [:hub, :contributor, :month],
        update_only: update_only_cols
      )
    end
  end

  # Reuse an already-open Net::HTTP connection.
  # Raises Net::HTTPError for non-2xx responses so callers' rescue blocks log
  # the failure instead of silently parsing an error response body as JSON.
  def fetch_json_via(http, url)
    uri      = URI(url)
    headers  = { "User-Agent" => "DPLA Analytics Dashboard/1.0" }
    response = http_get_with_retry(http, uri.request_uri, headers)
    response.value
    JSON.parse(response.body)
  end

  # Performs an HTTP GET, retrying up to CIM_MAX_RETRIES times on 429.
  # Uses linear backoff (Retry-After × attempt number) so the storage layer
  # has progressively more time to recover between attempts.
  def http_get_with_retry(http, request_uri, headers)
    response = http.get(request_uri, headers)
    CIM_MAX_RETRIES.times do |attempt|
      break unless response.is_a?(Net::HTTPTooManyRequests)
      base_wait = parse_retry_after(response["Retry-After"])
      wait      = base_wait * (attempt + 1)
      Rails.logger.error "[WikimediaCacheBuilder] 429 from #{http.address}, " \
                         "retry #{attempt + 1}/#{CIM_MAX_RETRIES} in #{wait}s"
      sleep(wait)
      response = http.get(request_uri, headers)
    end
    response
  end

  # Parses a Retry-After header value (integer seconds or HTTP-date).
  # Falls back to 10s if the value is absent, unparseable, or non-positive.
  def parse_retry_after(value)
    return 10 unless value

    wait = Integer(value)
    wait > 0 ? wait : 10
  rescue ArgumentError, TypeError
    begin
      wait = (Time.httpdate(value) - Time.now).ceil
      wait > 0 ? wait : 10
    rescue ArgumentError, TypeError
      10
    end
  end

  def with_cim_slot
    @cim_semaphore.pop
    begin
      yield
    ensure
      @cim_semaphore << true
    end
  end
end

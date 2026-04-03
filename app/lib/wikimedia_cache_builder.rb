require "net/http"
require "json"

class WikimediaCacheBuilder
  INSTITUTIONS_URL  = "https://raw.githubusercontent.com/dpla/ingestion3/main/src/main/resources/wiki/institutions_v2.json"
  WIKIDATA_API_URL  = "https://www.wikidata.org/w/api.php"
  COMMONS_API_URL   = "https://commons.wikimedia.org/w/api.php"
  CIM_BASE_URL      = "https://wikimedia.org/api/rest_v1/metrics/commons-analytics"
  # Fetch all months in one call by using a wide date window.
  # Snapshot: /{category}/{start}/{end}  — date format YYYYMMDD
  # Pageviews: /{category}/deep/all-wikis/{start}/{end}
  CIM_SNAPSHOT_URL  = "#{CIM_BASE_URL}/category-metrics-snapshot/%s/20231101/99991231"
  CIM_PAGEVIEWS_URL = "#{CIM_BASE_URL}/pageviews-per-category-monthly/%s/deep/all-wikis/00000101/99991231"
  THREAD_POOL_SIZE  = 20
  BATCH_SIZE        = 50  # MediaWiki anonymous API limit

  def self.rebuild
    new.rebuild
  end

  def rebuild
    institutions = fetch_json(INSTITUTIONS_URL)

    # Sync contributor participant flags to DB first (fast, DB-only, no external calls).
    sync_participant_flags(institutions)

    work_items   = build_work_items(institutions)

    Rails.logger.info "[WikimediaCacheBuilder] #{work_items.size} work items to process"

    # Resolve each unique Wikidata ID to a Commons category in batches of 50
    # via the anonymous MediaWiki API (~55 requests for Phase 1, ~8 for Phase 2).
    unique_ids      = work_items.map { |i| i[:wikidata_id] }.uniq
    wikidata_to_cat = batch_resolve_commons_categories(unique_ids)

    processable = work_items.select { |i| wikidata_to_cat.key?(i[:wikidata_id]) }
    Rails.logger.info "[WikimediaCacheBuilder] #{processable.size} items with resolvable categories"

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
    Rails.logger.info "[WikimediaCacheBuilder] Rebuild complete"
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

    rows.each_slice(100) do |batch|
      WikimediaParticipant.upsert_all(batch, unique_by: [:hub, :contributor])
    end

    Rails.logger.info "[WikimediaCacheBuilder] Synced participant flags for #{rows.size} contributors"
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
  # phases via the anonymous MediaWiki API (50 IDs per request):
  #   Phase 1 — wikidata.org: fetch P8464 claims to get MediaInfo entity IDs
  #   Phase 2 — commons.wikimedia.org: fetch sitelinks to get category titles
  # Returns { wikidata_id => category_name } for all successfully resolved IDs.
  def batch_resolve_commons_categories(wikidata_ids)
    # Phase 1: Wikidata — resolve each ID to a MediaInfo entity ID via P8464 claim
    wikidata_to_m_id = batch_fetch_entities(WIKIDATA_API_URL, wikidata_ids, "claims") do |entity|
      (entity.dig("claims", "P8464") || [])
        .first&.dig("mainsnak", "datavalue", "value", "id")
    end

    Rails.logger.info "[WikimediaCacheBuilder] #{wikidata_to_m_id.size} Wikidata IDs resolved to P8464 MediaInfo entities"

    # Phase 2: Commons — resolve each MediaInfo entity ID to a category name
    unique_m_ids     = wikidata_to_m_id.values.uniq
    m_id_to_category = batch_fetch_entities(COMMONS_API_URL, unique_m_ids, "sitelinks") do |entity|
      title = entity.dig("sitelinks", "commonswiki", "title")
      title&.sub(/\ACategory:/i, "")&.gsub(" ", "_")
    end

    # Combine: map wikidata_id -> category_name
    wikidata_to_m_id.each_with_object({}) do |(wikidata_id, m_id), result|
      cat = m_id_to_category[m_id]
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
        response = http.get("#{uri.path}?#{URI.encode_www_form(params)}", headers)
        if response.is_a?(Net::HTTPTooManyRequests)
          wait = response["Retry-After"]&.to_i || 10
          Rails.logger.info "[WikimediaCacheBuilder] 429 from #{uri.host}, retrying in #{wait}s"
          sleep(wait)
          response = http.get("#{uri.path}?#{URI.encode_www_form(params)}", headers)
        end
        response.value
        data = JSON.parse(response.body)

        if data["error"]
          Rails.logger.warn "[WikimediaCacheBuilder] #{uri.host} API error: #{data['error']['code']}: #{data['error']['info']}"
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
        Rails.logger.debug "[WikimediaCacheBuilder] #{uri.host} batch failed: #{e.message}"
      end
    end

    Rails.logger.info "[WikimediaCacheBuilder] #{uri.host}: #{result.size} resolved, #{failed} batches failed" if failed > 0
    result
  end

  # category is pre-resolved by the caller to avoid redundant API calls.
  def process_item(item, category)
    fetch_and_upsert(item[:hub], item[:contributor], category)
  rescue StandardError => e
    Rails.logger.error "[WikimediaCacheBuilder] Error processing #{item.inspect}: #{e.message}"
  end

  def fetch_and_upsert(hub, contributor, category)
    # The 20-thread outer pool already provides sufficient I/O parallelism;
    # spawning additional threads here would cause unbounded thread proliferation.
    snapshot_data  = fetch_snapshot(category)
    pageviews_data = fetch_pageviews(category)

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
    Rails.logger.debug "[WikimediaCacheBuilder] fetch_snapshot failed for #{category}: #{e.message}"
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
    Rails.logger.debug "[WikimediaCacheBuilder] fetch_pageviews failed for #{category}: #{e.message}"
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
    response = http.get(uri.request_uri, "User-Agent" => "DPLA Analytics Dashboard/1.0")
    response.value
    JSON.parse(response.body)
  end
end

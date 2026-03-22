require "net/http"
require "json"

class WikimediaCacheBuilder
  INSTITUTIONS_URL  = "https://raw.githubusercontent.com/dpla/ingestion3/main/src/main/resources/wiki/institutions_v2.json"
  WIKIDATA_URL      = "https://www.wikidata.org/wiki/Special:EntityData/%s.json"
  CIM_BASE_URL      = "https://wikimedia.org/api/rest_v1/metrics/commons-analytics"
  # Fetch all months in one call by using a wide date window.
  # Snapshot: /{category}/{start}/{end}  — date format YYYYMMDD
  # Pageviews: /{category}/deep/all-wikis/{start}/{end}
  CIM_SNAPSHOT_URL  = "#{CIM_BASE_URL}/category-metrics-snapshot/%s/20231101/99991231"
  CIM_PAGEVIEWS_URL = "#{CIM_BASE_URL}/pageviews-per-category-monthly/%s/deep/all-wikis/00000101/99991231"
  THREAD_POOL_SIZE  = 20

  def self.rebuild
    new.rebuild
  end

  def rebuild
    institutions = fetch_json(INSTITUTIONS_URL)
    work_items   = build_work_items(institutions)

    Rails.logger.info "[WikimediaCacheBuilder] #{work_items.size} work items to process"

    # Resolve each unique Wikidata ID to a Commons category once, avoiding
    # redundant API calls when multiple contributors share the same Wikidata ID.
    # Done sequentially — Wikidata rate-limits concurrent connections, causing
    # silent failures when too many threads hit the API simultaneously.
    unique_ids      = work_items.map { |i| i[:wikidata_id] }.uniq
    wikidata_to_cat = {}
    unique_ids.each do |wikidata_id|
      cat = resolve_commons_category(wikidata_id)
      wikidata_to_cat[wikidata_id] = cat if cat
    end

    processable = work_items.select { |i| wikidata_to_cat.key?(i[:wikidata_id]) }
    Rails.logger.info "[WikimediaCacheBuilder] #{processable.size} items with resolvable categories"

    queue = Queue.new
    processable.each { |item| queue << item }
    THREAD_POOL_SIZE.times { queue << :stop }

    threads = THREAD_POOL_SIZE.times.map do
      Thread.new do
        # Explicitly check out a connection per thread so upsert_all results
        # are committed and visible to all connections (not just the thread's
        # own implicit connection, which Rails doesn't auto-release on join).
        ActiveRecord::Base.connection_pool.with_connection do
          loop do
            item = queue.pop
            break if item == :stop
            process_item(item, wikidata_to_cat[item[:wikidata_id]])
          end
        end
      end
    end

    threads.each(&:join)
    Rails.logger.info "[WikimediaCacheBuilder] Rebuild complete"
  end

  private

  def build_work_items(institutions)
    items = []
    institutions.each do |hub_name, hub_data|
      hub_wikidata = hub_data["Wikidata"]
      items << { hub: hub_name, contributor: "", wikidata_id: hub_wikidata } if hub_wikidata.present?

      (hub_data["institutions"] || {}).each do |contributor_name, contributor_data|
        contrib_wikidata = contributor_data["Wikidata"]
        items << { hub: hub_name, contributor: contributor_name, wikidata_id: contrib_wikidata } if contrib_wikidata.present?
      end
    end
    items
  end

  # category is pre-resolved by the caller to avoid redundant API calls.
  def process_item(item, category)
    fetch_and_upsert(item[:hub], item[:contributor], category)
  rescue => e
    Rails.logger.error "[WikimediaCacheBuilder] Error processing #{item.inspect}: #{e.message}"
  end

  # Resolves a Wikidata entity ID to a Wikimedia Commons category name via the
  # P8464 claim. Reuses a single TCP+TLS connection for both Wikidata lookups.
  def resolve_commons_category(wikidata_id)
    wikidata_uri = URI("https://www.wikidata.org")

    Net::HTTP.start(wikidata_uri.host, wikidata_uri.port, use_ssl: true, read_timeout: 30) do |http|
      entity_data = fetch_json_via(http, format(WIKIDATA_URL, wikidata_id))
                      .dig("entities", wikidata_id)
      return nil unless entity_data

      # P8464 = MediaInfo entity on Wikimedia Commons for this category
      commons_entity_id = (entity_data.dig("claims", "P8464") || [])
                            .first&.dig("mainsnak", "datavalue", "value", "id")
      return nil unless commons_entity_id

      title = fetch_json_via(http, format(WIKIDATA_URL, commons_entity_id))
                .dig("entities", commons_entity_id, "sitelinks", "commonswiki", "title")
      return nil unless title

      # Strip "Category:" prefix; CIM API uses underscored category names
      title.sub(/\ACategory:/i, "").gsub(" ", "_")
    end
  rescue => e
    Rails.logger.debug "[WikimediaCacheBuilder] resolve_commons_category failed for #{wikidata_id}: #{e.message}"
    nil
  end

  def fetch_and_upsert(hub, contributor, category)
    # The 20-thread outer pool already provides sufficient I/O parallelism;
    # spawning additional threads here would cause unbounded thread proliferation.
    snapshot_data  = fetch_snapshot(category)
    pageviews_data = fetch_pageviews(category)

    all_months = (snapshot_data.keys + pageviews_data.keys).uniq
    return if all_months.empty?

    rows = all_months.map do |month|
      snap = snapshot_data[month] || {}
      # Snapshot fields use hyphenated names matching the API response keys.
      # -deep variants include subcategories (category-scope=deep).
      {
        hub:            hub,
        contributor:    contributor,
        month:          month,
        upload_count:   snap["media-file-count-deep"],
        files_used:     snap["used-media-file-count-deep"],
        pages_enhanced: snap["leveraging-page-count-deep"],
        page_views:     pageviews_data[month]
      }
    end

    WikimediaCache.upsert_all(
      rows,
      unique_by: [:hub, :contributor, :month],
      update_only: [:upload_count, :files_used, :pages_enhanced, :page_views]
    )

    Rails.logger.debug "[WikimediaCacheBuilder] Upserted #{rows.size} rows for #{hub} / #{contributor.presence || 'hub'}"
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
  rescue => e
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
  rescue => e
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

  # Reuse an already-open Net::HTTP connection.
  def fetch_json_via(http, url)
    uri      = URI(url)
    response = http.get(uri.request_uri, "User-Agent" => "DPLA Analytics Dashboard/1.0")
    JSON.parse(response.body)
  end
end

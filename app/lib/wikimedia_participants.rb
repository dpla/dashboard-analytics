##
# Determines whether a hub or contributor is a Wikimedia pipeline participant
# by checking whether their Wikidata entity has a P8464 claim (the Commons
# MediaInfo category link). This is the correct signal: an entity with P8464
# has a Commons category and may have analytics data regardless of whether
# it is currently active in an upload run.
#
# The institutions JSON and P8464 lookup results are each cached for 24 hours.
# All Wikidata IDs are resolved in batches of 50 (anonymous API limit), so
# the full ~2,000-ID dataset takes ~40 requests — fast enough to run monthly.
#
class WikimediaParticipants
  INSTITUTIONS_URL = WikimediaCacheBuilder::INSTITUTIONS_URL
  WIKIDATA_API_URL = WikimediaCacheBuilder::WIKIDATA_API_URL
  INSTITUTIONS_KEY = "wikimedia:institutions_v2"
  P8464_KEY        = "wikimedia:p8464_ids"
  CACHE_TTL        = 24.hours
  BATCH_SIZE       = 50

  ##
  # Returns true if the hub's Wikidata entity has a P8464 claim.
  #
  # @param hub [String]
  # @return [Boolean]
  #
  def self.hub?(hub)
    wikidata_id = fetch_institutions.dig(hub, "Wikidata")&.strip
    wikidata_id.present? && fetch_p8464_ids.include?(wikidata_id)
  end

  ##
  # Returns true if the contributor's Wikidata entity has a P8464 claim.
  #
  # @param hub         [String]
  # @param contributor [String]
  # @return [Boolean]
  #
  def self.contributor?(hub, contributor)
    wikidata_id = fetch_institutions.dig(hub, "institutions", contributor, "Wikidata")&.strip
    wikidata_id.present? && fetch_p8464_ids.include?(wikidata_id)
  end

  private_class_method def self.fetch_institutions
    Rails.cache.fetch(INSTITUTIONS_KEY, expires_in: CACHE_TTL) do
      uri = URI(INSTITUTIONS_URL)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                      open_timeout: 5, read_timeout: 10) do |http|
        response = http.get(uri.request_uri, "User-Agent" => "DPLA Analytics Dashboard/1.0")
        unless response.is_a?(Net::HTTPSuccess)
          Rails.logger.error("[WikimediaParticipants] HTTP #{response.code} fetching institutions JSON")
          next {}
        end
        JSON.parse(response.body)
      end
    end
  rescue StandardError => e
    Rails.logger.error("[WikimediaParticipants] Failed to fetch institutions JSON: #{e.message}")
    {}
  end

  # Returns the Set of Wikidata IDs that have a P8464 claim, fetched in
  # batches of 50 from the Wikidata API and cached for 24 hours.
  private_class_method def self.fetch_p8464_ids
    Rails.cache.fetch(P8464_KEY, expires_in: CACHE_TTL) do
      all_ids = collect_wikidata_ids(fetch_institutions)
      resolve_p8464_ids(all_ids)
    end
  rescue StandardError => e
    Rails.logger.error("[WikimediaParticipants] Failed to resolve P8464 IDs: #{e.message}")
    Set.new
  end

  # Collects every non-blank Wikidata ID from the institutions JSON.
  private_class_method def self.collect_wikidata_ids(institutions)
    ids = []
    institutions.each do |_, hub_data|
      ids << hub_data["Wikidata"]&.strip if hub_data["Wikidata"].present?
      (hub_data["institutions"] || {}).each do |_, contrib|
        ids << contrib["Wikidata"]&.strip if contrib["Wikidata"].present?
      end
    end
    ids.compact.uniq
  end

  # Batch-queries the Wikidata API for P8464 claims, returning the Set of
  # IDs that have one. Reuses a single TCP connection for all batches.
  private_class_method def self.resolve_p8464_ids(wikidata_ids)
    result = Set.new
    uri = URI(WIKIDATA_API_URL)

    Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 30) do |http|
      wikidata_ids.each_slice(BATCH_SIZE) do |batch|
        params   = { action: "wbgetentities", ids: batch.join("|"),
                     props: "claims", format: "json" }
        response = http.get("#{uri.path}?#{URI.encode_www_form(params)}",
                            "User-Agent" => "DPLA Analytics Dashboard/1.0")
        next unless response.is_a?(Net::HTTPSuccess)

        data = JSON.parse(response.body)
        (data["entities"] || {}).each do |id, entity|
          next if entity["missing"]
          result << id if entity.dig("claims", "P8464").present?
        end
      rescue StandardError => e
        Rails.logger.warn("[WikimediaParticipants] Batch failed: #{e.message}")
      end
    end

    Rails.logger.info("[WikimediaParticipants] #{result.size}/#{wikidata_ids.size} IDs have P8464")
    result
  end
end

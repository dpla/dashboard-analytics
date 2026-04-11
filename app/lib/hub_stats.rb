class HubStats
  KEY     = "hub-stats/hub_stats.json"
  BWS_KEY = "hub-stats/hub_stats_bws.json"
  EMPTY   = { "hubs" => {} }.freeze

  ##
  # @return [Hash] parsed hub_stats.json: { "generated_at" => ..., "hubs" => { name => { "item_count" => int, "contributors" => { name => count } } } }
  #
  def self.fetch
    Rails.cache.fetch("hub_stats", expires_in: 24.hours) do
      JSON.parse(SThreeResponseBuilder.response(KEY).body.read)
    rescue Aws::S3::Errors::NoSuchKey
      Rails.logger.warn("HubStats: #{KEY} not found in S3 — hub stats not yet generated")
      EMPTY
    end
  end

  ##
  # @return [Hash] same structure as fetch, filtered to BWS-tagged items
  #
  def self.fetch_bws
    Rails.cache.fetch("hub_stats_bws", expires_in: 24.hours) do
      JSON.parse(SThreeResponseBuilder.response(BWS_KEY).body.read)
    rescue Aws::S3::Errors::NoSuchKey
      Rails.logger.warn("HubStats: #{BWS_KEY} not found in S3 — hub stats not yet generated")
      EMPTY
    end
  end
end

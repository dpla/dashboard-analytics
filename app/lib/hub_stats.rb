class HubStats
  KEY     = "hub-stats/hub_stats.json"
  BWS_KEY = "hub-stats/hub_stats_bws.json"
  EMPTY   = { "hubs" => {} }.freeze

  ##
  # @return [Hash] parsed hub_stats.json: { "generated_at" => ..., "hubs" => { name => { "item_count" => int, "contributors" => { name => count } } } }
  #
  def self.fetch
    SThreeResponseBuilder.cached_json(KEY, cache_key: "hub_stats", default: EMPTY)
  end

  ##
  # @return [Hash] same structure as fetch, filtered to BWS-tagged items
  #
  def self.fetch_bws
    SThreeResponseBuilder.cached_json(BWS_KEY, cache_key: "hub_stats_bws", default: EMPTY)
  end
end

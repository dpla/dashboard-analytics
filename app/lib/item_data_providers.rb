class ItemDataProviders
  KEY       = "hub-stats/item_data_providers.json"
  CACHE_KEY = "item_data_providers"
  EMPTY     = { "items" => {} }.freeze

  ##
  # dataProvider (institution) names for DPLA item IDs, from the S3 cache
  # the monthly rebuild writes (generate_hub_stats.py). Empty until the
  # first run. Whole mapping sits in Rails.cache (64MB memory store in
  # production); past ~200k ids, shard the S3 file rather than raise the
  # store size.
  #
  # @return [Hash<String, String>] { item_id => data_provider_name }
  #
  def self.items
    SThreeResponseBuilder.cached_json(KEY, cache_key: CACHE_KEY, default: EMPTY)["items"] || {}
  end
end

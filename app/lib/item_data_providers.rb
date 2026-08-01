class ItemDataProviders
  KEY   = "hub-stats/item_data_providers.json"
  EMPTY = { "items" => {}.freeze }.freeze

  MUTEX = Mutex.new

  ##
  # dataProvider names by DPLA item ID, from the S3 file
  # generate_hub_stats.py writes monthly. Empty until the first run.
  #
  # In-process, not Rails.cache: MemoryStore Marshals on every read, and at
  # ~516k ids that rebuilds the whole hash per request. Same memory either
  # way. Shard by id prefix if it outgrows the process.
  #
  # @return [Hash<String, String>] { item_id => data_provider_name }
  #
  def self.items
    MUTEX.synchronize do
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      return @items if @expires_at && now < @expires_at

      data, ttl = SThreeResponseBuilder.fetch_json(KEY, default: EMPTY)
      @expires_at = now + ttl
      @items = data["items"] || {}
    end
  end
end

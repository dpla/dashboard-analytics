module GaStubs
  def cached_response(columns, rows, totals: {}, total: rows.size)
    GaPersistentCache::CachedResponse.build(columns, rows, totals: totals, total_results: total)
  end

  def stub_ga_cache_passthrough
    Rails.cache.clear
    allow(GaPersistentCache).to receive(:fetch_with_status) { |_key, _end, &block| [block.call, false] }
    allow(GaPersistentCache).to receive(:fetch) { |_key, _end, &block| block.call }
  end

  def stub_new_dimensions_date(date)
    allow(DataWindow).to receive(:new_dimensions_date).and_return(date)
  end
end

RSpec.configure { |config| config.include GaStubs }

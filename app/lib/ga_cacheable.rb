##
# Caching shared by the GA wrapper classes: Rails.cache in front of the
# permanent S3 store, one report per era (see GaEventSchema).
# Unset ivars serialise as "", so keys keep the same positions.
#
module GaCacheable
  CACHE_TTL = 2.hours

  # One builder per era, for the warm job to batch.
  def ga_builders
    eras.map { |era| [era, builder_for(era)] }
  end

  # Cache a response the warm job fetched, so #response skips GA4.
  # Goes to Rails.cache here and to S3 when the range is settled.
  def prefetch(era, ga4_response)
    return if ga4_response.nil?

    key = cache_key(era)
    stored = GaPersistentCache.write(key, ga4_response, era.end_date)
    Rails.cache.write(key, stored || ga4_response, expires_in: stored ? nil : CACHE_TTL)
  end

  private

  def eras
    @eras ||= GaEventSchema.eras(@start_date, @end_date)
  end

  def era_responses
    fetch_eras { |era| fetch_cached(range: era) { builder_for(era).response } }
  end

  # Two eras run at the same time.
  def fetch_eras
    return eras.map { |era| yield era } if eras.one?

    eras.map { |era|
      Thread.new do
        Thread.current.report_on_exception = false
        yield era
      end
    }.map(&:value)
  end

  # Includes the S3 schema version, so bumping it also clears Rails.cache.
  def cache_key(range = nil)
    start_date, end_date = range ? [range.start_date, range.end_date] : [@start_date, @end_date]
    ["ga", GaPersistentCache::SCHEMA_VERSION, self.class.name.underscore,
     *cache_key_parts, start_date, end_date].map(&:to_s).join(":")
  end

  # PssEvents overrides this, since one report serves every hub.
  def cache_key_parts
    [@hub, @contributor, @event_name]
  end

  # Try Rails.cache, then S3, then run the block (live GA4). Responses
  # S3 holds never expire from Rails.cache. Others last CACHE_TTL.
  # memory: false keeps big exports out of the small in-process store.
  def fetch_cached(suffix = nil, memory: true, range: nil, &block)
    key = [cache_key(range), suffix].compact.join(":")
    end_date = range ? range.end_date : @end_date
    permanent = GaPersistentCache.cacheable?(end_date)

    if memory || !permanent
      cached = Rails.cache.read(key)
      return cached unless cached.nil?

      # Read then write, not fetch: the expiry turns on whether S3 took it.
      # A truncated export kept for good would outlive a max_pages increase.
      response, persisted = GaPersistentCache.fetch_with_status(key, end_date, &block)
      Rails.cache.write(key, response, expires_in: persisted ? nil : CACHE_TTL)
      response
    else
      GaPersistentCache.fetch(key, end_date) do
        # S3 missed or refused it. A short-lived copy keeps repeat exports
        # off GA4, under a separate key so it can't be promoted into S3.
        Rails.cache.fetch("#{key}:tmp", expires_in: CACHE_TTL, &block)
      end
    end
  end

  def build_response(columns, rows, totals: {}, total_results: rows.size)
    GaPersistentCache::CachedResponse.build(columns, rows, totals: totals,
                                            total_results: total_results)
  end
end

##
# Shared caching for GA wrapper classes: #cache_key, #fetch_cached
# (Rails.cache over the permanent S3 store), #prefetch for the warm job.
# Unset ivars serialise as empty strings, keeping the key format positional.
#
module GaCacheable
  # In-process TTL for responses the permanent store doesn't hold.
  CACHE_TTL = 2.hours

  ##
  # Inject a batch-fetched response so the next #response call skips GA4.
  # Writes Rails.cache (this task) and, when the range qualifies, S3 (all
  # tasks). Holds the compact form, not the raw Google graph.
  #
  def prefetch(ga4_response)
    return if ga4_response.nil?

    stored = GaPersistentCache.write(cache_key, ga4_response, @end_date)
    @response = stored || ga4_response
    Rails.cache.write(cache_key, @response, expires_in: stored ? nil : CACHE_TTL)
  end

  private

  def cache_key
    [
      "ga",
      self.class.name.underscore,
      @hub,
      @contributor,
      @event_name,
      @start_date,
      @end_date,
    ].map(&:to_s).join(":")
  end

  ##
  # Rails.cache over the permanent S3 store (GaPersistentCache); the block
  # (live GA4) is the last resort. Permanent entries: no Rails.cache
  # expiry. Others: CACHE_TTL.
  #
  # @param suffix [String, nil] appended to cache_key, e.g. "page2" or "multi"
  # @param memory [Boolean] false keeps large payloads (multi-page exports)
  # out of the small in-process store whenever S3 can serve them.
  #
  def fetch_cached(suffix = nil, memory: true, &block)
    key = [cache_key, suffix].compact.join(":")
    permanent = GaPersistentCache.cacheable?(@end_date)

    if memory || !permanent
      Rails.cache.fetch(key, expires_in: permanent ? nil : CACHE_TTL) do
        GaPersistentCache.fetch(key, @end_date, &block)
      end
    else
      GaPersistentCache.fetch(key, @end_date) do
        # S3 missed or declined (e.g. truncated export): short-lived copy so
        # repeat exports skip GA4. Separate key so a pre-settling entry
        # can't be promoted into S3.
        Rails.cache.fetch("#{key}:tmp", expires_in: CACHE_TTL, &block)
      end
    end
  end
end

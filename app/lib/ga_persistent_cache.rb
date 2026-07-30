require 'digest'

##
# Durable S3 store for GA4 report responses.
#
# Completed months only (see DataWindow); their GA4 data never changes.
# Each qualifying response: fetched once, stored in S3, served to every
# task after. Entries never expire. S3 failures fall back to live GA4.
#
class GaPersistentCache
  # The version is the only invalidation: bump on query, page-size, or
  # JSON-shape changes; old objects are never read again. Safe: any month
  # re-fetches from GA4. GaCacheable#cache_key carries the same version, so
  # a bump also skips Rails.cache entries written under the old schema.
  SCHEMA_VERSION = "v1"
  PREFIX = "ga4-cache/#{SCHEMA_VERSION}/"

  # GA4 adjusts recent data for ~72h; don't store the just-completed month
  # until this many days in. One day of margin: Date.current is UTC, the
  # GA4 property is not.
  SETTLING_DAYS = 4

  ##
  # True when a range is storable for good: ends before the current month,
  # final month settled.
  #
  # @param end_date [Date, nil]
  #
  def self.cacheable?(end_date)
    end_date.present? && end_date < settled_boundary
  end

  ##
  # Stored response for key, or run the block (live GA4), store, return.
  # Unstorable ranges pass straight to the block.
  #
  # @param key [String] cache key (see GaCacheable#cache_key)
  # @param end_date [Date, nil] end of the response's date range
  # @yieldreturn [GaResponseBuilder::Ga4Response, Array, nil]
  #
  def self.fetch(key, end_date)
    return yield unless cacheable?(end_date)

    if (cached = read(key))
      cached
    else
      response = yield
      write(key, response, end_date) || response
    end
  end

  ##
  # Store when the range qualifies. Returns the compact stored form (what a
  # later read returns); nil if nothing stored.
  #
  def self.write(key, response, end_date)
    return if response.nil? || !cacheable?(end_date) || truncated?(response)

    data = serialize(response)
    SThreeResponseBuilder.put(s3_key(key), JSON.generate(data))
    deserialize(data)
  rescue StandardError => e
    Rails.logger.warn("GaPersistentCache: failed to write #{key}: #{e.class}: #{e.message}")
    Sentry.capture_exception(e)
    nil
  end

  def self.read(key)
    deserialize(JSON.parse(SThreeResponseBuilder.response(s3_key(key)).body.read))
  rescue Aws::S3::Errors::NoSuchKey
    # Quiet misses need s3:ListBucket; without it S3 answers AccessDenied
    # and every miss lands below.
    nil
  rescue StandardError => e
    Rails.logger.warn("GaPersistentCache: failed to read #{key}: #{e.class}: #{e.message}")
    Sentry.capture_exception(e)
    nil
  end

  # Export capped by max_pages: fewer rows than GA4 reported. Never freeze
  # it; a later cap increase must take effect.
  def self.truncated?(response)
    return false unless response.is_a?(Array) && response.any?

    fetched = response.sum { |page| page.rows&.size.to_i }
    response.first.total_results.to_i > fetched
  end

  # First day of the earliest month still subject to change.
  def self.settled_boundary
    (Date.current - SETTLING_DAYS).beginning_of_month
  end

  # Readable slug + digest of the full key for uniqueness.
  def self.s3_key(key)
    slug = key.gsub(/[^0-9A-Za-z:._-]+/, "-")[0, 150]
    "#{PREFIX}#{slug}-#{Digest::MD5.hexdigest(key)}.json"
  end

  # Multi-page (Array) becomes a JSON array; a single response, a JSON object.
  def self.serialize(response)
    return response.map { |page| serialize_response(page) } if response.is_a?(Array)

    serialize_response(response)
  end

  def self.serialize_response(response)
    {
      "columns"       => response.column_headers.map(&:name),
      "rows"          => response.rows,
      "totals"        => response.totals_for_all_results,
      "total_results" => response.total_results,
    }
  end

  def self.deserialize(data)
    return data.map { |page| deserialize_response(page) } if data.is_a?(Array)

    deserialize_response(data)
  end

  def self.deserialize_response(data)
    CachedResponse.new(
      data["columns"].map { |name| GaResponseBuilder::Ga4Response::ColumnHeader.new(name) },
      data["rows"],
      data["totals"],
      data["total_results"]
    )
  end

  private_class_method :read, :truncated?, :settled_boundary, :s3_key,
                       :serialize, :serialize_response,
                       :deserialize, :deserialize_response

  ##
  # Read-side stand-in for Ga4Response: same interface over stored JSON.
  #
  CachedResponse = Struct.new(:column_headers, :rows,
                              :totals_for_all_results, :total_results) do
    alias_method :row_count, :total_results
  end
end

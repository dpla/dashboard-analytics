class SThreeResponseBuilder

  ##
  # @param [String] S3 key (i.e. filepath)
  #
  # @return [Aws::S3::Types::GetObjectOutput]
  #
  # @raise [Aws::S3::Errors::NoSuchKey]
  # The specified key does not exist. Do not retry.
  #
  # @raise [S3::Errors::InternalError]
  # An error occurred on the server and the request can be retried.
  #
  # Documentation about possible errors:
  # https://docs.aws.amazon.com/sdkforruby/api/Aws/S3/Errors.html
  #
  def self.response(key)
    self.client.get_object({ bucket: self.bucket, key: key })
  end

  def self.list(prefix)
    self.client.list_objects({ bucket: self.bucket, prefix: prefix })
  end

  ##
  # Write an object. Task role needs s3:PutObject.
  #
  # @param key [String] S3 key (i.e. filepath)
  # @param body [String] object content
  #
  def self.put(key, body)
    self.client.put_object({ bucket: self.bucket, key: key, body: body })
  end

  ##
  # Fetch and parse a JSON file from S3, cached 24h in Rails.cache.
  # Missing key: returns +default+, cached 24h (not generated yet). Other
  # failures: returns +default+, cached 5 minutes so a transient S3 error
  # can't empty the site for a day. Pages degrade instead of erroring.
  #
  # @param key [String] S3 key
  # @param cache_key [String] Rails.cache key
  # @param default [Hash] value to return and cache on failure
  #
  # @return [Hash] parsed JSON
  #
  def self.cached_json(key, cache_key:, default:)
    cached = Rails.cache.read(cache_key)
    return cached if cached

    data = JSON.parse(response(key).body.read)
    # Valid JSON that isn't an object ([], null) would cache for 24h and
    # raise in every caller that string-indexes it.
    raise TypeError, "expected Hash, got #{data.class}" unless data.is_a?(Hash)
    warn_if_stale(key, data)
    Rails.cache.write(cache_key, data, expires_in: 24.hours)
    data
  rescue Aws::S3::Errors::NoSuchKey
    message = "SThreeResponseBuilder: #{key} not found in S3 (not yet generated)"
    Rails.logger.warn(message)
    Sentry.capture_message(message)
    Rails.cache.write(cache_key, default, expires_in: 24.hours)
    default
  rescue StandardError => e
    Rails.logger.error("SThreeResponseBuilder: failed to load #{key}: #{e.class}: #{e.message}")
    Sentry.capture_exception(e)
    Rails.cache.write(cache_key, default, expires_in: 5.minutes)
    default
  end

  # The monthly generator is the only writer; a stopped one silently serves
  # stale data, so make that loud. At most one alert per cache period per task.
  STALE_AFTER = 45.days

  def self.warn_if_stale(key, data)
    generated_at = Time.iso8601(data["generated_at"].to_s) rescue nil
    return unless generated_at && generated_at < STALE_AFTER.ago

    message = "SThreeResponseBuilder: #{key} is stale (generated_at #{generated_at.to_date})"
    Rails.logger.error(message)
    Sentry.capture_message(message)
  end

  private

  def self.client
    # TODO: Define region in config settings
    # By default, the client retries 500 and some 400 errors three times.
    @@client ||= Aws::S3::Client.new(region: 'us-east-1')
  end

  ##
  # @return String
  def self.bucket
    Settings.s3.bucket
  end
end

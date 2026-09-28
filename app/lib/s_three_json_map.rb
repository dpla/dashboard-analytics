##
# A JSON map in S3, { field => { key => value } },
# held in the process for as long as fetch_json says.
#
module SThreeJsonMap
  # A nil stale_after suits a file that nothing regenerates on a schedule.
  def s3_json_map(key, field, stale_after: SThreeResponseBuilder::STALE_AFTER)
    @s3_key = key
    @s3_field = field
    @s3_stale_after = stale_after
    @s3_mutex = Mutex.new
  end

  # The map. Empty until the file exists in S3.
  def entries
    @s3_mutex.synchronize do
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      return @entries if @expires_at && now < @expires_at

      data, ttl = SThreeResponseBuilder.fetch_json(
        @s3_key, default: { @s3_field => {} }, stale_after: @s3_stale_after)
      @expires_at = now + ttl.to_f
      @entries = entries_hash(data[@s3_field] || {})
    end
  end

  private

  # fetch_json only checks the top level.
  def entries_hash(entries)
    return entries if entries.is_a?(Hash)

    message = "#{name}: #{@s3_key} #{@s3_field} is a #{entries.class}, not a Hash"
    Rails.logger.error(message)
    Sentry.capture_message(message)
    {}
  end
end

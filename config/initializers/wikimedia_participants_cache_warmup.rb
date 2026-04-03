# Pre-warms the WikimediaParticipants P8464 cache in a background thread at
# boot time. Without this, the first request to any hub or contributor page
# after a deploy blocks for ~30 seconds while ~40 sequential Wikidata API
# calls are made to populate the cache. Since production uses memory_store
# (per-process), the cache is cold on every deploy.
#
# The thread is daemonised so it doesn't prevent process exit, and all errors
# are rescued so a transient Wikidata outage cannot prevent the app from
# starting.
Rails.application.config.after_initialize do
  Thread.new do
    Rails.logger.info("[WikimediaParticipants] Starting cache warm-up in background thread")
    WikimediaParticipants.warm_cache!
    Rails.logger.info("[WikimediaParticipants] Cache warm-up complete")
  rescue StandardError => e
    Rails.logger.error("[WikimediaParticipants] Cache warm-up failed: #{e.message}")
  end
end

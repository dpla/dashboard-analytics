namespace :cache do
  desc "Pre-warm GA4 caches for all hubs (run as a one-off ECS task with " \
       "LOG_LEVEL=info and GA4_READ_TIMEOUT_SEC=120)"
  task warm: :environment do
    WarmComparisonCacheJob.perform_now
  end
end

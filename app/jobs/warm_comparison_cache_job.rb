class WarmComparisonCacheJob < ApplicationJob
  queue_as :default

  # Pre-warms the GA4 and S3 caches for all hubs using the all-time
  # date range (the most-visited view). Running this nightly ensures the
  # first user of the day gets fast page loads instead of cold-cache latency.
  #
  # Schedule via AWS EventBridge rule targeting an ECS task, e.g.:
  #   cron(0 5 * * ? *)   # 05:00 UTC daily
  #
  def perform
    start_date = Date.new(2012, 1, 1)
    end_date   = Date.today

    Hub.all.map(&:name).each do |hub_name|
      warm_hub(hub_name, start_date, end_date)
    rescue => e
      Rails.logger.error("WarmComparisonCacheJob: failed warming #{hub_name}: #{e.message}")
      Sentry.capture_exception(e)
    end
  end

  private

  def warm_hub(hub_name, start_date, end_date)
    Rails.logger.info("WarmComparisonCacheJob: warming cache for #{hub_name}")

    website_overview = WebsiteOverviewByContributor.build do |b|
      b.hub        = hub_name
      b.start_date = start_date
      b.end_date   = end_date
    end

    website_events = WebsiteEventsByContributor.build do |b|
      b.hub        = hub_name
      b.start_date = start_date
      b.end_date   = end_date
    end

    metadata_completeness = MetadataCompleteness.build do |b|
      b.hub      = hub_name
      b.end_date = end_date
    end

    [
      Thread.new { DplaApiResponseBuilder.new.contributors_item_count(hub_name) },
      Thread.new { DplaApiResponseBuilder.new.contributors_bws_item_count(hub_name) },
      Thread.new {
        batch = GaResponseBuilder.batch_responses([website_overview.ga_builder, website_events.ga_builder])
        website_overview.prefetch(batch[0])
        website_events.prefetch(batch[1])
      },
      Thread.new { metadata_completeness.contributor_csv },
    ].map(&:value)
  end
end

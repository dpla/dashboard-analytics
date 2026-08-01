class WarmComparisonCacheJob < ApplicationJob
  queue_as :default

  # Pre-warms GA4 caches for all hubs so pages skip 20-30s GA4 calls.
  # Responses land in the permanent S3 store, so one run warms every task;
  # each range needs warming once.
  #
  # Schedule monthly via EventBridge → ECS task, e.g.:
  #   cron(0 5 5 * ? *)   # 05:00 UTC on the 5th
  #
  def perform
    end_date = DataWindow.max_date
    unless GaPersistentCache.cacheable?(end_date)
      Rails.logger.warn(
        "WarmComparisonCacheJob: skipping, the just-completed month has not " \
        "settled yet; run after day #{GaPersistentCache::SETTLING_DAYS} of the month."
      )
      return
    end

    hubs = Hub.all
    if hubs.empty?
      message = "WarmComparisonCacheJob: no hubs found (hub_stats.json missing?); nothing warmed"
      Rails.logger.error(message)
      Sentry.capture_message(message)
      return
    end

    failures = 0
    hubs.each do |hub_name|
      failures += warm_hub(hub_name, DataWindow.min_date, end_date)
    rescue => e
      failures += 1
      Rails.logger.error("WarmComparisonCacheJob: failed warming #{hub_name}: #{e.message}")
      Sentry.capture_exception(e)
    end

    summary = "WarmComparisonCacheJob: warmed #{hubs.size} hubs, #{failures} failures"
    Rails.logger.info(summary)
    Sentry.capture_message(summary) if failures.positive?
  end

  private

  # Warm each class with the range its pages request: hub landing =
  # all-time; contributor comparison = last completed month. Returns the
  # count of event tables that failed.
  def warm_hub(hub_name, start_date, end_date)
    Rails.logger.info("WarmComparisonCacheJob: warming cache for #{hub_name}")

    sections = [
      [WebsiteOverviewByContributor, end_date.beginning_of_month],
      [WebsiteEventsByContributor,   end_date.beginning_of_month],
      [WebsiteOverview,              start_date],
      [WebsiteEventTotals,           start_date],
    ].map do |klass, range_start|
      klass.build do |b|
        b.hub        = hub_name
        b.start_date = range_start
        b.end_date   = end_date
      end
    end

    event_failures = 0
    threads = [
      Thread.new {
        # One batched GA4 call (batchRunReports max: 5 reports).
        batch = GaResponseBuilder.batch_responses(sections.map(&:ga_builder))
        sections.zip(batch).each { |section, response| section.prefetch(response) }
      },
      Thread.new { event_failures = warm_event_tables(hub_name, end_date) },
    ]
    # Wait on both threads before raising, so one failure can't orphan
    # the other.
    errors = threads.filter_map do |thread|
      thread.value
      nil
    rescue StandardError => e
      e
    end
    errors.drop(1).each do |e|
      Rails.logger.error("WarmComparisonCacheJob: also failed warming #{hub_name}: #{e.message}")
      Sentry.capture_exception(e)
    end
    raise errors.first if errors.any?

    event_failures
  end

  # First page of each event table, for both landing ranges: the default
  # full window (see EventsController#default_start_date) and the last
  # completed month alone, which the date menu and old links request.
  # Other ranges: stored on first user request. Counts nil responses;
  # WebsiteEvents#response swallows errors.
  def warm_event_tables(hub_name, end_date)
    starts = [DataWindow.events_min_date, end_date.beginning_of_month].uniq

    starts.sum do |start_date|
      WebsiteEvents::NAMES_BY_ID.each_value.count do |event_name|
        WebsiteEvents.build do |b|
          b.hub        = hub_name
          b.start_date = start_date
          b.end_date   = end_date
          b.event_name = event_name
          b.page       = 1
        end.response.nil?
      end
    end
  end
end

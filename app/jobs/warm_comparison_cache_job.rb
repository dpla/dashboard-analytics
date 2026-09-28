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

    # Site-wide floor for the search-terms page.
    site_months = WebsiteActivityMonths.build do |b|
      b.start_date = DataWindow.min_date
      b.end_date   = end_date
    end
    failures += 1 if site_months.response.nil?

    failures += warm_source_set_views(end_date)

    summary = "WarmComparisonCacheJob: warmed #{hubs.size} hubs, #{failures} failures"
    Rails.logger.info(summary)
    Sentry.capture_message(summary) if failures.positive?
  end

  private

  # Source set views, same two ranges as the event tables.
  # One site-wide report serves every hub (see PssEvents#cache_key_parts).
  def warm_source_set_views(end_date)
    landing_starts(DataWindow.pss_min_date, end_date).count do |start_date|
      PssEvents.build do |b|
        b.start_date = start_date
        b.end_date   = end_date
      end.response.nil?
    end
  end

  # Each section gets the range its page asks for: all-time for the hub
  # landing, last completed month for the contributor comparison.
  def warm_hub(hub_name, start_date, end_date)
    Rails.logger.info("WarmComparisonCacheJob: warming cache for #{hub_name}")

    sections = [
      [WebsiteOverviewByContributor, end_date.beginning_of_month],
      [WebsiteEventsByContributor,   end_date.beginning_of_month],
      [WebsiteOverview,              start_date],
      [WebsiteEventTotals,           start_date],
      [WebsiteActivityMonths,        start_date],
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
        # One batched report per era per section (see GaEventSchema).
        reports = sections.flat_map do |section|
          section.ga_builders.map { |era, builder| [section, era, builder] }
        end
        responses = GaResponseBuilder.batch_responses(reports.map(&:last))
        reports.zip(responses).each do |(section, era, _builder), response|
          section.prefetch(era, response)
        end
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

  # The two ranges landing pages ask for: the full window (see
  # EventsController#default_start_date) and the last completed month.
  def landing_starts(min_date, end_date)
    [min_date, end_date.beginning_of_month].uniq
  end

  # First page of each event table, for both landing ranges.
  # Counts nil responses, since WebsiteEvents#response swallows errors.
  def warm_event_tables(hub_name, end_date)
    landing_starts(DataWindow.events_min_date, end_date).sum do |start_date|
      WebsiteEvents::NAMES_BY_ID.except(PssEvents::EVENT_ID).each_value.count do |event_name|
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

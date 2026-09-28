class WebsiteOverview
  include GaErrorTracking
  include GaCacheable

  METRICS = %w(ga:totalEvents ga:sessions ga:users).freeze

  ##
  # @return [WebsiteOverview]
  #
  # @example
  #   WebsiteOverview.build do |builder|
  #     builder.hub = "California Digital Library"
  #     builder.contributor = "Agua Caliente Cultural Museum"
  #     builder.start_date = Date.yesterday
  #     builder.end_date = Date.today
  #   end
  #
  def self.build
    builder = new
    yield(builder)
    builder
  end

  def initialize
    @hub = nil
    @contributor = nil
    @start_date = nil
    @end_date = nil
  end

  def hub=(hub)
    @hub = hub
  end

  def contributor=(contributor)
    @contributor = contributor
  end

  def start_date=(start_date)
    @start_date = start_date
  end

  def end_date=(end_date)
    @end_date = end_date
  end

  # Cached totals, or nil on error (see #error?). The eras are summed, so
  # sessions and users count a returning visitor once per era.
  def response
    @response ||= merge(era_responses)
  rescue => e
    Rails.logger.error(e)
    record_ga_error(e)
    nil
  end

  ##
  # Total website events for the given hub/contributor and time period.
  def events
    response&.totals_for_all_results&.[]('ga:totalEvents').to_i
  end

  ##
  # Total website sessions for the given hub/contributor and time period.
  def sessions
    response&.totals_for_all_results&.[]('ga:sessions').to_i
  end

  ##
  # Total website users for the given hub/contributor and time period.
  def users
    response&.totals_for_all_results&.[]('ga:users').to_i
  end

  private

  def builder_for(era)
    GaResponseBuilder.build do |builder|
      builder.start_date = era.start_date.iso8601
      builder.end_date = era.end_date.iso8601
      builder.metrics = METRICS
      builder.filters = era.schema.hub_filters(@hub, @contributor)
    end
  end

  def merge(responses)
    totals = METRICS.to_h do |metric|
      [metric, responses.sum { |response| response.totals_for_all_results[metric].to_i }.to_s]
    end
    build_response(METRICS, [], totals: totals, total_results: 0)
  end
end

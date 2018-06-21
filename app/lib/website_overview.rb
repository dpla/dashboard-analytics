class WebsiteOverview

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

  ##
  # Lazy load single-page response.
  # Return nil if response fails.
  #
  # @return [Google::Apis::AnalyticsV3::GaData] | nil
  #
  def response
    @reponse ||= website_overview_builder.response
  rescue => e
    Rails.logger.error(e)
    nil
  end

  ##
  # Total website events for the given hub/contributor and time period.
  def events
    response.present? ? response.totals_for_all_results['ga:totalEvents'] : nil
  end

  ##
  # Total website sessions for the given hub/contributor and time period.
  def sessions
    response.present? ? response.totals_for_all_results['ga:sessions'] : nil
  end

  ##
  # Total website users for the given hub/contributor and time period.
  def users
   response.present? ? response.totals_for_all_results['ga:users'] :nil
  end

  private

  ##
  # @return GaResponseBuilder
  # @throws exception if HTTP request fails
  #
  def website_overview_builder
    filters = %W(ga:eventCategory=@#{@hub} ga:eventCategory!@Browse)
    filters.concat %W(ga:eventAction==#{@contributor}) if @contributor

    GaResponseBuilder.build do |builder|
      builder.profile_id = profile_id
      builder.start_date = @start_date.iso8601
      builder.end_date = @end_date.iso8601
      builder.metrics = %w(ga:totalEvents ga:sessions ga:users)
      builder.filters = filters
    end
  end

  def profile_id
    Settings.google_analytics.frontend_profile_id
  end
end

class OverviewWebsite

  def initialize(target)
    @target = target
    @start_date = target.start_date #already in iso8601
    @end_date = target.end_date #already in iso8601
  end

  def target
    @target
  end

  def hub_name
    target.is_a?(Hub) ? target.name : target.hub.name
  end

  def contributor_name
    target.is_a?(Contributor) ? target.name : nil
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
    filters = %W(ga:eventCategory=@#{hub_name} ga:eventCategory!@Browse)
    filters.concat %W(ga:eventAction==#{contributor_name}) if contributor_name

    GaResponseBuilder.build do |builder|
      builder.profile_id = profile_id
      builder.start_date = @start_date
      builder.end_date = @end_date
      builder.metrics = %w(ga:totalEvents ga:sessions ga:users)
      builder.filters = filters
    end
  end

  def profile_id
    Settings.google_analytics.frontend_profile_id
  end
end

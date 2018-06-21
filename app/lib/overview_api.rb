class OverviewApi

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
    @reponse ||= api_overview_builder.response
  rescue => e
    Rails.logger.error(e)
    nil
  end

  def events
    response.present? ? response.totals_for_all_results['ga:totalEvents'] : nil
  end

  def users
    response.present? ? response.totals_for_all_results['ga:users'] : nil
  end

  private

  ##
  # @return GaResponseBuilder
  # @throws exception if HTTP request fails
  #
  def api_overview_builder
    filters = %W(ga:eventCategory=@#{hub_name})
    filters.concat %W(ga:eventAction==#{contributor_name}) if contributor_name

    GaResponseBuilder.build do |builder|
      builder.profile_id = profile_id
      builder.start_date = @start_date
      builder.end_date = @end_date
      builder.segment = segment
      builder.metrics = %w(ga:totalEvents ga:users)
      builder.filters = filters
    end
  end

  def segment
    Settings.google_analytics.api_segment
  end

  def profile_id
    Settings.google_analytics.api_profile_id
  end
end

class WebsiteEventsByContributor

  def initialize(hub)
    @hub = hub
    @start_date = hub.start_date #already in iso8601
    @end_date = hub.end_date #already in iso8601
  end

  def target
    @target
  end

  def hub_name
    @hub.name
  end

  def parse_data
    return Hash.new unless response.present?
    # Create Hash of data
    # e.g. "The Library" => { "Click Throughs" => 2, "Total Views" => 5 }
    data = {}

    response.rows.map do |r|
      event = r[0].split(" : ").first
      contributor = r[1]
      count = r[2].to_i rescue 0

      data[contributor] ||= { "Views" => 0 }
      data[contributor]["Click Throughs"] = count if event == "Click Through"
      data[contributor]["Views"] += count if event.start_with?("View")
    end

    data
  end

  ##
  # Lazy load single-page response.
  # Return nil if response fails.
  #
  # @return [Google::Apis::AnalyticsV3::GaData] | nil
  #
  def response
    @reponse ||= events_by_contributor_builder.response
  rescue => e
    Rails.logger.error(e)
    nil
  end

  private

  ##
  # @return GaResponseBuilder
  # @throws exception if HTTP request fails
  #
  def events_by_contributor_builder
    GaResponseBuilder.build do |builder|
      builder.profile_id = profile_id
      builder.start_date = @start_date
      builder.end_date = @end_date
      builder.metrics = %w(ga:totalEvents)
      builder.dimensions = %w(ga:eventCategory ga:eventAction)
      builder.filters = %W(ga:eventCategory=@#{hub_name} ga:eventCategory!@Browse)
    end
  end

  def profile_id
    Settings.google_analytics.frontend_profile_id
  end
end

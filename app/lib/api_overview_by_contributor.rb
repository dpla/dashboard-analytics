class ApiOverviewByContributor

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
    # Create Hash of data
    # e.g. { "The Library" => { "Views" => 4, "Users" => 2 } }
    columns = response.column_headers.map { |c| c.name }
    data = {}

    response.rows.map do |r|
      contributor = r[columns.index("ga:eventAction")]
      views = r[columns.index("ga:totalEvents")]
      users = r[columns.index("ga:users")]
      data[contributor] = { 'Views' => views, 'Users' => users }
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
    @reponse ||= overview_by_contributor_builder.response
  rescue => e
    Rails.logger.error(e)
    nil
  end

  private

  ##
  # @return GaResponseBuilder
  # @throws exception if HTTP request fails
  #
  def overview_by_contributor_builder
    GaResponseBuilder.build do |builder|
      builder.profile_id = profile_id
      builder.start_date = @start_date
      builder.end_date = @end_date
      builder.segment = segment
      builder.metrics = %w(ga:totalEvents ga:users)
      builder.dimensions = %w(ga:eventAction)
      builder.filters = %W(ga:eventCategory=@#{hub_name})
    end
  end

  def segment
    Settings.google_analytics.api_segment
  end

  def profile_id
    Settings.google_analytics.frontend_profile_id
  end
end

class WebsiteOverviewByContributor

  ##
  # @return [WebsiteOverviewByContributor]
  #
  # @example
  #   WebsiteOverviewByContributor.build do |builder|
  #     builder.hub = "California Digital Library"
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
    @start_date = nil
    @end_date = nil
  end

  def hub=(hub)
    @hub = hub
  end

  def start_date=(start_date)
    @start_date = start_date
  end

  def end_date=(end_date)
    @end_date = end_date
  end

  # Returns the configured GaResponseBuilder for use in batch requests.
  def ga_builder
    @ga_builder ||= overview_by_contributor_builder
  end

  # Inject a pre-fetched response (e.g. from a batch call) to skip
  # the individual GA4 API call when response is next accessed.
  def prefetch(ga4_response)
    @response = ga4_response
  end

  def parse_data
    return Hash.new unless response.present? && response.rows.present?
    # Create Hash of data
    # e.g. "The Library" => { "Sessions" => 4, "Users" => 2 }
    columns = response.column_headers.map { |c| c.name }
    data = {}

    response.rows.map do |r|
      contributor = r[columns.index("ga:eventAction")]
      sessions = r[columns.index("ga:sessions")]
      users = r[columns.index("ga:users")]
      data[contributor] = { 'Sessions' => sessions.to_i,
                            'Users' => users.to_i }
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
    @response ||= Rails.cache.fetch(cache_key, expires_in: 2.hours) do
      overview_by_contributor_builder.response
    end
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
      builder.start_date = @start_date.iso8601
      builder.end_date = @end_date.iso8601
      builder.metrics = %w(ga:sessions ga:users)
      builder.dimensions = %w(ga:eventAction)
      builder.filters = %W(ga:eventCategory=@#{@hub} ga:eventCategory!@Browse)
    end
  end

  def cache_key
    "ga:website_overview_by_contributor:#{@hub}:#{@start_date}:#{@end_date}"
  end

  def profile_id
    Settings.google_analytics.frontend_profile_id
  end
end

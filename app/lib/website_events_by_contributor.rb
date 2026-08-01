class WebsiteEventsByContributor
  include GaCacheable

  ##
  # @return [WebsiteEventsByContributor]
  #
  # @example
  #   WebsiteEventsByContributor.build do |builder|
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
    @ga_builder ||= events_by_contributor_builder
  end

  def parse_data
    return Hash.new unless response.present? && response.rows.present?
    # Create Hash of data
    # e.g. "The Library" => { "Click Throughs" => 2, "Total Views" => 5 }
    data = {}

    response.rows.each do |r|
      event = r[0].split(" : ").first
      contributor = r[1]
      count = r[2]&.to_i || 0

      data[contributor] ||= { "Views" => 0, "Click Throughs" => 0 }
      data[contributor]["Click Throughs"] += count if event == "Click Through"
      data[contributor]["Views"] += count if event.start_with?("View")
    end

    data
  end

  ##
  # Cached single-page response; nil on error.
  #
  def response
    @response ||= fetch_cached do
      events_by_contributor_builder.response
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
  def events_by_contributor_builder
    GaResponseBuilder.build do |builder|
      builder.profile_id = profile_id
      builder.start_date = @start_date.iso8601
      builder.end_date = @end_date.iso8601
      builder.metrics = %w(ga:totalEvents)
      builder.dimensions = %w(ga:eventCategory ga:eventAction)
      builder.filters = %W(ga:eventCategory=@#{@hub} ga:eventCategory!@Browse)
    end
  end

  def profile_id
    Settings.google_analytics.frontend_profile_id
  end
end

class ApiEvents

  ##
  # @return [ApiEvents]
  #
  # @example
  #   ApiEvents.build do |builder|
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
    @response ||= events_builder.response
  rescue => e
    Rails.logger.error(e)
    nil
  end

  ##
  # Lazy load multi-page response.
  # Return empty array if response fails.
  #
  # @return [Array<Google::Apis::AnalyticsV3::GaData>] | empty array
  #
  def multi_page_response
    @multi_page_reponse ||= events_builder.multi_page_response
  rescue => e
    Rails.logger.error(e)
    Array.new
  end

  ##
  # @return [Array<Hash>]
  def results
    parse(response)
  end

  ##
  # Generate CSV of all events
  def to_csv
    attributes = ["Item", "Item ID", "Contributor", "View API Item"]

    CSV.generate({ headers: true }) do |csv|
      csv << attributes

      multi_page_response.each do |response|
        events = parse(response)
        events.each do |event|
          csv << [event[:title], event[:id], event[:contributor], event[:count]]
        end
      end
    end
  end

  private

  ##
  # @param [Google::Apis::AnalyticsV3::GaData]
  # @return [Array<Hash>]
  #
  def parse(res)
    # Create a Hash of data
    # E.g. { contributor: "Foo", id: "123", title: "Bar", count: "4" }
    data = []

    # Handle failed response or response with no results.
    return data unless (res && res.rows.present?)

    columns = res.column_headers.map { |c| c.name }

    res.rows.each do |r|
      contributor = r[columns.index("ga:eventAction")]
      id = r[columns.index("ga:eventLabel")].split(" : ").first rescue nil
      title = r[columns.index("ga:eventLabel")].split(" : ").last rescue nil
      count = r[columns.index("ga:totalEvents")]

      data.push({ contributor: contributor, id: id, title: title, count: count })
    end

    data
  end

  ##
  # @return GaResponseBuilder
  # @throws exception if HTTP request fails
  #
  def events_builder
    event_category = "View API Item : #{@hub}"
    filters = %W(ga:eventCategory==#{event_category})
    filters.concat %W(ga:eventAction==#{@contributor}) if @contributor

    GaResponseBuilder.build do |builder|
      builder.profile_id = profile_id
      builder.start_date = @start_date.iso8601
      builder.end_date = @end_date.iso8601
      builder.segment = segment
      builder.metrics = %w(ga:totalEvents)
      builder.dimensions = %w(ga:eventLabel ga:eventAction)
      builder.filters = filters
      builder.sort = %w(-ga:totalEvents) # Descending
    end
  end

  def profile_id
    Settings.google_analytics.api_profile_id
  end

  def segment
    Settings.google_analytics.api_segment if @scope =="api"
  end
end

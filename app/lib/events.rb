class Events

  ##
  # @param target [Hub|Contributor]
  # @param event_label [String] e.g. view_item, click_through, etc.
  def initialize(target, event_label)
    @target = target
    @event_label = event_label
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

  def event_name
    dict = { 'view_item' => 'View Item',
             'view_exhibit' => 'View Exhibition Item',
             'view_pss' => 'View Primary Source',
             'click_through' => 'Click Through',
             'view_api' => 'View API Item' }

    dict[@event_label]
  end

  ##
  # Lazy load single-page response.
  # Return nil if response fails.
  #
  # @return [Google::Apis::AnalyticsV3::GaData] | nil
  #
  def response
    events_builder.response
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
    events_builder.multi_page_response
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
    attributes = ["Item", "Item ID", "Contributor", event_name]

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
  def events_builder
    event_category = "#{event_name} : #{hub_name}"
    filters = %W(ga:eventCategory==#{event_category})
    filters.concat %W(ga:eventAction==#{contributor_name}) if contributor_name

    GaResponseBuilder.build do |builder|
      builder.profile_id = profile_id
      builder.start_date = @start_date
      builder.end_date = @end_date
      builder.metrics = %w(ga:totalEvents)
      builder.dimensions = %w(ga:eventLabel ga:eventAction)
      builder.filters = filters
      builder.sort = %w(-ga:totalEvents) # Descending
    end
  end

  def profile_id
    if(@event_label == "view_api")
      Settings.google_analytics.api_profile_id
    else
      Settings.google_analytics.frontend_profile_id
    end
  end

  def segment
    Settings.google_analytics.api_segment if @scope =="api"
  end
end

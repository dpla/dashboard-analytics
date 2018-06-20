class FrontendAnalytics < GaResponseBuilder

  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  ##
  # @param hub [String] Hub name
  # @param contributor [String] Contributor name
  # @return [Hash]
  #
  def overall_use_totals(hub, contributor = nil)
    filters = %W(ga:eventCategory=@#{hub} ga:eventCategory!@Browse)
    filters.concat %W(ga:eventAction==#{contributor}) if contributor

    begin
      GaResponseBuilder.build do |builder|
        builder.profile_id = profile_id
        builder.start_date = @start_date
        builder.end_date = @end_date
        builder.metrics = %w(ga:totalEvents ga:uniqueEvents ga:sessions ga:users)
        builder.filters = filters
      end.response.totals_for_all_results
    rescue
      # TODO: Log error
      Hash.new
    end
  end

  ##
  # @param [String] Hub name
  # @param contributor [String] Contributor name
  # @return [Hash]
  #
  def event_totals(hub, contributor = nil)
    filters = %W(ga:eventCategory=@#{hub} ga:eventCategory!@Browse)
    filters.concat %W(ga:eventAction==#{contributor}) if contributor

    begin
      res = GaResponseBuilder.build do |builder|
        builder.profile_id = profile_id
        builder.start_date = @start_date
        builder.end_date = @end_date
        builder.metrics = %w(ga:totalEvents)
        builder.dimensions = %w(ga:eventCategory)
        builder.filters = filters
      end.response

      res.rows.collect{ |row| 
        # Create human-readable key-value pairs
        # Example: change "Click Through : ArtStor" to "Click Through"
        [row[0].split(' : ')[0], row[1]]
      }.to_h
    rescue
      # TODO: Log error message
      Hash.new
    end
  end

  ##
  # @param hub [String] Hub name
  # @return [Hash]
  #
  def overall_use_by_contributor(hub)

    begin
      res = GaResponseBuilder.build do |builder|
        builder.profile_id = profile_id
        builder.start_date = @start_date
        builder.end_date = @end_date
        builder.metrics = %w(ga:sessions ga:users)
        builder.dimensions = %w(ga:eventAction)
        builder.filters = %W(ga:eventCategory=@#{hub} ga:eventCategory!@Browse)
      end.response

      # Create Hash of data
      # e.g. "The Library" => { "Sessions" => 4, "Users" => 2 }
      columns = res.column_headers.map { |c| c.name }
      data = {}

      res.rows.map do |r|
        contributor = r[columns.index("ga:eventAction")]
        sessions = r[columns.index("ga:sessions")]
        users = r[columns.index("ga:users")]
        data[contributor] = { 'Sessions' => sessions,
                              'Users' => users }
      end

      data
    rescue
      # TODO: Log error
      Hash.new
    end
  end

  ##
  # @param hub [String] Hub name
  # @return [Hash]
  #
  def events_by_contributor(hub)

    begin
      res = GaResponseBuilder.build do |builder|
        builder.profile_id = profile_id
        builder.start_date = @start_date
        builder.end_date = @end_date
        builder.metrics = %w(ga:totalEvents)
        builder.dimensions = %w(ga:eventCategory ga:eventAction)
        builder.filters = %W(ga:eventCategory=@#{hub} ga:eventCategory!@Browse)
      end.response

      # Create Hash of data
      # e.g. "The Library" => { "Click Throughs" => 2, "Total Views" => 5 }
      data = {}

      res.rows.map do |r|
        event = r[0].split(" : ").first
        contributor = r[1]
        count = r[2].to_i rescue 0

        data[contributor] ||= { "Views" => 0 }
        data[contributor]["Click Throughs"] = count if event == "Click Through"
        data[contributor]["Views"] += count if event.start_with?("View")
      end

      data
    rescue
      # TODO: Log error
      Hash.new
    end
  end

  ##
  # @param event [String] event name, e.g. "Click Through" 
  # @param hub [String] Hub name
  # @param options [Hash]
  # @return [Hash] | nil
  #
  def events(event, hub, options = {})
    res = events_builder(event, hub, options).response
    parse_event_data(res)

    # TODO: if there are no results, this returns nil.
    # Would be better to return an empty Hash.
  rescue
    # TODO: Handle error
    Hash.new
  end

  ##
  # Get all events.
  # @return [Array<Hash>]
  def all_events(event, hub, options={})
    res = events_builder(event, hub, options).multi_page_response
    res.flat_map{ |response| parse_event_data(response)[:results] }
  rescue
    # TODO: Handle error
      Array.new
  end

  ##
  # @return GaResponseBuilder
  def events_builder(event, hub, options={})
    contributor = options[:contributor]
    event_category = "#{event} : #{hub}"
    filters = %W(ga:eventCategory==#{event_category})
    filters.concat %W(ga:eventAction==#{contributor}) if contributor

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

  ##
  # @param response from an events data request
  def parse_event_data(res)
    # Create a Hash of data
    # E.g. { contributor: "Foo", id: "123", title: "Bar", count: "4" }
    columns = res.column_headers.map { |c| c.name }
    data = {
      items_per_page: res.items_per_page,
      start_index: res.query.start_index,
      total_results: res.total_results,
      next_link: res.next_link,
      results: []
    }

    res.rows.each do |r|
      contributor = r[columns.index("ga:eventAction")]
      id = r[columns.index("ga:eventLabel")].split(" : ").first rescue nil
      title = r[columns.index("ga:eventLabel")].split(" : ").last rescue nil
      count = r[columns.index("ga:totalEvents")]

      data[:results].push({ contributor: contributor, id: id, title: title,
                            count: count })
    end

    return data
  end

  protected

  def profile_id
    Settings.google_analytics.frontend_profile_id
  end
end

class ApiAnalytics

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
    filters = %W(ga:eventCategory=@#{hub})
    filters.concat %W(ga:eventAction==#{contributor}) if contributor

    begin
      GaResponseBuilder.build do |builder|
        builder.profile_id = profile_id
        builder.start_date = @start_date
        builder.end_date = @end_date
        builder.segment = segment
        builder.metrics = %w(ga:totalEvents ga:users)
        builder.filters = filters
      end.totals_for_all_results
    rescue
      # TODO: Log error
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
        builder.segment = segment
        builder.metrics = %w(ga:totalEvents ga:users)
        builder.dimensions = %w(ga:eventAction)
        builder.filters = %W(ga:eventCategory=@#{hub})
      end

      # Create Hash of data
      # e.g. { "The Library" => { "Views" => 4, "Users" => 2 } }
      columns = res.column_headers.map { |c| c.name }
      data = {}

      res.rows.map do |r|
        contributor = r[columns.index("ga:eventAction")]
        views = r[columns.index("ga:totalEvents")]
        users = r[columns.index("ga:users")]
        data[contributor] = { 'Views' => views, 'Users' => users }
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
  def events(event, hub, options={})
    contributor = options[:contributor]
    start_index = options[:start_index]
    event_category = "#{event} : #{hub}"
    filters = %W(ga:eventCategory==#{event_category})
    filters.concat %W(ga:eventAction==#{contributor}) if contributor

    begin
      res = GaResponseBuilder.build do |builder|
        builder.profile_id = profile_id
        builder.start_date = @start_date
        builder.end_date = @end_date
        builder.segment = segment
        builder.metrics = %w(ga:totalEvents)
        builder.dimensions = %w(ga:eventLabel ga:eventAction)
        builder.filters = filters
        builder.sort = %w(-ga:totalEvents) # Descending
        builder.start_index = start_index
      end

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

      # TODO: if there are no results, this returns nil.
      # Would be better to return an empty Hash.
    rescue => e
      Rails.logger.error(e)
      # TODO: Handle error
      Hash.new
    end
  end

  ##
  # Get all events. Paginate as necessary.
  # @return [Array]
  def all_events(event, hub, options={})
    results = []
    first_response = events(event, hub, options)
    results.push first_response
    more = first_response[:next_link].present?

    while more == true
      options[:start_index] = 
        results.last[:start_index] + results.last[:items_per_page]

      results.push events(event, hub, options)
      more = results.last[:next_link].present?
    end

    results.flat_map{ |response| response[:results] }
  end

  protected

  def segment
    Settings.google_analytics.api_segment
  end

  def profile_id
    Settings.google_analytics.api_profile_id
  end
end

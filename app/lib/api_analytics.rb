class ApiAnalytics < GaResponseBuilder

  ##
  # @param hub [String] Hub name
  # @param contributor [String] Contributor name
  # @return [Hash]
  #
  def overall_use_totals(hub, contributor = nil)
    metrics = %w(ga:totalEvents ga:users)
    dimensions = %w()
    filters = %W(ga:eventCategory=@#{hub})

    filters.concat %W(ga:eventAction==#{contributor}) if contributor

    begin
      response(metrics, dimensions, filters).totals_for_all_results
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
    metrics = %w(ga:totalEvents ga:users)
    dimensions = %w(ga:eventAction)
    filters = %W(ga:eventCategory=@#{hub})

    begin
      res = response(metrics, dimensions, filters)

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
  # @param hub [String] Hub name
  # @param contributor [String] Contributor name
  # @return [Hash] | nil
  #
  def individual_event_counts(hub, contributor = nil)
    event_category = "View API Item : #{hub}"

    metrics = %w(ga:totalEvents)
    dimensions = %w(ga:eventLabel ga:eventAction)
    filters = %W(ga:eventCategory==#{event_category})
    sort = %w(-ga:totalEvents) # Descending

    filters.concat %W(ga:eventAction==#{contributor}) if contributor

    begin
      res = response(metrics, dimensions, filters, options={ sort: sort } )

      # Create a Hash of data
      # E.g. { contributor: "Foo", id: "123", title: "Bar", count: "4" }
      columns = res.column_headers.map { |c| c.name }

      res.rows.map do |r|
        contributor = r[columns.index("ga:eventAction")]
        id = r[columns.index("ga:eventLabel")].split(" : ").first rescue nil
        title = r[columns.index("ga:eventLabel")].split(" : ").last rescue nil
        count = r[columns.index("ga:totalEvents")]

        { contributor: contributor,
          id: id, 
          title: title,
          count: count }
      end

      # TODO: if there are no results, this returns nil.
      # Would be better to return an empty Hash.
    rescue
      # TODO: Handle error
      Hash.new
    end
  end

  ##
  # @param event [String] event name, e.g. "Click Through" 
  # @param hub [String] Hub name
  # @param contributor [String] Contributor name
  # @return [Hash] | nil
  #
  def events(event, hub, options={})
    contributor = options[:contributor]

    event_category = "#{event} : #{hub}"

    metrics = %w(ga:totalEvents)
    dimensions = %w(ga:eventLabel ga:eventAction)
    filters = %W(ga:eventCategory==#{event_category})
    sort = %w(-ga:totalEvents) # Descending

    filters.concat %W(ga:eventAction==#{contributor}) if contributor

    begin
      res = response(metrics, dimensions, filters, options={ sort: sort } )

      # Create a Hash of data
      # E.g. { contributor: "Foo", id: "123", title: "Bar", count: "4" }
      columns = res.column_headers.map { |c| c.name }
      data = {
        items_per_page: res.items_per_page,
        start_index: res.query.start_index,
        total_results: res.total_results,
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
    rescue
      # TODO: Handle error
      Hash.new
    end
  end

  protected

  def segment
    Settings.google_analytics.api_segment
  end

  def profile_id
    Settings.google_analytics.api_profile_id
  end
end

class FrontendAnalytics < GaResponseBuilder

  ##
  # @param hub [String] Hub name
  # @param contributor [String] Contributor name
  # @return [Hash]
  #
  def overall_use_totals(hub, contributor = nil)
    metrics = %w(ga:totalEvents ga:uniqueEvents ga:sessions ga:users)
    dimensions = %w()
    filters = %W(ga:eventCategory=@#{hub} ga:eventCategory!@Browse)

    filters.concat %W(ga:eventAction==#{contributor}) if contributor

    begin
      response(metrics, dimensions, filters).totals_for_all_results
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
    metrics = %w(ga:totalEvents)
    dimensions = %w(ga:eventCategory)
    filters = %W(ga:eventCategory=@#{hub} ga:eventCategory!@Browse)

    filters.concat %W(ga:eventAction==#{contributor}) if contributor

    begin
      response(metrics, dimensions, filters).rows.collect{ |row| 
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
  # @return [Array<Hash>]
  #
  def overall_use_by_contributor(hub)
    metrics = %w(ga:sessions ga:users)
    dimensions = %w(ga:eventAction)
    filters = %W(ga:eventCategory=@#{hub} ga:eventCategory!@Browse)

    begin
      res = response(metrics, dimensions, filters)

      # Create Array of Hashes
      # e.g. "The Library" => { "frontend_sessions" => 4, "frontend_users" => 2 }
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
      Array.new
    end
  end

  ##
  # @param hub [String] Hub name
  # @return [Array<Hash>]
  #
  def events_by_contributor(hub)
    metrics = %w(ga:totalEvents)
    dimensions = %w(ga:eventCategory ga:eventAction)
    filters = %W(ga:eventCategory=@#{hub} ga:eventCategory!@Browse)

    begin
      res = response(metrics, dimensions, filters)

      # Create Array of Hashes
      # e.g. "The Library" => { "Click Throughs" => 2, "Total Views" => 5 }
      data = {}

      res.rows.map do |r|
        event = r[0].split(" : ").first
        contributor = r[1]
        count = r[2].to_i rescue 0

        data[contributor] ||= { "Views" => 0 }
        # data[contributor][event] = count
        data[contributor]["Click Throughs"] = count if event == "Click Through"
        data[contributor]["Views"] += count if event.start_with?("View")
      end

      data
    rescue
      # TODO: Log error
      Array.new
    end
  end

  protected

  def profile_id
    Settings.google_analytics.frontend_profile_id
  end
end

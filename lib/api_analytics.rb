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

  protected

  def segment
    Settings.google_analytics.api_segment
  end

  def profile_id
    Settings.google_analytics.api_profile_id
  end
end

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
      end.response.totals_for_all_results
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
      end.response

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
  # @param contributor [String]
  # @return [Hash] | nil
  #
  def events(event, hub, contributor=nil)
    res = events_builder(event, hub, contributor).response
    parse_event_data(res)

    # TODO: if there are no results, this returns nil.
    # Would be better to return an empty Hash.
  rescue => e
    Rails.logger.error(e)
    # TODO: Handle error
    Hash.new
  end

  protected

  def segment
    Settings.google_analytics.api_segment
  end

  def profile_id
    Settings.google_analytics.api_profile_id
  end
end

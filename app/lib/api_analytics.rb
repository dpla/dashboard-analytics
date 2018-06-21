class ApiAnalytics

  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
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

  protected

  def segment
    Settings.google_analytics.api_segment
  end

  def profile_id
    Settings.google_analytics.api_profile_id
  end
end

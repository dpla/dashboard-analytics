class SearchTerms

  ##
  # @param scope [String] "api" or "website"
  # @param start_date [Date]
  # @param end_date [Date]
  #
  def initialize(scope, start_date, end_date)
    @scope = scope
    @start_date = start_date
    @end_date = end_date
  end

  ##
  # Lazy load single-page response.
  # Return nil if response fails.
  #
  # @return [Google::Apis::AnalyticsV3::GaData] | nil
  #
  def response
    @response ||= search_terms_builder.response
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
    @multi_page_response ||= search_terms_builder.multi_page_response
  rescue => e
    Rails.logger.error(e)
    Array.new
  end

  ##
  # Generate CSV of all search terms.
  def to_csv
    attributes = [ "Search term", "Count" ]

    CSV.generate({ headers: true }) do |csv|
      csv << attributes

      multi_page_response.each do |response|
        response.rows.each do |row|
          csv << row
        end
      end
    end
  end

  private

  def profile_id
    if(@scope == "website")
      Settings.google_analytics.frontend_profile_id
    elsif(@scope =="api")
      Settings.google_analytics.api_profile_id
    end
  end

  def segment
    Settings.google_analytics.api_segment if @scope =="api"
  end

  ##
  # @return GaResponseBuilder
  # @throws exception if HTTP request fails
  #
  def search_terms_builder
    GaResponseBuilder.build do |builder|
      builder.profile_id = profile_id
      builder.start_date = @start_date.iso8601
      builder.end_date = @end_date.iso8601
      builder.segment = segment
      builder.metrics = %w(ga:searchUniques)
      builder.dimensions = %w(ga:searchKeyword)
      builder.sort = %w(-ga:searchUniques) # Descending
    end
  end
end

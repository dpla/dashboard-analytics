require 'csv'

class WebsiteSearchTerms
  include GaCacheable

  ##
  # @return [WebsiteSearchTerms]
  #
  # @example
  #   WebsiteSearchTerms.build do |builder|
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
    @start_date = nil
    @end_date = nil
    @page = nil
  end

  def start_date=(start_date)
    @start_date = start_date
  end

  def end_date=(end_date)
    @end_date = end_date
  end

  # 1-based page for #response; CSV exports are unaffected.
  def page=(page)
    @page = page
  end

  ##
  # Cached single-page response; nil on error.
  #
  def response
    @response ||= fetch_cached("page#{@page}") do
      search_terms_builder.response
    end
  rescue => e
    Rails.logger.error(e)
    nil
  end

  ##
  # Cached multi-page response for CSV export; empty array on error.
  #
  def multi_page_response
    @multi_page_response ||= fetch_cached("multi", memory: false) do
      search_terms_builder.multi_page_response
    end
  rescue => e
    Rails.logger.error(e)
    Array.new
  end

  ##
  # Generate CSV of all search terms.
  def to_csv
    attributes = [ "Search term", "Count" ]

    CSV.generate(headers: true) do |csv|
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
    Settings.google_analytics.frontend_profile_id
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
      builder.metrics = %w(ga:searchUniques)
      builder.dimensions = %w(ga:searchKeyword)
      builder.sort = %w(-ga:searchUniques) # Descending
      builder.page = @page
    end
  end

end

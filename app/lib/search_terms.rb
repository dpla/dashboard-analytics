class SearchTerms
  def initialize(id, start_date, end_date)
    @id = id
    @start_date = start_date
    @end_date = end_date
  end

  def id
    @id
  end

  def start_date
    @start_date.iso8601
  end

  def end_date
    @end_date.iso8601
  end

  ##
  # @return Hash
  def data
    @data ||= search_terms
  end

  ##
  # @return Array
  def terms
    data[:results] || []
  end

  ##
  # @return Integer
  def total_results
    data[:total_results]
  end

  ##
  # @return Integer
  def items_per_page
    data[:items_per_page]
  end

  ##
  # @return Integer
  def start_index
    data[:start_index]
  end

  def all_search_terms
    @all_search_terms ||= ga.all_search_terms
  end

  ##
  # Generate CSV of all search terms.
  def to_csv
    attributes = [ "Search term", "Count" ]

    CSV.generate({ headers: true }) do |csv|
      csv << attributes

      all_search_terms.each do |term|
        csv << term
      end
    end
  end

  ##
  # @return Integer
  def end_index
    total_results.to_i < items_per_page.to_i ? total_results : items_per_page
  end

  private

  def ga
    if(id == "website")
      frontend_ga
    elsif(id=="api")
      api_ga
    end
  end

  def profile_id
    if(id == "website")
      Settings.google_analytics.frontend_profile_id
    elsif(id=="api")
      Settings.google_analytics.api_profile_id
    end
  end

  def segment
    if(id=="api")
      Settings.google_analytics.api_segment
    end
  end

  ##
  # @return Hash
  #   Example search_terms.results:
  #     [["genealogy", "140"], ["\"family bible\"", "65"] ... ]
  def search_terms(start_index = nil)
    begin
      res = GaResponseBuilder.build do |builder|
        builder.profile_id = profile_id
        builder.start_date = start_date
        builder.end_date = end_date
        builder.segment = segment
        builder.metrics = %w(ga:searchUniques)
        builder.dimensions = %w(ga:searchKeyword)
        builder.sort = %w(-ga:searchUniques) # Descending
        builder.start_index = start_index
      end

      { items_per_page: res.items_per_page,
        start_index: res.query.start_index,
        total_results: res.total_results,
        next_link: res.next_link,
        results: res.rows }
    rescue => e
      Rails.logger.error(e)
      Hash.new
    end
  end

  ##
  # Get all search terms. Paginate as necessary.
  # @return [Array]
  def all_search_terms
    results = [search_terms]
    more = search_terms[:next_link].present?

    while more == true
      next_start_index = results.last[:start_index] + results.last[:items_per_page]
      results.push search_terms(next_start_index)
      more = results.last[:next_link].present?
    end
    
    results.flat_map { |response| response[:results] }
  end

  def frontend_ga
    @frontend_ga ||= FrontendAnalytics.new(start_date, end_date)
  end

  def api_ga
    @api_ga ||= ApiAnalytics.new(start_date, end_date)
  end
end

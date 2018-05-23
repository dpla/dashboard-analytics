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
    @data ||= get_data
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

  ##
  # @return Integer
  def end_index
    total_results.to_i < items_per_page.to_i ? total_results : items_per_page
  end

  private

  ##
  # @return Hash
  def get_data
    if(id == "website")
      frontend_ga.search_terms
    elsif(id=="api")
      api_ga.search_terms
    end
  end

  def frontend_ga
    @frontend_ga ||= FrontendAnalytics.new(start_date, end_date)
  end

  def api_ga
    @api_ga ||= ApiAnalytics.new(start_date, end_date)
  end
end

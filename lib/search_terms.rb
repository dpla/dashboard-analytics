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

  def data
    @data ||= get_data
  end

  def terms
    data[:results]
  end

  def total_results
    data[:total_results]
  end

  def items_per_page
    data[:items_per_page]
  end

  def start_index
    data[:start_index]
  end

  def end_index
    total_results < items_per_page ? total_results : items_per_page
  end

  private

  def get_data
    if(id == "website")
      frontend_ga.search_terms
    elsif(id=="api")
      # TODO
    end
  end

  def frontend_ga
    @frontend_ga ||= FrontendAnalytics.new(start_date, end_date)
  end

  def api_ga
    @api_ga ||= ApiAnalytics.new(start_date, end_date)
  end
end

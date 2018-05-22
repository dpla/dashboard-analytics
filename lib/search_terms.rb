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

  def terms
    @terms ||= get_terms
  end

  private

  def get_terms
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

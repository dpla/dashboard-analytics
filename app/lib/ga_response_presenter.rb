class GaResponsePresenter
  ##
  # @param GaResponse
  def initialize(ga_response)
    @ga_response = ga_response
  end

  def response
    @ga_response.response
  end

  def multi_page_response
    @ga_response.multi_page_response ? @ga_response.multi_page_response : []
  end

  def total_results
    response ? response.total_results : nil
  end

  def start_index
    response ? response.query.start_index : nil
  end

  def items_per_page
    response ? response.items_per_page : nil
  end

  def end_index
    if total_results && start_index
      total_results.to_i < items_per_page.to_i ? total_results : items_per_page
    end
  end

  def columns
    response ? response.column_headers.map { |c| c.name } : []
  end

  def rows
    response && response.rows ? response.rows : []
  end
end

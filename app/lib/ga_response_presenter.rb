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

  # Falls back to the export pages so CSV survives a failed display fetch.
  def columns
    resp = response || multi_page_response.first
    resp ? resp.column_headers.map { |c| c.name } : []
  end

  def rows
    response && response.rows ? response.rows : []
  end

  # nil when the row has no label or the report omits the column.
  def event_label(row)
    index = columns.index("ga:eventLabel")
    row[index] if index
  end

  # Labels are "id : title". Split once; the title may contain " : ".
  # GA has sent labels with embedded CRLF, hence the strip.
  def id(row)
    event_label(row)&.split(" : ", 2)&.first&.strip
  end

  def title(row)
    event_label(row)&.split(" : ", 2)&.last&.strip
  end
end

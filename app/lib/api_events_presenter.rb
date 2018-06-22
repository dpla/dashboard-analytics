class ApiEventsPresenter

  ##
  # @param [ApiEvents]
  def initialize(api_events)
    @api_events = api_events
  end

  def label
    "API item views"
  end

  def action
    "view"
  end

  def response
    @api_events.response
  end

  def multi_page_response
    @api_events.multi_page_response
  end

  def total_results
    response.total_results
  end

  def start_index
    response.query.start_index
  end

  def end_index
    response.total_results.to_i < response.items_per_page.to_i ? 
      response.total_results : response.items_per_page
  end

  def columns
    response.column_headers.map { |c| c.name }
  end

  def rows
    response.rows rescue []
  end

  def contributor(row)
    row[columns.index("ga:eventAction")]
  end

  def id(row)
    row[columns.index("ga:eventLabel")].split(" : ").first rescue nil
  end

  def title(row)
    row[columns.index("ga:eventLabel")].split(" : ").last rescue nil
  end

  def count(row)
    row[columns.index("ga:totalEvents")]
  end

  ##
  # Generate CSV of all events
  def to_csv
    attributes = ["Item", "Item ID", "Contributor", "View API Item"]

    CSV.generate({ headers: true }) do |csv|
      csv << attributes

      multi_page_response.each do |response|
        response.rows.each do |row|
          csv << [title(row), id(row), contributor(row), count(row)]
        end
      end
    end
  end
end

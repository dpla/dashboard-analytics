class WebsiteEventsPresenter  < GaResponsePresenter

  def label
    dict = {
      "View Item" => "Digital library catalog views",
      "View Exhibition Item" => "Exhibition views",
      "View Primary Source" => "Primary source set views",
      "Click Through" => "DPLA website click throughs"
    }

    dict.key?(@ga_response.event_name) ? dict[@ga_response.event_name] :
      @ga_response.event_name
  end

  def action
    @ga_response.event_name == "Click Through" ? "Click throughs" : "Views"
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
    attributes = ["Item", "Item ID", "Contributor", label]

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

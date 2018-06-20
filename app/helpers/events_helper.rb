module EventsHelper

  ##
  # @param [Google::Apis::AnalyticsV3::GaData]
  # @return Integer
  def end_index(response)
    response.total_results.to_i < response.items_per_page.to_i ? 
      response.total_results : response.items_per_page
  end

  def render_event_data(events)
    case params[:id]

    when 'click_through'
      table_name = "Click throughs"
      action = "Click throughs"
      render_item_table(events, table_name, action)

    when 'view_item'
      table_name = "Metadata record views"
      action = "Views"
      render_item_table(events, table_name, action)

    when 'view_exhibit'
      table_name = "Exhibit item views"
      action = "Views"
      render_item_table(events, table_name, action)

    when 'view_pss'
      table_name = "Primary source views"
      action = "Views"
      render_item_table(events, table_name, action)

    when 'view_api'
      table_name = "API item views"
      action = "Views"
      render_item_table(events, table_name, action)
      
    else
      "Invalid event id: #{events.id}."
    end
  end

  def render_item_table(events, table_name, action)
    render partial: 'shared/item_table',
           locals: { items: events.results,
                     table_name: table_name,
                     contributor: events.target.is_a?(Contributor),
                     action: action }
  end
end

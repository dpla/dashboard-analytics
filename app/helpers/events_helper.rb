module EventsHelper

  def render_event_data(events)
    case events.id

    when 'click_through'
      table_name = "Items clicked through on website"
      action = "Click throughs"
      render_item_table(events, table_name, action)

    when 'view_item'
      table_name = "Metadata records viewed on website"
      action = "Views"
      render_item_table(events, table_name, action)

    when 'view_exhibit'
      table_name = "Exhibition items viewed on website"
      action = "Views"
      render_item_table(events, table_name, action)

    when 'view_pss'
      table_name = "Primary source set items viewed on website"
      action = "Views"
      render_item_table(events, table_name, action)

    when 'view_api'
      table_name = "Items viewed in api"
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

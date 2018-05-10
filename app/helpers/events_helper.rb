module EventsHelper

  def render_view_item_table(items, target)
    table_name = "Metadata records viewed on website"
    action = "Views"
    render_item_table(items, target, table_name, action)
  end

  def render_view_exhibit_table(items, target)
    table_name = "Exhibition items viewed on website"
    action = "Views"
    render_item_table(items, target, table_name, action)
  end

  def render_view_pss_table(items, target)
    table_name = "Primary source set items viewed on website"
    action = "Views"
    render_item_table(items, target, table_name, action)
  end

  def render_click_through_table(items, target)
    table_name = "Items clicked through on website"
    action = "Click throughs"
    render_item_table(items, target, table_name, action)
  end

  def render_view_api_table(items, target)
    table_name = "Items viewed in api"
    action = "Views"
    render_item_table(items, target, table_name, action)
  end

  def render_item_table(items, target, table_name, action)
    render partial: 'shared/item_table',
           locals: { items: items,
                     table_name: table_name,
                     contributor: target.is_a?(Contributor),
                     action: action }
  end

  def render_event_data(event_id, target)
    case event_id
    when 'click_through'
      render_click_through_table(target.click_through_events, target)
    when 'view_item'
      render_view_item_table(target.view_item_events, target)
    when 'view_exhibit'
      render_view_exhibit_table(target.view_exhibit_events, target)
    when 'view_pss'
      render_view_pss_table(target.view_pss_events, target)
    when 'view_api'
      render_view_api_table(target.view_api_item_events, target)
    else
      "Invalid event id: #{event_id}."
    end
  end
end

module DataMenuHelper
  
  def render_overview_link(target)
    path = target.is_a?(Hub) ? hub_path(target.name) : 
      hub_contributor_path(target.hub.name, target.name)
    link_to("Overview", path, html_opts(path))
  end

  def render_locations_link(target)
    path = target.is_a?(Hub) ? hub_locations_path(target.name) :
      hub_contributor_locations_path(target.hub.name, target.name)
    link_to("Website user locations", path, html_opts(path))
  end

  def render_view_item_link(target)
    path = target.is_a?(Hub) ? hub_event_path(target.name, 'view_item') :
      hub_contributor_event_path(target.hub.name, target.name, 'view_item')
    link_to("Metadata record views", path, html_opts(path))
  end

  def render_view_exhibit_link(target)
    path = target.is_a?(Hub) ? hub_event_path(target.name, 'view_exhibit') : 
      hub_contributor_event_path(target.hub.name, target.name, 'view_exhibit')
    link_to("Exhibit item views", path, html_opts(path))
  end

  def render_view_pss_link(target)
    path = target.is_a?(Hub) ? hub_event_path(target.name, 'view_pss') : 
      hub_contributor_event_path(target.hub.name, target.name, 'view_pss')
    link_to("Primary source views", path, html_opts(path))
  end

  def render_click_through_link(target)
    path = target.is_a?(Hub) ? hub_event_path(target.name, 'click_through') : 
      hub_contributor_event_path(target.hub.name, target.name, 'click_through')
    link_to("Click throughs", path, html_opts(path))
  end

  def render_view_api_link(target)
    path = target.is_a?(Hub) ? hub_event_path(target.name, 'view_api') : 
      hub_contributor_event_path(target.hub.name, target.name, 'view_api')
    link_to("API item views", path, html_opts(path))
  end

  def html_opts(path)
    current_page?(path) ? { class: 'selected' } : {}
  end
end

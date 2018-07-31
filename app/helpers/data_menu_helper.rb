module DataMenuHelper
  
  def render_overview_link(target)
    path = target.is_a?(Hub) ?
      hub_path(target.name, date_opts) : 
      hub_contributor_path(target.hub.name, target.name, date_opts)

    link_to("Overview", path, html_opts(path))
  end

  def render_website_timelines_link(target)
    path = target.is_a?(Hub) ?
      hub_timeline_path(target.name, 'website', date_opts) :
      hub_contributor_timeline_path(target.hub.name, 'website', target.name, date_opts)

    link_to("Website usage timelines", path, html_opts(path))
  end

  def render_api_timelines_link(target)
    path = target.is_a?(Hub) ?
      hub_timeline_path(target.name, 'api', date_opts) :
      hub_contributor_timeline_path(target.hub.name, 'api', target.name, date_opts)

    link_to("API usage timelines", path, html_opts(path))
  end

  def render_locations_link(target)
    path = target.is_a?(Hub) ?
      hub_locations_path(target.name, date_opts) :
      hub_contributor_locations_path(target.hub.name, target.name, date_opts)

    link_to("Website user locations", path, html_opts(path))
  end

  def render_view_item_link(target)
    path = target.is_a?(Hub) ?
      hub_event_path(target.name, 'view_item', date_opts) :
      hub_contributor_event_path(target.hub.name, target.name, 'view_item', date_opts)

    link_to("Digital library catalog views", path, html_opts(path))
  end

  def render_view_exhibit_link(target)
    path = target.is_a?(Hub) ?
      hub_event_path(target.name, 'view_exhibit', date_opts) : 
      hub_contributor_event_path(target.hub.name, target.name, 'view_exhibit', date_opts)

    link_to("Exhibition views", path, html_opts(path))
  end

  def render_view_pss_link(target)
    path = target.is_a?(Hub) ?
      hub_event_path(target.name, 'view_pss', date_opts) : 
      hub_contributor_event_path(target.hub.name, target.name, 'view_pss', date_opts)

    link_to("Primary source set views", path, html_opts(path))
  end

  def render_click_through_link(target)
    path = target.is_a?(Hub) ?
      hub_event_path(target.name, 'click_through', date_opts) :
      hub_contributor_event_path(target.hub.name, target.name, 'click_through', date_opts)

    link_to("Click throughs", path, html_opts(path))
  end

  def render_view_api_link(target)
    path = target.is_a?(Hub) ?
      hub_event_path(target.name, 'view_api', date_opts) : 
      hub_contributor_event_path(target.hub.name, target.name, 'view_api', date_opts)

    link_to("API item views", path, html_opts(path))
  end

  def render_website_terms_link
    path = search_term_path('website', date_opts)
    link_to("Website", path, html_opts(path))
  end

  def render_api_terms_link
    path = search_term_path('api', date_opts)
    link_to("API", path, html_opts(path))
  end

  ##
  # Set HTML class to selected if the given path matches the current request
  # path. Parameters (e.g. start_date and end_date) are ignored.
  #
  # @param String
  #
  def html_opts(path)
    path.split("?").first == request.path ? { class: 'selected' } : {}
  end
end

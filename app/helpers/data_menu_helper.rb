module DataMenuHelper

  def render_overview_link(target)
    path = target.is_a?(Hub) ?
      hub_path(route_id(target.name), date_opts) :
      hub_contributor_path(route_id(target.hub.name), route_id(target.name), date_opts)

    link_to("Overview", path, html_opts(path))
  end

  def render_view_item_link(target)
    path = target.is_a?(Hub) ?
      hub_event_path(route_id(target.name), 'view_item', date_opts) :
      hub_contributor_event_path(route_id(target.hub.name), route_id(target.name), 'view_item', date_opts)

    link_to("Digital library catalog views", path, html_opts(path))
  end

  def render_view_exhibit_link(target)
    unless curated_participant?(target, :exhibitions)
      return disabled_menu_item("Exhibition views", "No items in DPLA exhibitions")
    end

    path = target.is_a?(Hub) ?
      hub_event_path(route_id(target.name), 'view_exhibit', date_opts) :
      hub_contributor_event_path(route_id(target.hub.name), route_id(target.name), 'view_exhibit', date_opts)

    link_to("Exhibition views", path, html_opts(path))
  end

  def render_view_pss_link(target)
    unless curated_participant?(target, :primary_source_sets)
      return disabled_menu_item("Primary source set views", "No items in DPLA primary source sets")
    end

    path = target.is_a?(Hub) ?
      hub_event_path(route_id(target.name), 'view_pss', date_opts) :
      hub_contributor_event_path(route_id(target.hub.name), route_id(target.name), 'view_pss', date_opts)

    link_to("Primary source set views", path, html_opts(path))
  end

  def render_click_through_link(target)
    path = target.is_a?(Hub) ?
      hub_event_path(route_id(target.name), 'click_through', date_opts) :
      hub_contributor_event_path(route_id(target.hub.name), route_id(target.name), 'click_through', date_opts)

    link_to("DPLA website click throughs", path, html_opts(path))
  end

  def render_wikimedia_readiness_link(target)
    unless wikimedia_participant?(target)
      return disabled_menu_item("Wikimedia readiness", "Not a Wikimedia pipeline participant")
    end

    path = target.is_a?(Hub) ?
      hub_wikimedia_preparations_path(route_id(target.name), date_opts) :
      hub_contributor_wikimedia_preparations_path(route_id(target.hub.name), route_id(target.name), date_opts)

    link_to("Wikimedia readiness", path, html_opts(path))
  end

  def wikimedia_participant?(target)
    target.is_a?(Hub) ?
      WikimediaParticipant.hub_participant?(target.name) :
      WikimediaParticipant.participant?(target.hub.name, target.name)
  end

  def disabled_menu_item(label, title)
    content_tag(:span, label, class: "disabled", title: title)
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

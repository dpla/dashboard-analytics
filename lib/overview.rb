class Overview

  # @param Hub || Contributor
  def initialize(target)
    @target = target
  end

  def target
    @target
  end

  def hub_name
    target.is_a?(Hub) ? target.name : target.hub.name
  end

  def contributor_name
    target.is_a?(Contributor) ? target.name : nil
  end

  def total_frontend_events
    frontend_use_totals['ga:totalEvents'] || 0
  end

  def frontend_sessions
    frontend_use_totals['ga:sessions'] || 0
  end

  def frontend_users
   frontend_use_totals['ga:users'] || 0
  end

  def total_view_events
    total_item_events + total_exhibit_events + total_pss_events
  end

  def total_item_events
    frontend_event_totals['View Item'].to_i rescue 0
  end

  def total_exhibit_events
    frontend_event_totals['View Exhibition Item'].to_i rescue 0
  end

  def total_pss_events
    frontend_event_totals['View Primary Source'].to_i rescue 0
  end

  def total_click_throughs
    frontend_event_totals['Click Through'] || 0
  end

  def total_api_events
    api_use_totals['ga:totalEvents'] || 0
  end

  def api_users
    api_use_totals['ga:users'] || 0
  end

  private

  def frontend_ga
    @frontend_ga ||= FrontendAnalytics.new(target.start_date, target.end_date)
  end

  def api_ga
    @api_ga ||= ApiAnalytics.new(target.start_date, target.end_date)
  end

  def frontend_use_totals
    @frontend_use_totals ||= 
      frontend_ga.overall_use_totals(hub_name, contributor_name)
  end

  def frontend_event_totals
    @frontend_event_totals ||= 
      frontend_ga.event_totals(hub_name, contributor_name)
  end

  def api_use_totals
    @api_use_totals ||= api_ga.overall_use_totals(hub_name, contributor_name)
  end
end

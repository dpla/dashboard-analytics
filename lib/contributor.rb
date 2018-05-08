class Contributor

  ##
  # Initialize a single contributor
  # 
  # @param name [String]
  # @param hub_name [String]
  # @param start_date [String]
  # @param end_date [String]
  #
  def initialize(name, hub_name, start_date, end_date)
    @name = name
    @hub = Hub.new(hub_name, start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  def name
    @name
  end

  def hub
    @hub
  end

  def start_date
    @start_date.iso8601
  end

  def end_date
    @end_date.iso8601
  end

  def ga_token
    @frontend_ga.token
  end

  def total_frontend_events
    frontend_use_totals['ga:totalEvents'] || 0
  end

  def unique_frontend_events
    frontend_use_totals['ga:uniqueEvents'] || 0
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

  def view_item_events
    frontend_ga.individual_event_counts("View Item", hub.name, name)
  end

  def view_exhibit_events
    frontend_ga.individual_event_counts("View Exhibition Item", hub.name, name)
  end

  def view_pss_events
    frontend_ga.individual_event_counts("View Primary Source", hub.name, name)
  end

  def click_through_events
    frontend_ga.individual_event_counts("Click Through", hub.name, name)
  end

  def view_api_item_events
    api_ga.individual_event_counts(hub.name, name)
  end

  def api_users
    api_use_totals['ga:users'] || 0
  end

  protected

  def self.dpla_api
    @@dpla_api ||= DplaApiResponseBuilder.new()
  end

  private

  def frontend_ga
    @frontend_ga ||= FrontendAnalytics.new(start_date, end_date)
  end

  def api_ga
    @api_ga ||= ApiAnalytics.new(start_date, end_date)
  end

  def frontend_use_totals
    @frontend_use_totals ||= frontend_ga.overall_use_totals(hub.name, name)
  end

  def frontend_event_totals
    @frontend_event_totals ||= frontend_ga.event_totals(hub.name, name)
  end

  def api_use_totals
    @api_use_totals ||= api_ga.overall_use_totals(hub.name, name)
  end
end

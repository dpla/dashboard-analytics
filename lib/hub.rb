class Hub

  ##
  # Get all the hub names from the DPLA API
  # @return [Array<String>]
  #
  def self.all
    dpla_api.hubs.sort
  end

  ##
  # Initialize a single hub
  # 
  # @param name [String]
  # @param start_date [String]
  # @param end_date [String]
  #
  def initialize(name, start_date, end_date)
    @name = name
    @start_date = start_date
    @end_date = end_date
  end

  def name
    @name
  end

  def start_date
    @start_date
  end

  def end_date
    @end_date
  end

  def ga_token
    frontend_ga.token
  end

  ##
  # Get all the contributors that belong to this hub instance
  #
  # @return [Array<String>]
  #
  def contributors
    @contributors ||= self.class.dpla_api.contributors(name).sort
    @contributors
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

  def total_item_events
    frontend_event_totals['View Item'] || 0
  end

  def total_exhibit_events
    frontend_event_totals['View Exhibition Item'] || 0
  end

  def total_pss_events
    frontend_event_totals['View Primary Source'] || 0
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
    @frontend_use_totals ||= frontend_ga.overall_use_totals(name)
  end

  def frontend_event_totals
    @frontend_event_totals ||= frontend_ga.event_totals(name)
  end

  def api_use_totals
    @api_use_totals ||= api_ga.overall_use_totals(name)
  end
end

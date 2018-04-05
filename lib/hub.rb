class Hub

  @@dpla_api = DplaApiResponseBuilder.new()

  ##
  # Get all the hub names from the DPLA API
  # @return [Array<String>]
  #
  def self.all
    @@dpla_api.hubs.sort
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
    @ga = GaResponseBuilder.new(start_date, end_date)
  end

  def name
    @name
  end

  def ga_token
    @ga.token
  end

  ##
  # Get all the contributors that belong to this hub instance
  #
  # @retrun [Array<String>]
  def contributors
    @@dpla_api.contributors(name).sort
  end

  def total_events
    overall_use_totals['ga:totalEvents'] || 0
  end

  def unique_events
    overall_use_totals['ga:uniqueEvents'] || 0
  end

  def sessions
    overall_use_totals['ga:sessions'] || 0
  end

  def users
   overall_use_totals['ga:users'] || 0
  end

  def total_item_events
    event_totals['View Item'] || 0
  end

  def total_exhibit_events
    event_totals['View Exhibition Item'] || 0
  end

  def total_pss_events
    event_totals['View Primary Source'] || 0
  end

  def total_click_throughs
    event_totals['Click Through'] || 0
  end

  private

  def overall_use_totals
    @overall_use_totals ||= @ga.hub_overall_use_totals(name)
  end

  def event_totals
    @event_totals ||= @ga.hub_event_totals(name)
  end
end

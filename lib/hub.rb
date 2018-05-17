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
    @start_date.iso8601
  end

  def end_date
    @end_date.iso8601
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

  ##
  # Get all contributors and their associated key metrics.
  # @return [Hash]
  # e.g. { "The Library" => { "Website" => { "Users" => 4 },
  #                           "Api" => { "Users" => 6 } } }
  def contributor_totals
    data = {}

    contributors.map do |c|
      f_use = frontend_use_by_contributor[c] || {}
      f_events = frontend_events_by_contributor[c] || {}
      # TODO: only call API if date range applies
      a_use = api_use_by_contributor[c] || {}
      data[c] = { "Website" => f_use.merge(f_events),
                  "Api" => a_use }
    end

    data
  end

  def metadata_completeness
    MetadataCompleteness.new(self)
  end

  def events(event_id)
    Events.new(self, event_id)
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

  def view_api_item_events
    api_ga.individual_event_counts(name)
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

  def frontend_use_by_contributor
    @frontend_use_by_contributor ||= frontend_ga.overall_use_by_contributor(name)
  end

  def frontend_events_by_contributor
    @frontend_events_by_contributor ||= frontend_ga.events_by_contributor(name)
  end

  def api_use_totals
    @api_use_totals ||= api_ga.overall_use_totals(name)
  end

  def api_use_by_contributor
    @api_use_by_contributor ||= api_ga.overall_use_by_contributor(name)
  end
end

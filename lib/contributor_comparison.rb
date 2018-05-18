class ContributorComparison

  # @param hub Hub
  def initialize(hub)
    @hub= hub
  end

  def hub
    @hub
  end

  ##
  # Get all contributors and their associated key metrics.
  # @return [Hash]
  # e.g. { "The Library" => { "Website" => { "Users" => 4 },
  #                           "Api" => { "Users" => 6 } } }
  def totals
    data = {}

    hub.contributors.map do |c|
      f_use = frontend_use_by_contributor[c] || {}
      f_events = frontend_events_by_contributor[c] || {}
      # TODO: only call API if date range applies
      a_use = api_use_by_contributor[c] || {}
      data[c] = { "Website" => f_use.merge(f_events),
                  "Api" => a_use }
    end

    data
  end

  private

  def frontend_ga
    @frontend_ga ||= FrontendAnalytics.new(hub.start_date, hub.end_date)
  end

  def api_ga
    @api_ga ||= ApiAnalytics.new(hub.start_date, hub.end_date)
  end

  def frontend_use_by_contributor
    @frontend_use_by_contributor ||=
      frontend_ga.overall_use_by_contributor(hub.name)
  end

  def frontend_events_by_contributor
    @frontend_events_by_contributor ||=
      frontend_ga.events_by_contributor(hub.name)
  end

  def api_use_by_contributor
    @api_use_by_contributor ||= 
      api_ga.overall_use_by_contributor(hub.name)
  end
end
class Events

  # @param target Hub || Contributor
  # @param event_type String
  #   acceptable values: "View Item", "View Exhibition Item",
  #                      "View Primary Source", "Click Through"
  def initialize(target, event_type)
    @target = target
    @event_type = event_type
  end

  def target
    @target
  end

  def event_type
    @event_type
  end

  def hub_name
    target.is_a?(Hub) ? target.name : target.hub.name
  end

  def contributor_name
    target.is_a?(Contributor) ? target.name : nil
  end

  def results
    frontend_response[:events]
  end

  def total_results
  end

  def items_per_page
  end

  def start_index
  end

  private

  def frontend_ga
    @frontend_ga ||= FrontendAnalytics.new(target.start_date, target.end_date)
  end

  def frontend_response
    @frontend_response ||=
      frontend_ga.events(event_type, hub_name, contributor_name)
  end
end

class Events

  # @param target Hub || Contributor
  # @param event_type String
  #   acceptable values: "View Item", "View Exhibition Item",
  #                      "View Primary Source", "Click Through"
  def initialize(target, id)
    @target = target
    @id = id
  end

  def id
    @id
  end

  def target
    @target
  end

  def event_name
    dict = { 'view_item' => 'View Item',
             'view_exhibit' => 'View Exhibition Item',
             'view_pss' => 'View Primary Source',
             'click_through' => 'Click Through',
             'view_api' => 'View API Item' }

    dict[id]
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
    frontend_response[:total_results]
  end

  def items_per_page
    frontend_response[:items_per_page]
  end

  def start_index
    frontend_response[:start_index]
  end

  private

  def frontend_ga
    @frontend_ga ||= FrontendAnalytics.new(target.start_date, target.end_date)
  end

  def frontend_response
    @frontend_response ||=
      frontend_ga.events(event_name, hub_name, contributor_name)
  end
end

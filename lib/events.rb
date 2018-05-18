class Events

  # @param target Hub || Contributor
  # @param id String e.g. view_item, click_through, etc.
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

  def response
    id == 'view_api' ? api_response : frontend_response
  end

  def hub_name
    target.is_a?(Hub) ? target.name : target.hub.name
  end

  def contributor_name
    target.is_a?(Contributor) ? target.name : nil
  end

  def results
    response[:results]
  end

  def total_results
    response[:total_results]
  end

  def items_per_page
    response[:items_per_page]
  end

  def start_index
    response[:start_index]
  end

  def end_index
    total_results < items_per_page ? total_results : items_per_page
  end

  private

  def frontend_ga
    target.frontend_ga
  end

  def api_ga
    target.api_ga
  end

  def frontend_response
    @frontend_response ||=
      frontend_ga.events(event_name, hub_name, contributor_name)
  end

  def api_response
    @api_response ||= api_ga.events(event_name, hub_name, contributor_name)
  end
end

class Events

  # @param Hub || Contributor
  def initialize(target)
    @target = target
  end

  def target
    @target
  end

  def start_date
    target.start_date
  end

  def end_date
    target.end_date
  end

  def hub_name
    target.is_a?(Hub) ? target.name : target.hub.name
  end

  def contributor_name
    target.is_a?(Contributor) ? target.name : nil
  end

  def view_item
    frontend_ga.individual_event_counts("View Item", hub_name, contributor_name)[:events]
  end

  def view_exhibit
    frontend_ga.individual_event_counts("View Exhibition Item", hub_name, contributor_name)[:events]
  end

  def view_pss
    frontend_ga.individual_event_counts("View Primary Source", hub_name, contributor_name)[:events]
  end

  def click_through
    frontend_ga.individual_event_counts("Click Through", hub_name, contributor_name)[:events]
  end

  private

  def frontend_ga
    @frontend_ga ||= FrontendAnalytics.new(start_date, end_date)
  end
end

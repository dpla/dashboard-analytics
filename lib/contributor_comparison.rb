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
      mc = contributor_mc(c) || {}
      data[c] = { "Website" => f_use.merge(f_events),
                  "Api" => a_use,
                  "MetadataCompleteness" => mc }
    end

    data
  end

  # def show_contributors_mc
  #   hub.contributors.map do |c|
  #     contributor_mc(c)
  #   end
  # end

  def contributor_mc(contributor)
    all_contributors_mc.find do |row|
      row['dataProvider'] == contributor
    end
  end

  private

  def frontend_ga
    hub.frontend_ga
  end

  def api_ga
    hub.api_ga
  end

  def metadata_completeness
    @mc ||= MetadataCompleteness.new(hub)
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

  def all_contributors_mc
    @all_contributors_mc ||= metadata_completeness.all_contributors_data
  end
end

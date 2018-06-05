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

  def contributor_mc(contributor)
    all_contributors_mc.find do |row|
      row['dataProvider'] == contributor
    end
  end

  def to_csv
    attributes = [ "Contributor",
                   "Website Sessions",
                   "Website Users",
                   "Website Views",
                   "Website Click Throughs",
                   "API Views",
                   "API Users" ]

    MetadataCompleteness.fields.each do |field|
      attributes.push(field.titleize + " Completeness")
    end

    CSV.generate({ headers: true }) do |csv|
      csv << attributes

      totals.each do |contributor|

        website = contributor[1]["Website"]
        api = contributor[1]["Api"]
        mc = contributor[1]["MetadataCompleteness"]

        data =[ contributor[0],
                website["Sessions"],
                website["Users"],
                website["Views"],
                website["Click Throughs"],
                api["Views"],
                api["Users"] ]

        MetadataCompleteness.fields.each do |field|
          data.push(metadata_completeness.field_data[field])
        end

        csv << data
      end
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

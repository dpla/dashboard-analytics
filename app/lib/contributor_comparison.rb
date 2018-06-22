class ContributorComparison

  def self.build
    builder = new
    yield(builder)
    builder
  end

  def initialize
    @contributors = nil
    @website_overview = nil
    @website_events = nil
    @api_overview = nil
    @metadata_completeness = nil
  end

  # @param [Array<String>]
  def contributors=(contributors)
    @contributors = contributors
  end

  # @param WebsiteOverviewByContributor
  def website_overview=(website_overview)
    @website_overview = website_overview
  end

  # @param WebsiteEventsByContributor
  def website_events=(website_events)
    @website_events = website_events
  end

  # @param ApiOverviewByContributor
  def api_overview=(api_overview)
    @api_overview = api_overview
  end

  # @param MetadataCompleteness
  def metadata_completeness=(metadata_completeness)
    @metadata_completeness = metadata_completeness
  end

  ##
  # Get all contributors and their associated key metrics.
  # @return [Hash]
  # e.g. { "The Library" => { "Website" => { "Users" => 4 },
  #                           "Api" => { "Users" => 6 } } }
  def totals
    data = {}

    @contributors.map do |c|
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

  ##
  # Generate a CSV file with the data from totals.
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

        MetadataCompleteness.fields.each { |field| data.push(mc[field]) }

        csv << data
      end
    end
  end

  private

  def frontend_use_by_contributor
    @website_overview.parse_data
  end

  def frontend_events_by_contributor
    @website_events.parse_data
  end

  def api_use_by_contributor
    @api_overview.parse_data
  end

  def all_contributors_mc
    @all_contributors_mc ||= @metadata_completeness.all_contributors_data
  end
end

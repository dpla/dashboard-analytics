class ContributorComparison

  def self.build
    builder = new
    yield(builder)
    builder
  end

  def initialize
    @hub = nil
    @contributors_item_count = nil
    @website_overview = nil
    @website_events = nil
    @bws_item_count = nil
    @bws_overview = nil
    @bws_events = nil
    @api_overview = nil
    @mc_presenter = nil
    @wp_presenter = nil
    @wa_presenter = nil
  end

  ##
  # @param [String]
  def hub=(hub)
    @hub = hub
  end

  # @param [Array<Hash>]
  def contributors_item_count=(contributors_item_count)
    @contributors_item_count = contributors_item_count
  end

  # @param WebsiteOverviewByContributor
  def website_overview=(website_overview)
    @website_overview = website_overview
  end

  # @param WebsiteEventsByContributor
  def website_events=(website_events)
    @website_events = website_events
  end

  # @param [Array<Hash>]
  def bws_item_count=(bws_item_count)
    @bws_item_count = bws_item_count
  end

  # @param BwsOverviewByContributor
  def bws_overview=(bws_overview)
    @bws_overview = bws_overview
  end

  # @param BwsEventsByContributor
  def bws_events=(bws_events)
    @bws_events = bws_events
  end

  # @param ApiOverviewByContributor
  def api_overview=(api_overview)
    @api_overview = api_overview
  end

  # @param MetadataCompletenessPresenter
  def mc_presenter=(mc_presenter)
    @mc_presenter = mc_presenter
  end

  # @param WikimediaPreparationsPresenter
  def wp_presenter=(wp_presenter)
    @wp_presenter = wp_presenter
  end

  # @param WikimediaAnalyticsPresenter
  def wa_presenter=(wa_presenter)
    @wa_presenter = wa_presenter
  end

  def contributors
    @contributors_item_count.map { |c| c['term'] }
  end

  ##
  # Get all contributors and their associated key metrics.
  # @return [Hash]
  # e.g. { "The Library" => { "Website" => { "Users" => 4 },
  #                           "Api" => { "Users" => 6 } } }
  def totals
    data = {}

    @contributors_item_count.map do |c|
      contributor = c["term"]
      count = c["count"]
      f_use = frontend_use_by_contributor[contributor] || {}
      f_events = frontend_events_by_contributor[contributor] || {}
      b_count = { "ItemCount" => @bws_item_count[contributor] || nil }
      b_use = bws_use_by_contributor[contributor] || {}
      b_events = bws_events_by_contributor[contributor] || {}
      # TODO: only call API if date range applies
      a_use = api_use_by_contributor[contributor] || {}
      mc = contributor_mc(contributor) || {}
      wp = contributor_wp(contributor) || {}
      wa = contributor_wa(contributor) || {}

      data[contributor] = { "Website" => f_use.merge(f_events),
                            "BWS" => b_use.merge(b_events).merge(b_count),
                            "Api" => a_use,
                            "MetadataCompleteness" => mc,
                            "ItemCount" => count,
                            "WikimediaPreparations" => wp,
                            "WikimediaAnalytics" => wa }
    end

    data
  end

  def contributor_mc(contributor)
    all_contributors_mc.find do |row|
      row['dataProvider'] == contributor
    end
  end

  def contributor_wp(contributor)
    all_contributors_wp.find do |row|
      row['dataProvider'] == contributor
    end
  end

  def contributor_wa(contributor)
    all_contributors_wa.find do |row|
      row['Institution'] == contributor
    end
  end

  ##
  # Generate a CSV file with the data from totals.
  def to_csv
    attributes = [ "Contributor",
                   "Website Sessions",
                   "Website Users",
                   "Website Item Views",
                   "Website Click Throughs",
                   "BWS Item Count",
                   "BWS Sessions",
                   "BWS Users",
                   "BWS Item Views",
                   "BWS Click Throughs",
                   "API Views",
                   "API Users",
                   "Item Count" ]

    WikimediaPreparationsPresenter.fields.each do |field|
      attributes.push(field.titleize)
    end

    WikimediaAnalyticsPresenter.fields.each do |field|
      attributes.push(field.titleize)
    end

    MetadataCompletenessPresenter.fields.each do |field|
      attributes.push(field.titleize + " Completeness") unless field == "count"
    end

    CSV.generate({ headers: true }) do |csv|
      csv << attributes

      totals.each do |contributor|

        website = contributor[1]["Website"]
        bws = contributor[1]["BWS"]
        api = contributor[1]["Api"]
        mc = contributor[1]["MetadataCompleteness"]
        wp = contributor[1]["WikimediaPreparations"]
        wa = contributor[1]["WikimediaAnalytics"]
        count = contributor[1]["ItemCount"]

        data =[ contributor[0],
                website["Sessions"],
                website["Users"],
                website["Views"],
                website["Click Throughs"],
                bws["ItemCount"],
                bws["Sessions"],
                bws["Users"],
                bws["Views"],
                bws["Click Throughs"],
                api["Views"],
                api["Users"],
                count ]

        WikimediaPreparationsPresenter.fields.each do |field|
          data.push(wp[field])
        end

        WikimediaAnalyticsPresenter.fields.each do |field|
          data.push(wa[field])
        end

        MetadataCompletenessPresenter.fields.each do |field| 
          data.push(mc[field]) unless field == "count"
        end

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

  def bws_use_by_contributor
    @bws_overview.parse_data
  end

  def bws_events_by_contributor
    @bws_events.parse_data
  end

  def api_use_by_contributor
    @api_overview.parse_data
  end

  def all_contributors_mc
    @all_contributors_mc ||= @mc_presenter.all_contributors(@hub)
  end

  def all_contributors_wp
    @all_contributors_wp ||= @wp_presenter.all_contributors(@hub)
  end

  def all_contributors_wa
    @all_contributors_wa ||= @wa_presenter.all_contributors(@hub)
  end
end

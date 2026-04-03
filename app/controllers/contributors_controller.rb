# Handles HTTP requests for contributors

class ContributorsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper
  include MetadataCompletenessHelper
  include TooltipsHelper

  def index
    assign_start_and_end_dates
    @hub = Hub.new(params[:hub_id], @start_date, @end_date)

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_contributors_path(current_user.hub)
    end
  end

  def show
    assign_start_and_end_dates
    @contributor = Contributor.new(params[:id],
                                   params[:hub_id],
                                   @start_date,
                                   @end_date)

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end


  ##
  # Single async endpoint that loads all four data sections for the contributor show page
  # concurrently, returning one combined HTML response instead of four.
  #
  def sections
    assign_start_and_end_dates

    hub_id     = params[:hub_id]
    contrib_id = params[:contributor_id]
    all_start  = min_date
    all_end    = max_date
    end_date   = @end_date

    item_count_t = Thread.new { DplaApiResponseBuilder.new.item_count(hub_id, contrib_id) rescue nil }
    website_views_t = Thread.new do
      WebsiteOverview.build { |b|
        b.hub = hub_id; b.contributor = contrib_id; b.start_date = all_start; b.end_date = all_end
      }.events
    rescue => e
      Rails.logger.error(e); nil
    end
    wiki_views_t = Thread.new do
      WikimediaAnalyticsPresenter.new(
        start_month: all_start.strftime("%Y-%m"), end_month: all_end.strftime("%Y-%m")
      ).contributor(hub_id, contrib_id)["Page views"]
    rescue => e
      Rails.logger.error(e); nil
    end
    website_overview_t = Thread.new do
      WebsiteOverview.build { |b|
        b.hub = hub_id; b.contributor = contrib_id; b.start_date = all_start; b.end_date = all_end
      }
    rescue => e
      Rails.logger.error(e); nil
    end
    website_events_t = Thread.new do
      WebsiteEventTotals.build { |b|
        b.hub = hub_id; b.contributor = contrib_id; b.start_date = all_start; b.end_date = all_end
      }
    rescue => e
      Rails.logger.error(e); nil
    end
    mc_thread = Thread.new do
      mc = MetadataCompleteness.build { |b|
        b.hub = hub_id; b.contributor = contrib_id; b.end_date = end_date
      }
      {
        wp: WikimediaPreparationsPresenter.new(mc).contributor(hub_id, contrib_id),
        wa: WikimediaAnalyticsPresenter.new(
              start_month: all_start.strftime("%Y-%m"),
              end_month:   all_end.strftime("%Y-%m")
            ).contributor(hub_id, contrib_id),
        mc: MetadataCompletenessPresenter.new(mc).contributor(hub_id, contrib_id)
      }
    rescue => e
      Rails.logger.error(e); {}
    end

    [item_count_t, website_views_t, wiki_views_t,
     website_overview_t, website_events_t, mc_thread].each(&:join)

    mc_data = mc_thread.value || {}

    @item_count           = item_count_t.value
    @website_views        = website_views_t.value
    @wikimedia_views      = wiki_views_t.value
    @website_overview     = website_overview_t.value
    @website_event_totals = website_events_t.value
    @wp_data              = mc_data[:wp]
    @wa_data              = mc_data[:wa]
    @mc_data              = mc_data[:mc]
    @wikimedia_participant = WikimediaParticipant.where(hub: hub_id, contributor: contrib_id).pick(:participant) || false
    @target               = Contributor.new(contrib_id, hub_id, all_start, all_end)

    render partial: "shared/contributor_sections"
  end

  def contributor_website_overview
    assign_all_time_dates

    @website_overview = WebsiteOverview.build do |builder|
      builder.hub         = params[:hub_id]
      builder.contributor = params[:contributor_id]
      builder.start_date  = @start_date
      builder.end_date    = @end_date
    end

    @website_event_totals = WebsiteEventTotals.build do |builder|
      builder.hub         = params[:hub_id]
      builder.contributor = params[:contributor_id]
      builder.start_date  = @start_date
      builder.end_date    = @end_date
    end

    render partial: "shared/frontend_use_metrics"
  end

  def contributor_api_overview
    assign_start_and_end_dates

    @api_overview = ApiOverview.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:contributor_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    render partial: "shared/api_use_metrics"
  end

  def contributor_bws_overview
    assign_start_and_end_dates

    @bws_item_count = DplaApiResponseBuilder.new()
      .bws_item_count(params[:hub_id], params[:contributor_id])

    @bws_overview = BwsOverview.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:contributor_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    @bws_event_totals = BwsEventTotals.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:contributor_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    render partial: "shared/bws_use_metrics"
  end

  def contributor_item_count
    @item_count = DplaApiResponseBuilder.new()
      .item_count(params[:hub_id], params[:contributor_id])

    render partial: "shared/item_count"
  end

  def contributor_totals
    api = DplaApiResponseBuilder.new
    results = [
      Thread.new {
        begin
          api.item_count(params[:hub_id], params[:contributor_id])
        rescue => e
          Rails.logger.error(e)
          nil
        end
      },
      Thread.new {
        begin
          WebsiteOverview.build do |b|
            b.hub         = params[:hub_id]
            b.contributor = params[:contributor_id]
            b.start_date  = min_date
            b.end_date    = max_date
          end.events
        rescue => e
          Rails.logger.error(e)
          nil
        end
      },
      Thread.new {
        begin
          WikimediaAnalyticsPresenter.new(
            start_month: min_date.strftime("%Y-%m"),
            end_month:   max_date.strftime("%Y-%m")
          ).contributor(params[:hub_id], params[:contributor_id])["Page views"]
        rescue => e
          Rails.logger.error(e)
          nil
        end
      }
    ].map(&:value)

    @item_count      = results[0]
    @website_views   = results[1]
    @wikimedia_views = results[2]

    render partial: "shared/totals"
  end

  def contributor_metadata_completeness
    assign_start_and_end_dates

    metadata_completeness = MetadataCompleteness.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:contributor_id]
      builder.end_date = @end_date
    end

    mc_presenter = MetadataCompletenessPresenter.new(metadata_completeness)
    @mc_data = mc_presenter.contributor(params[:hub_id], params[:contributor_id])
    render partial: "shared/metadata_completeness"
  end

  def contributor_wikimedia_overview
    assign_all_time_dates

    # Fetch item_count concurrently while building Wikimedia data.
    item_count_thread = Thread.new do
      DplaApiResponseBuilder.new.item_count(params[:hub_id], params[:contributor_id])
    rescue => e
      Rails.logger.error(e)
      nil
    end

    metadata_completeness = MetadataCompleteness.build do |builder|
      builder.hub         = params[:hub_id]
      builder.contributor = params[:contributor_id]
      builder.end_date    = @end_date
    end

    wp_presenter = WikimediaPreparationsPresenter.new(metadata_completeness)
    @wp_data = wp_presenter.contributor(params[:hub_id], params[:contributor_id])

    wa_presenter = WikimediaAnalyticsPresenter.new(
      start_month: @start_date.strftime("%Y-%m"),
      end_month:   @end_date.strftime("%Y-%m")
    )
    @wa_data = wa_presenter.contributor(params[:hub_id], params[:contributor_id])

    @item_count            = item_count_thread.value
    @wikimedia_participant = WikimediaParticipant.where(hub: params[:hub_id], contributor: params[:contributor_id]).pick(:participant) || false
    @target                = Contributor.new(params[:contributor_id],
                                             params[:hub_id],
                                             @start_date,
                                             @end_date)

    render partial: "shared/wikimedia_overview"
  end

  def contributor_comparison
    assign_start_and_end_dates

    # Build objects first — no network calls yet.
    website_overview = WebsiteOverviewByContributor.build do |builder|
      builder.hub = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    website_events = WebsiteEventsByContributor.build do |builder|
      builder.hub = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    bws_overview = BwsOverviewByContributor.build do |builder|
      builder.hub = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    bws_events = BwsEventsByContributor.build do |builder|
      builder.hub = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    api_overview = ApiOverviewByContributor.build do |builder|
      builder.hub = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    metadata_completeness = MetadataCompleteness.build do |builder|
      builder.hub = params[:hub_id]
      builder.end_date = @end_date
    end

    # Fire all five independent network calls concurrently. DPLA API results
    # are returned directly; GA4/S3 calls warm each object's memoized cache
    # so ContributorComparison#totals reads from memory instead of the network.
    hub_id = params[:hub_id]
    results = [
      Thread.new { DplaApiResponseBuilder.new.contributors_item_count(hub_id) },
      Thread.new { DplaApiResponseBuilder.new.contributors_bws_item_count(hub_id) },
      Thread.new { website_overview.response },
      Thread.new { website_events.response },
      Thread.new { metadata_completeness.contributor_csv },
    ].map(&:value)

    contributors_item_count = results[0]
    bws_item_count          = results[1]

    mc_presenter = MetadataCompletenessPresenter.new(metadata_completeness)
    wp_presenter = WikimediaPreparationsPresenter.new(metadata_completeness)
    wa_presenter = WikimediaAnalyticsPresenter.new(
      start_month: @start_date.strftime("%Y-%m"),
      end_month:   @end_date.strftime("%Y-%m")
    )

    @contributor_comparison = ContributorComparison.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributors_item_count = contributors_item_count
      builder.website_overview = website_overview
      builder.website_events = website_events
      builder.bws_item_count = bws_item_count
      builder.bws_overview = bws_overview
      builder.bws_events = bws_events
      builder.api_overview = api_overview
      builder.mc_presenter = mc_presenter
      builder.wp_presenter = wp_presenter
      builder.wa_presenter = wa_presenter
    end

    respond_to do |format|
      format.html { render partial: "shared/contributor_comparison" }
      format.csv { send_data @contributor_comparison.to_csv }
    end
  end
end

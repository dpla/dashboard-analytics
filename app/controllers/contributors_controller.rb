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
    return render_not_found unless Hub.exists?(params[:hub_id])

    unless current_user.hub == params[:hub_id] || admin_for_all_hubs?
      return redirect_to hub_contributors_path(current_user.hub)
    end

    assign_start_and_end_dates
    @hub = Hub.new(params[:hub_id], @start_date, @end_date)
    begin
      @contributors_item_count = Hub.contributors_item_count(params[:hub_id])
    rescue => e
      Rails.logger.error(e)
      @contributors_item_count = []
    end
  end

  def show
    return render_not_found unless Hub.exists?(params[:hub_id])
    return render_not_found unless Hub.contributor?(params[:hub_id], params[:id])

    assign_start_and_end_dates
    @contributor = Contributor.new(params[:id],
                                   params[:hub_id],
                                   @start_date,
                                   @end_date)

    # Pre-load S3-cached count so the totals card renders on initial page load.
    @item_count = Hub.item_count(params[:hub_id], params[:id])
    @target     = @contributor

    unless current_user.hub == params[:hub_id] || admin_for_all_hubs?
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
    contrib_id = params[:id]
    all_start  = min_date
    all_end    = max_date
    end_date   = @end_date

    @item_count = Hub.item_count(hub_id, contrib_id)
    wiki_views_t = Thread.new do
      WikimediaAnalyticsPresenter.new(
        start_month: all_start.strftime("%Y-%m"), end_month: all_end.strftime("%Y-%m")
      ).contributor(hub_id, contrib_id)["Page views"]
    rescue => e
      Rails.logger.error(e); nil
    end
    website_overview_t = Thread.new do
      overview = WebsiteOverview.build { |b|
        b.hub = hub_id; b.contributor = contrib_id; b.start_date = @start_date; b.end_date = @end_date
      }
      overview.response
      overview
    rescue => e
      Rails.logger.error(e); nil
    end
    website_events_t = Thread.new do
      WebsiteEventTotals.build { |b|
        b.hub = hub_id; b.contributor = contrib_id; b.start_date = @start_date; b.end_date = @end_date
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

    [wiki_views_t,
     website_overview_t, website_events_t, mc_thread].each(&:join)

    mc_data = mc_thread.value || {}

    @website_views        = website_overview_t.value&.events
    @wikimedia_views      = wiki_views_t.value
    @website_overview     = website_overview_t.value
    @website_event_totals = website_events_t.value
    @wp_data              = mc_data[:wp]
    @wa_data              = mc_data[:wa]
    @mc_data              = mc_data[:mc]
    @wikimedia_participant = WikimediaParticipant.participant?(hub_id, contrib_id)
    @target               = Contributor.new(contrib_id, hub_id, all_start, all_end)

    render partial: "shared/contributor_sections"
  end

  def contributor_website_overview
    assign_all_time_dates

    @website_overview = WebsiteOverview.build do |builder|
      builder.hub         = params[:hub_id]
      builder.contributor = params[:id]
      builder.start_date  = @start_date
      builder.end_date    = @end_date
    end

    @website_event_totals = WebsiteEventTotals.build do |builder|
      builder.hub         = params[:hub_id]
      builder.contributor = params[:id]
      builder.start_date  = @start_date
      builder.end_date    = @end_date
    end

    render partial: "shared/frontend_use_metrics"
  end

  def contributor_api_overview
    assign_start_and_end_dates

    @api_overview = ApiOverview.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    render partial: "shared/api_use_metrics"
  end

  def contributor_bws_overview
    assign_start_and_end_dates

    @bws_item_count = Hub.bws_item_count(params[:hub_id], params[:id])

    @bws_overview = BwsOverview.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    @bws_event_totals = BwsEventTotals.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    render partial: "shared/bws_use_metrics"
  end

  def contributor_item_count
    @item_count = Hub.item_count(params[:hub_id], params[:id])
    render partial: "shared/item_count"
  end

  def contributor_totals
    @item_count = Hub.item_count(params[:hub_id], params[:id])

    results = [
      Thread.new {
        begin
          WebsiteOverview.build do |b|
            b.hub         = params[:hub_id]
            b.contributor = params[:id]
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
          ).contributor(params[:hub_id], params[:id])["Page views"]
        rescue => e
          Rails.logger.error(e)
          nil
        end
      }
    ].map(&:value)

    @website_views   = results[0]
    @wikimedia_views = results[1]

    render partial: "shared/totals"
  end

  def contributor_metadata_completeness
    assign_start_and_end_dates

    metadata_completeness = MetadataCompleteness.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:id]
      builder.end_date = @end_date
    end

    mc_presenter = MetadataCompletenessPresenter.new(metadata_completeness)
    @mc_data = mc_presenter.contributor(params[:hub_id], params[:id])
    render partial: "shared/metadata_completeness"
  end

  def contributor_wikimedia_overview
    assign_all_time_dates

    metadata_completeness = MetadataCompleteness.build do |builder|
      builder.hub         = params[:hub_id]
      builder.contributor = params[:id]
      builder.end_date    = @end_date
    end

    wp_presenter = WikimediaPreparationsPresenter.new(metadata_completeness)
    @wp_data = wp_presenter.contributor(params[:hub_id], params[:id])

    wa_presenter = WikimediaAnalyticsPresenter.new(
      start_month: @start_date.strftime("%Y-%m"),
      end_month:   @end_date.strftime("%Y-%m")
    )
    @wa_data = wa_presenter.contributor(params[:hub_id], params[:id])

    @item_count            = Hub.item_count(params[:hub_id], params[:id])
    @wikimedia_participant = WikimediaParticipant.participant?(params[:hub_id], params[:id])
    @target                = Contributor.new(params[:id],
                                             params[:hub_id],
                                             @start_date,
                                             @end_date)

    render partial: "shared/wikimedia_overview"
  end

  def contributor_comparison
    assign_start_and_end_dates

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

    hub_id = params[:hub_id]
    contributors_item_count = Hub.contributors_item_count(hub_id)
    bws_item_count          = Hub.contributors_bws_item_count(hub_id)

    # For HTML the GA website columns load async via contributor_ga_data; pass nil
    # so the table renders immediately from fast S3/DB caches.
    # For CSV exports, prefetch GA data so the download is complete.
    website_overview = nil
    website_events   = nil
    threads = [Thread.new { metadata_completeness.contributor_csv }]
    if request.format.csv?
      website_overview = WebsiteOverviewByContributor.build do |builder|
        builder.hub = params[:hub_id]; builder.start_date = @start_date; builder.end_date = @end_date
      end
      website_events = WebsiteEventsByContributor.build do |builder|
        builder.hub = params[:hub_id]; builder.start_date = @start_date; builder.end_date = @end_date
      end
      threads << Thread.new { website_overview.response }
      threads << Thread.new { website_events.response }
    end
    threads.each(&:value)

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
      builder.website_events   = website_events
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

  ##
  # Returns GA website metrics for all contributors in a hub as JSON.
  # Called asynchronously by the comparison table after it renders.
  #
  def contributor_ga_data
    hub_id = params[:hub_id]
    return head :not_found unless Hub.exists?(hub_id)
    unless current_user.hub == hub_id || admin_for_all_hubs?
      return head :forbidden
    end

    assign_start_and_end_dates

    website_overview = WebsiteOverviewByContributor.build do |builder|
      builder.hub        = hub_id
      builder.start_date = @start_date
      builder.end_date   = @end_date
    end

    website_events = WebsiteEventsByContributor.build do |builder|
      builder.hub        = hub_id
      builder.start_date = @start_date
      builder.end_date   = @end_date
    end

    [
      Thread.new { website_overview.response },
      Thread.new { website_events.response }
    ].each(&:value)

    overview_data = website_overview.parse_data
    events_data   = website_events.parse_data

    result = Hub.contributors_item_count(hub_id).each_with_object({}) do |c, hash|
      contributor = c["term"]
      ga_key      = contributor[0, GaResponseBuilder::GA4_EVENT_NAME_MAX_LENGTH]
      ov          = overview_data[ga_key] || {}
      ev          = events_data[ga_key]   || {}
      hash[contributor] = {
        "views"          => ev["Views"]          || 0,
        "click-throughs" => ev["Click Throughs"] || 0,
        "sessions"       => ov["Sessions"]       || 0,
        "users"          => ov["Users"]          || 0
      }
    end

    render json: result
  rescue => e
    Rails.logger.error(e)
    render json: {}, status: :service_unavailable
  end
end

# Handles HTTP requests for hubs

class HubsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper
  include MetadataCompletenessHelper
  include TooltipsHelper

  before_action :authorize_hub_scope!, only: %i[
    sections website_overview api_overview bws_overview
    item_count totals metadata_completeness wikimedia_overview
  ]

  def index
    return redirect_to(hub_path(route_id(current_user.hub))) unless admin_for_all_hubs?

    assign_start_and_end_dates
    @hubs = Hub.all_with_counts
  end

  def show
    return render_not_found unless Hub.exists?(params[:id])
    return redirect_to(hub_path(route_id(current_user.hub))) unless current_user.hub == params[:id] || admin_for_all_hubs?

    assign_start_and_end_dates
    @hub = Hub.new(params[:id], @start_date, @end_date)

    first_month = Rails.cache.fetch("wikimedia_start_month:#{params[:id]}", expires_in: 24.hours) do
      WikimediaCache.where(hub: params[:id], contributor: "").minimum(:month)
    end
    @wikimedia_start_date = Date.parse("#{first_month}-01") if first_month

    # Pre-load S3-cached counts so the totals card renders on initial page load.
    @item_count        = Hub.item_count(params[:id])
    @contributor_count = Hub.contributor_count(params[:id])
    @target            = @hub
  end

  ##
  # Single async endpoint that loads all four data sections for the hub show page
  # concurrently, returning one combined HTML response instead of four.
  #
  def sections
    assign_start_and_end_dates

    hub_id              = params[:hub_id]
    all_start, all_end  = min_date, max_date
    sec_start, sec_end  = section_date_range
    end_date            = @end_date

    first_month = Rails.cache.fetch("wikimedia_start_month:#{hub_id}", expires_in: 24.hours) do
      WikimediaCache.where(hub: hub_id, contributor: "").minimum(:month)
    end
    @wikimedia_start_date = Date.parse("#{first_month}-01") if first_month

    @item_count        = Hub.item_count(hub_id)
    @contributor_count = Hub.contributors(hub_id).size
    website_views_t = Thread.new do
      WebsiteOverview.build { |b|
        b.hub = hub_id; b.start_date = all_start; b.end_date = all_end
      }.events
    rescue => e
      Rails.logger.error(e); nil
    end
    wiki_views_t = Thread.new do
      WikimediaAnalyticsPresenter.new(
        start_month: all_start.strftime("%Y-%m"), end_month: all_end.strftime("%Y-%m")
      ).hub(hub_id)["Page views"]
    rescue => e
      Rails.logger.error(e); nil
    end
    website_overview_t = Thread.new do
      overview = WebsiteOverview.build { |b|
        b.hub = hub_id; b.start_date = sec_start; b.end_date = sec_end
      }
      overview.response
      overview
    rescue => e
      Rails.logger.error(e); nil
    end
    website_events_t = Thread.new do
      totals = WebsiteEventTotals.build { |b|
        b.hub = hub_id; b.start_date = sec_start; b.end_date = sec_end
      }
      totals.response
      totals
    rescue => e
      Rails.logger.error(e); nil
    end
    mc_thread = Thread.new do
      mc = MetadataCompleteness.build { |b| b.hub = hub_id; b.end_date = end_date }
      {
        wp: WikimediaPreparationsPresenter.new(mc).hub(hub_id),
        wa: WikimediaAnalyticsPresenter.new(
              start_month: sec_start.strftime("%Y-%m"),
              end_month: sec_end.strftime("%Y-%m")
            ).hub(hub_id),
        mc: MetadataCompletenessPresenter.new(mc).hub(hub_id)
      }
    rescue => e
      Rails.logger.error(e); {}
    end
    participant_t = Thread.new do
      WikimediaParticipant.hub_participant?(hub_id)
    rescue => e
      Rails.logger.error(e); false
    end

    [website_views_t, wiki_views_t,
     website_overview_t, website_events_t, mc_thread, participant_t].each(&:join)

    mc_data = mc_thread.value || {}

    @website_views        = website_views_t.value
    @wikimedia_views      = wiki_views_t.value
    @website_overview     = website_overview_t.value
    @website_event_totals = website_events_t.value
    @wp_data              = mc_data[:wp]
    @wa_data              = mc_data[:wa]
    @mc_data              = mc_data[:mc]
    @wikimedia_participant = participant_t.value
    @target               = Hub.new(hub_id, sec_start, sec_end)

    render partial: "shared/hub_sections"
  end

  def website_overview
    params[:start_date].present? ? assign_start_and_end_dates : assign_all_time_dates

    @website_overview = WebsiteOverview.build do |builder|
      builder.hub        = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date   = @end_date
    end

    @website_event_totals = WebsiteEventTotals.build do |builder|
      builder.hub        = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date   = @end_date
    end

    render partial: "shared/frontend_use_metrics"
  end

  def api_overview
    assign_start_and_end_dates

    @api_overview = ApiOverview.build do |builder|
      builder.hub = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    render partial: "shared/api_use_metrics"
  end

  def bws_overview
    assign_start_and_end_dates

    @bws_item_count = Hub.bws_item_count(params[:hub_id])

    @bws_overview = BwsOverview.build do |builder|
      builder.hub = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    @bws_event_totals = BwsEventTotals.build do |builder|
      builder.hub = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    render partial: "shared/bws_use_metrics"
  end

  def item_count
    @item_count = Hub.item_count(params[:hub_id])
    render partial: "shared/item_count"
  end

  def totals
    @item_count        = Hub.item_count(params[:hub_id])
    @contributor_count = Hub.contributors(params[:hub_id]).size

    results = [
      Thread.new {
        begin
          WebsiteOverview.build do |b|
            b.hub        = params[:hub_id]
            b.start_date = min_date
            b.end_date   = max_date
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
          ).hub(params[:hub_id])["Page views"]
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

  def metadata_completeness
    assign_start_and_end_dates

    metadata_completeness = MetadataCompleteness.build do |builder|
      builder.hub = params[:hub_id]
      builder.end_date = @end_date
    end

    mc_presenter = MetadataCompletenessPresenter.new(metadata_completeness)
    @mc_data = mc_presenter.hub(params[:hub_id])

    render partial: "shared/metadata_completeness"
  end

  def wikimedia_overview
    params[:start_date].present? ? assign_start_and_end_dates : assign_all_time_dates

    metadata_completeness = MetadataCompleteness.build do |builder|
      builder.hub      = params[:hub_id]
      builder.end_date = @end_date
    end

    wp_presenter = WikimediaPreparationsPresenter.new(metadata_completeness)
    @wp_data = wp_presenter.hub(params[:hub_id])

    wa_presenter = WikimediaAnalyticsPresenter.new(
      start_month: @start_date.strftime("%Y-%m"),
      end_month:   @end_date.strftime("%Y-%m")
    )
    @wa_data = wa_presenter.hub(params[:hub_id])

    @item_count            = Hub.item_count(params[:hub_id])
    @wikimedia_participant = WikimediaParticipant.hub_participant?(params[:hub_id])
    @target                = Hub.new(params[:hub_id], @start_date, @end_date)

    render partial: "shared/wikimedia_overview"
  end

  private

  def authorize_hub_scope!
    render_not_found unless Hub.exists?(params[:hub_id])
  end
end

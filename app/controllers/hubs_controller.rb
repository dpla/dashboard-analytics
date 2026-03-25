# Handles HTTP requests for hubs

class HubsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper
  include MetadataCompletenessHelper
  include TooltipsHelper

  def index
    assign_start_and_end_dates
    @hubs = Hub.all_with_counts
    redirect_to hub_path(current_user.hub) unless current_user.hub == "All"
  end

  def show
    assign_start_and_end_dates
    @hub = Hub.new(params[:id], @start_date, @end_date)

    first_month = Rails.cache.fetch("wikimedia_start_month:#{params[:id]}", expires_in: 24.hours) do
      WikimediaCache.where(hub: params[:id], contributor: "").minimum(:month)
    end
    @wikimedia_start_date = Date.parse("#{first_month}-01") if first_month

    unless current_user.hub == params[:id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end

  def website_overview
    assign_start_and_end_dates

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

    @bws_item_count = DplaApiResponseBuilder.new()
      .bws_item_count(params[:hub_id])
    
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
    @item_count = DplaApiResponseBuilder.new().item_count(params[:hub_id])
    render partial: "shared/item_count"
  end

  def totals
    api = DplaApiResponseBuilder.new
    results = [
      Thread.new {
        begin
          api.item_count(params[:hub_id])
        rescue => e
          Rails.logger.error(e)
          nil
        end
      },
      Thread.new {
        begin
          api.contributors(params[:hub_id]).count
        rescue => e
          Rails.logger.error(e)
          nil
        end
      },
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

    @item_count        = results[0]
    @contributor_count = results[1]
    @website_views     = results[2]
    @wikimedia_views   = results[3]

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
    assign_start_and_end_dates

    # Fetch item_count concurrently while building Wikimedia data.
    item_count_thread = Thread.new do
      DplaApiResponseBuilder.new.item_count(params[:hub_id])
    rescue => e
      Rails.logger.error(e)
      nil
    end

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

    @item_count = item_count_thread.value
    @target     = Hub.new(params[:hub_id], @start_date, @end_date)

    render partial: "shared/wikimedia_overview"
  end
end

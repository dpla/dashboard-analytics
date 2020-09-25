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

  def contributor_website_overview
    assign_start_and_end_dates

    @website_overview = WebsiteOverview.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:contributor_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    @website_event_totals = WebsiteEventTotals.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:contributor_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
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
    assign_start_and_end_dates

    metadata_completeness = MetadataCompleteness.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:contributor_id]
      builder.end_date = @end_date
    end

    wp_presenter = WikimediaPreparationsPresenter.new(metadata_completeness)
    @wp_data = wp_presenter.contributor(params[:hub_id], params[:contributor_id])

    @target = Contributor.new(params[:contributor_id],
                              params[:hub_id],
                              @start_date,
                              @end_date)

    render partial: "shared/wikimedia_overview"
  end

  def contributor_comparison
    assign_start_and_end_dates
    
    contributors_item_count = DplaApiResponseBuilder.new
      .contributors_item_count(params[:hub_id])

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

    api_overview = ApiOverviewByContributor.build do |builder|
      builder.hub = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    metadata_completeness = MetadataCompleteness.build do |builder|
      builder.hub = params[:hub_id]
      builder.end_date = @end_date
    end

    mc_presenter = MetadataCompletenessPresenter.new(metadata_completeness)
    wp_presenter = WikimediaPreparationsPresenter.new(metadata_completeness)

    @contributor_comparison = ContributorComparison.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributors_item_count = contributors_item_count
      builder.website_overview = website_overview
      builder.website_events = website_events
      builder.api_overview = api_overview
      builder.mc_presenter = mc_presenter
      builder.wp_presenter = wp_presenter
    end

    respond_to do |format|
      format.html { render partial: "shared/contributor_comparison" }
      format.csv { send_data @contributor_comparison.to_csv }
    end
  end
end

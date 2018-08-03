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

    contributors = @hub.contributors

    @website_overview = WebsiteOverviewByContributor.build do |builder|
      builder.hub = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    @website_events = WebsiteEventsByContributor.build do |builder|
      builder.hub = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    @api_overview = ApiOverviewByContributor.build do |builder|
      builder.hub = params[:hub_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    metadata_completeness = MetadataCompleteness.build do |builder|
      builder.hub = params[:hub_id]
      builder.end_date = @end_date
    end

    @mc_presenter = MetadataCompletenessPresenter.new(metadata_completeness)

    @contributor_comparison = ContributorComparison.build do |builder|
      builder.hub = @hub.name
      builder.contributors = contributors
      builder.website_overview = @website_overview
      builder.website_events = @website_events
      builder.api_overview = @api_overview
      builder.mc_presenter = @mc_presenter
    end

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_contributors_path(current_user.hub)
    end

    respond_to do |format|
      format.html
      format.csv { send_data @contributor_comparison.to_csv }
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

  def contributors_website_overview
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

  def contributors_api_overview
    assign_start_and_end_dates

    @api_overview = ApiOverview.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:contributor_id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    render partial: "shared/api_use_metrics"
  end

  def contributors_item_count
    @item_count = DplaApiResponseBuilder.new()
      .item_count(params[:hub_id], params[:contributor_id])

    render partial: "shared/item_count"
  end

  def contributors_metadata_completeness
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
end

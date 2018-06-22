# Handles HTTP requests for contributors

class ContributorsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper
  include MetadataCompletenessHelper

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

    @metadata_completeness = MetadataCompleteness.new(@hub)

    @contributor_comparison = ContributorComparison.build do |builder|
      builder.contributors = contributors
      builder.website_overview = @website_overview
      builder.website_events = @website_events
      builder.api_overview = @api_overview
      builder.metadata_completeness = @metadata_completeness
    end

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_contributors_path(current_user.hub)
    end

    respond_to do |format|
      format.html
      format.csv { send_data @hub.contributor_comparison.to_csv }
    end
  end

  def show
    assign_start_and_end_dates
    @contributor = Contributor.new(params[:id],
                                   params[:hub_id],
                                   @start_date,
                                   @end_date)

    @website_overview = WebsiteOverview.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    @website_event_totals = WebsiteEventTotals.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    @api_overview = ApiOverview.build do |builder|
      builder.hub = params[:hub_id]
      builder.contributor = params[:id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end
end

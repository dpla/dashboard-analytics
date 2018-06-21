# Handles HTTP requests for hubs

class HubsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper
  include EventsHelper
  include MetadataCompletenessHelper

  def index
    assign_start_and_end_dates
    @hubs = Hub.all
    redirect_to hub_path(current_user.hub) unless current_user.hub == "All"
  end

  def show
    assign_start_and_end_dates
    @hub = Hub.new(params[:id], @start_date, @end_date)

    @website_overview = WebsiteOverview.build do |builder|
      builder.hub = params[:id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    @website_event_totals = WebsiteEventTotals.build do |builder|
      builder.hub = params[:id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    @api_overview = ApiOverview.build do |builder|
      builder.hub = params[:id]
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    unless current_user.hub == params[:id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end
end

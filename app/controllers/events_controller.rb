# Handles HTTP requests for events

class EventsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper
  include PaginationHelper

  def show
    assign_start_and_end_dates
    @hub = Hub.new(params[:hub_id], @start_date, @end_date)

    if params[:contributor_id]
      @contributor = Contributor.new(params[:contributor_id], params[:hub_id],
                                     @start_date, @end_date)
    end

    @target = params[:contributor_id] ? @contributor : @hub

    unless current_user.hub == params[:hub_id] || admin_for_all_hubs?
      redirect_to hub_path(route_id(current_user.hub))
    end
  end

  def website_event_names
    WebsiteEvents::NAMES_BY_ID
  end

  def api_events
    assign_start_and_end_dates

    events = ApiEvents.build do |builder|
        builder.hub = params[:hub_id]
        builder.contributor = params[:contributor_id] #may be nil
        builder.start_date = @start_date
        builder.end_date = @end_date
      end

    @events = ApiEventsPresenter.new(events)

    respond_to do |format|
      format.html { render partial: "shared/events_table" }
      format.csv { send_data @events.to_csv }
    end
  end

  def website_events
    assign_start_and_end_dates

    events = WebsiteEvents.build do |builder|
        builder.hub = params[:hub_id]
        builder.contributor = params[:contributor_id] #may be nil
        builder.start_date = @start_date
        builder.end_date = @end_date
        builder.event_name = website_event_names[params[:event_id]]
        builder.page = current_page
      end

    @events = WebsiteEventsPresenter.new(events)

    respond_to do |format|
      format.html { render partial: "shared/events_table" }
      format.csv { send_data @events.to_csv }
    end
  end
end

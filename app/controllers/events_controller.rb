# Handles HTTP requests for events

class EventsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper

  def show
    assign_start_and_end_dates
    @hub = Hub.new(params[:hub_id], @start_date, @end_date)

    if params[:contributor_id]
      @contributor = Contributor.new(params[:contributor_id], params[:hub_id],
                                     @start_date, @end_date)
    end

    @target = params[:contributor_id] ? @contributor : @hub

    # File extension may be included in params[:id], e.g. "view_item.csv"
    @label = params[:id].split(".").first

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end

  def website_event_names
    { "view_item" => "View Item",
      "view_exhibit" => "View Exhibition Item",
      "view_pss" => "View Primary Source",
      "click_through" => "Click Through" }
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
      format.html { render partial: "shared/events_table.html.erb" }
      format.csv { send_data @events.to_csv }
    end
  end

  def website_events
    assign_start_and_end_dates

    # File extension may be included in params[:id], e.g. "view_item.csv"
    label = params[:event_id].split(".").first

    events = WebsiteEvents.build do |builder|
        builder.hub = params[:hub_id]
        builder.contributor = params[:contributor_id] #may be nil
        builder.start_date = @start_date
        builder.end_date = @end_date
        builder.event_name = website_event_names[label]
      end

    @events = WebsiteEventsPresenter.new(events)

    respond_to do |format|
      format.html { render partial: "shared/events_table.html.erb" }
      format.csv { send_data @events.to_csv }
    end
  end
end

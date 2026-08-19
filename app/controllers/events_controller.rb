# Handles HTTP requests for events

class EventsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include CsvFilenameHelper
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
      format.csv { send_data @events.to_csv, filename: events_csv_filename }
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
      format.csv { send_data @events.to_csv, filename: events_csv_filename }
    end
  end

  private

  def events_csv_filename
    csv_filename(params[:hub_id], params[:contributor_id],
                 @events.label, csv_date_range)
  end

  # Event tables have no rows before event_label (see DataWindow).
  # Also floors api_events, harmless while ApiEvents#response is stubbed nil;
  # revisit if API event tracking returns.
  def min_date
    DataWindow.events_min_date
  end

  # No dates in the URL: show the full window, not one month.
  def default_start_date
    min_date
  end
end

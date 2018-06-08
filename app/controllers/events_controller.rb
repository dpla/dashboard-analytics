# Handles HTTP requests for events

class EventsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper
  include EventsHelper

  def show
    assign_start_and_end_dates
    @hub = Hub.new(params[:hub_id], @start_date, @end_date)

    if params[:contributor_id]
      @contributor = Contributor.new(params[:contributor_id], params[:hub_id],
                                     @start_date, @end_date)
    end

    @target = params[:contributor_id] ? @contributor : @hub
    @events = Events.new(@target, params[:id])

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end

    respond_to do |format|
      format.html
      format.csv { send_data @events.to_csv }
    end
  end
end

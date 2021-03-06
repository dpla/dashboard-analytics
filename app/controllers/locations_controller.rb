# Handles HTTP requests for locations

class LocationsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper

  def index
    assign_start_and_end_dates
    @hub = Hub.new(params[:hub_id], @start_date, @end_date)

    if params[:contributor_id]
      @contributor = Contributor.new(params[:contributor_id], params[:hub_id],
                                     @start_date, @end_date)
    end

    @target = params[:contributor_id] ? @contributor : @hub

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end
end

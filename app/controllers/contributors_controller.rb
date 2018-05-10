# Handles HTTP requests for contributors

class ContributorsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper
  include EventsHelper

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
end

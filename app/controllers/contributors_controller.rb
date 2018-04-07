# Handles HTTP requests for contributors

class ContributorsController < ApplicationController

  def index
    @start_date = "30daysAgo"
    @end_date = "yesterday"
    @hub = Hub.new(params[:hub_id], @start_date, @end_date)
    @contributors = @hub.contributors

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_contributors_path(current_user.hub)
    end
  end

  def show
    @start_date = "30daysAgo"
    @end_date = "yesterday"
    @contributor = Contributor.new(params[:id],
                                   params[:hub_id],
                                   @start_date,
                                   @end_date)

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end
end

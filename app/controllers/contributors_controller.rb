# Handles HTTP requests for contributors

class ContributorsController < ApplicationController

  def index
    @start_date = "30daysAgo"
    @end_date = "yesterday"
    @hub = Hub.new(params[:hub_id], @start_date, @end_date)

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_contributors_path(current_user.hub)
    end
  end

  def show
    @start_date = params[:start_date] ? params[:start_date] : 
      Date.today.last_month.beginning_of_month.iso8601
      
    @end_date = params[:end_date] ? params[:end_date] :
      Date.today.last_month.end_of_month.iso8601

    @contributor = Contributor.new(params[:id],
                                   params[:hub_id],
                                   @start_date,
                                   @end_date)

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end
end

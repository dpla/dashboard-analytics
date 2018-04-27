# Handles HTTP requests for contributors

class ContributorsController < ApplicationController
  include DateSetter
  include DateMenuHelper

  def index
    @start_date = "30daysAgo"
    @end_date = "yesterday"
    @hub = Hub.new(params[:hub_id], @start_date, @end_date)

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_contributors_path(current_user.hub)
    end
  end

  def show
    year = params[:date].split("-").first rescue nil
    month = params[:date].split("-").last rescue nil
    @start_date = get_start_date(year, month)
    @end_date = get_end_date(@start_date)
    @contributor = Contributor.new(params[:id],
                                   params[:hub_id],
                                   @start_date,
                                   @end_date)

    unless current_user.hub == params[:hub_id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end
end

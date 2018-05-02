# Handles HTTP requests for hubs

class HubsController < ApplicationController
  include DateSetter
  include DateHelper

  def index
    @hubs = Hub.all
    redirect_to hub_path(current_user.hub) unless current_user.hub == "All"
  end

  def show
    year = params[:date].split("-").first rescue nil
    month = params[:date].split("-").last rescue nil
    @start_date = get_start_date(year, month)
    @end_date = get_end_date(@start_date)
    @hub = Hub.new(params[:id], @start_date, @end_date)

    unless current_user.hub == params[:id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end
end

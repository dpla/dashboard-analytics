# Handles HTTP requests for hubs

class HubsController < ApplicationController
  def index
    @hubs = Hub.all
    redirect_to hub_path(current_user.hub) unless current_user.hub == "All"
  end

  def show
    @start_date = Date.today.last_month.beginning_of_month.iso8601
    @end_date = Date.today.last_month.end_of_month.iso8601
    @hub = Hub.new(params[:id], @start_date, @end_date)

    unless current_user.hub == params[:id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end
end

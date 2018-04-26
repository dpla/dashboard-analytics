# Handles HTTP requests for hubs

class HubsController < ApplicationController
  include DateSetter

  def index
    @hubs = Hub.all
    redirect_to hub_path(current_user.hub) unless current_user.hub == "All"
  end

  def show
    @start_date = start_date(params).iso8601
    @end_date = end_date(params).iso8601
    @hub = Hub.new(params[:id], @start_date, @end_date)

    unless current_user.hub == params[:id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end
end

# Handles HTTP requests for hubs

class HubsController < ApplicationController
  include DateSetter # Controller concern
  include DateHelper # View helper

  def index
    @hubs = Hub.all
    redirect_to hub_path(current_user.hub) unless current_user.hub == "All"
  end

  def show
    assign_start_and_end_dates
    @hub = Hub.new(params[:id], @start_date, @end_date)

    unless current_user.hub == params[:id] || current_user.hub == "All"
      redirect_to hub_path(current_user.hub)
    end
  end
end

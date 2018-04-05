# Handles HTTP requests for hubs

class HubsController < ApplicationController
  def index
    @hubs = Hub.all
  end

  def show
    @start_date = "30daysAgo"
    @end_date = "yesterday"
    @hub = Hub.new(params[:id], @start_date, @end_date)
  end
end

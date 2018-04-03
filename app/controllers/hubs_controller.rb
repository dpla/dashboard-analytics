# Handles HTTP requests for hubs

class HubsController < ApplicationController
  def index
  end

  def show
    @hub = params[:id]
    @start_date = "30daysAgo"
    @end_date = "yesterday"
    @ga = GaResponseBuilder.new(@hub, @start_date, @end_date)
  end
end

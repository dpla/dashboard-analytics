# Handles HTTP requests for hubs

class HubsController < ApplicationController
  def index
  end

  def show
    @hub = params[:id]
    @ga = GaResponseBuilder.new(@hub)
  end
end

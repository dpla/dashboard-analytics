# Handles HTTP requests for contributors

class ContributorsController < ApplicationController

  def show
    @start_date = "30daysAgo"
    @end_date = "yesterday"
    @contributor = Contributor.new(params[:id],
                                   params[:hub_id],
                                   @start_date,
                                   @end_date)
  end
end

# Handles HTTP requests for events

class SearchTermsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper

  def show
    assign_start_and_end_dates
    @search_terms= SearchTerms.new(params[:id], @start_date, @end_date)
  end
end

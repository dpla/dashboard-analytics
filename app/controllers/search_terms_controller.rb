# Handles HTTP requests for search terms

class SearchTermsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper

  def show
    assign_start_and_end_dates
    @search_terms= SearchTerms.new(params[:id], @start_date, @end_date)

    respond_to do |format|
      format.html
      format.csv { send_data @search_terms.to_csv }
    end
  end
end

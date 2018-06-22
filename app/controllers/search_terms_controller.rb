# Handles HTTP requests for search terms

class SearchTermsController < ApplicationController
  # Controller concerns
  include DateSetter
  # View helpers
  include DataMenuHelper
  include DateHelper
  include SearchTermsHelper

  def show
    assign_start_and_end_dates
    @search_terms = get_search_terms

    respond_to do |format|
      format.html
      format.csv { send_data @search_terms.to_csv }
    end
  end

  def get_search_terms
    if params[:id] == "website"
      WebsiteSearchTerms.build do |builder|
        builder.start_date = @start_date
        builder.end_date = @end_date
      end
    elsif params[:id] == "api"
      ApiSearchTerms.build do |builder|
        builder.start_date = @start_date
        builder.end_date = @end_date
      end
    end 
  end
end

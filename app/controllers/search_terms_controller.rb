# Handles HTTP requests for search terms

class SearchTermsController < ApplicationController
  # Controller concerns
  include DateSetter
  # Site-wide floor: no hub or contributor params.
  include GaDataFloor
  # View helpers
  include CsvFilenameHelper
  include DataMenuHelper
  include DateHelper
  include SearchTermsHelper
  include PaginationHelper

  def show
    assign_start_and_end_dates
  end

  def website_search_terms
    assign_start_and_end_dates

    @search_terms = WebsiteSearchTerms.build do |builder|
      builder.start_date = @start_date
      builder.end_date = @end_date
      builder.page = current_page
    end

    respond_to do |format|
      format.html { render partial: "shared/search_terms_table", locals: { scope: "website" } }
      format.csv do
        send_data @search_terms.to_csv,
                  filename: csv_filename("DPLA website search terms", csv_date_range)
      end
    end
  end

  def api_search_terms
    assign_start_and_end_dates

    @search_terms = ApiSearchTerms.build do |builder|
      builder.start_date = @start_date
      builder.end_date = @end_date
    end

    respond_to do |format|
      format.html { render partial: "shared/search_terms_table", locals: { scope: "api" } }
      format.csv do
        send_data @search_terms.to_csv,
                  filename: csv_filename("DPLA API search terms", csv_date_range)
      end
    end
  end
end

module SearchTermsHelper

  def scope_label
    params[:id] == "website" ? "Website" : "API"
  end

  ##
  # @param [Google::Apis::AnalyticsV3::GaData]
  # @return Integer
  def end_index(response)
    response.total_results.to_i < response.items_per_page.to_i ? 
      response.total_results : response.items_per_page
  end
end

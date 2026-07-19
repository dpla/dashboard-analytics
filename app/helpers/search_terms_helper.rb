module SearchTermsHelper

  def scope_label
    params[:id] == "website" ? "Website" : "API"
  end
end

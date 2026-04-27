class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  before_action :authenticate_user!
  before_action :normalize_encoded_params
  before_action :redirect_inverted_date_range
  layout :layout_by_resource

  rescue_from Google::Apis::Error, Signet::AuthorizationError, Faraday::Error,
              Timeout::Error, with: :handle_service_error

  private

  ENCODED_PARAM_KEYS = %i[id hub_id contributor_id].freeze

  def normalize_encoded_params
    return unless request.get? || request.head?

    ENCODED_PARAM_KEYS.each do |key|
      params[key] = CGI.unescape(params[key]) if params[key]
    end
  end

  def redirect_inverted_date_range
    return unless request.get? || request.head?
    return if request.xhr?
    return unless params[:start_date] =~ /\A\d{4}-\d{2}\z/ &&
                  params[:end_date]   =~ /\A\d{4}-\d{2}\z/

    begin
      start_d = Date.strptime("#{params[:start_date]}-01", "%Y-%m-%d")
      end_d   = Date.strptime("#{params[:end_date]}-01", "%Y-%m-%d")
    rescue ArgumentError
      return
    end
    return unless end_d < start_d

    swapped_query = request.query_parameters.merge(
      "start_date" => params[:end_date],
      "end_date"   => params[:start_date]
    )
    redirect_to "#{request.path}?#{swapped_query.to_query}",
                flash: { alert: "End date was before start date — dates have been swapped." }
  end

  def render_not_found
    render "errors/not_found", status: :not_found, layout: "application"
  end

  def admin_for_all_hubs?
    current_user.admin && current_user.hub == "All"
  end
  helper_method :admin_for_all_hubs?

  # Encode literal slashes as %2F so the string passes Rails' [^\/]+ route
  # constraint during URL generation. Rails' escape_segment then re-encodes
  # the % to %25, producing %252F in the final URL. normalize_encoded_params
  # runs a second CGI.unescape on inbound params to reverse that extra layer.
  def route_id(name)
    name.to_s.gsub("/", "%2F")
  end
  helper_method :route_id

  def require_admin!
    unless current_user.admin
      flash[:alert] = "You don't have permission to do that."
      redirect_to admin_user_path(current_user)
    end
  end

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end

  def handle_service_error(exception)
    Rails.logger.error(exception.full_message)
    # XHR requests (render_async sections) must return 200 so the response body
    # is inserted into the container instead of being discarded in favour of the
    # hard-coded error_message string.
    if request.xhr?
      render "errors/service_unavailable", status: :ok, layout: false
    else
      render "errors/service_unavailable", status: :service_unavailable, layout: "application"
    end
  end
end

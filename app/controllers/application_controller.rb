class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  before_action :authenticate_user!
  before_action :redirect_inverted_date_range
  layout :layout_by_resource

  rescue_from Google::Apis::Error, Signet::AuthorizationError, Faraday::Error,
              Timeout::Error, with: :handle_service_error

  private

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

    redirect_to params.to_unsafe_h.merge(start_date: params[:end_date], end_date: params[:start_date]),
                flash: { alert: "End date was before start date — dates have been swapped." }
  end

  def render_not_found
    render "errors/not_found", status: :not_found, layout: "application"
  end

  def admin_for_all_hubs?
    current_user.admin && current_user.hub == "All"
  end
  helper_method :admin_for_all_hubs?

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end

  def handle_service_error(exception)
    Rails.logger.error(exception.full_message)
    render "errors/service_unavailable", status: :service_unavailable, layout: "application"
  end
end

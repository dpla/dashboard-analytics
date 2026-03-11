class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  before_action :authenticate_user!
  layout :layout_by_resource

  rescue_from Google::Apis::Error, StandardError, with: :handle_service_error

  private

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end

  def handle_service_error(exception)
    Rails.logger.error("#{exception.class}: #{exception.message}")
    render "errors/service_unavailable", status: :service_unavailable, layout: "application"
  end
end

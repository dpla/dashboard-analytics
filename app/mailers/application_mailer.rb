class ApplicationMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers
  default from: "analytics-dashboard@dp.la"
  layout 'mailer'
end

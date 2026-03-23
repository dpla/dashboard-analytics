class ApplicationMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers
  default from: "info@dp.la"
  layout 'mailer'
end

require_relative 'boot'

# This code runs before rails itself is loaded.

# Regex to unescape JSON loaded from ENV var
re = /\\\"/m
subst = '"'
# Load JSON from GOOGLE_ANALYTICS_KEY ENV var
#   The GOOGLE_ANALYTICS_KEY value is defined in AWS secrets manager
#   and value is read and set as an ENV var for the ECS container by Terraform
#   which is the source of the ENV var being loaded here.
ga_key = ENV["GOOGLE_ANALYTICS_KEY"]
# The JSON needed to be escaped to be read/passed through to ECS container definition 
# This regex unescapes the JSON with the regex
result = ga_key.gsub(re, subst)
# FIXME 
#   This open call will create the file if it doesn't exist and should use the path
#   defined by service_account_json_key key in ./config/settings.yml 
#   Hard coding the path here can result in nil objects and break the app
# Copy the google analtyics JSON to a local JSON file.
File.open("./google-analytics-key.json", "w") {|f| f.write(result) }

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DashboardAnalytics
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.autoload_paths << "#{config.root}/lib)"
    config.eager_load_paths << "#{config.root}/lib)"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end

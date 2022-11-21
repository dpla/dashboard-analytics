require_relative 'boot'

require 'logger'

# Copy the google analtyics key to a local JSON file.
# This code runs before rails itself is loaded.


logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

# Regex to unescape JSON loaded from ENV var
re = /\\\"/m
subst = '"'

# Load JSON from GOOGLE_ANALYTICS_KEY ENV var
# Unescape JSON by applying regex above
# Copy the google analtyics JSON to a local JSON file.
# This code runs before rails itself is loaded.
ga_key = ENV["GOOGLE_ANALYTICS_KEY"]
result = ga_key.gsub(re, subst)
File.open("google-analytics-key.json", "w") {|f| f.write(result) }

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DashboardAnalytics
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    config.autoload_paths += %W(#{config.root}/lib)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end

require_relative 'boot'

# Copy the google analtyics key to a local JSON file.
# This code runs before rails itself is loaded.
File.open("google-analytics-key.json", "w") {|f| f.write(ENV["GOOGLE_ANALYTICS_KEY"].gsub("\\"",""")) }

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

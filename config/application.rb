require_relative 'boot'

# This code runs before rails itself is loaded.

# Production: service account JSON arrives in GOOGLE_ANALYTICS_KEY (Secrets
# Manager via Terraform), escaped for the ECS container definition;
# unescape and write the key file. No env var (local dev, tests): keep any
# existing key file and boot. GA sections degrade instead of the app dying.
ga_key = ENV["GOOGLE_ANALYTICS_KEY"]
if ga_key && !ga_key.empty?
  File.write("./google-analytics-key.json", ga_key.gsub(/\\\"/m, '"'))
elsif ENV["RAILS_ENV"] == "production"
  # Fail the deploy loudly; no pages with dead GA sections.
  raise "GOOGLE_ANALYTICS_KEY is not set"
end

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DashboardAnalytics
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    # Keep 7.0 defaults: upgrading to 7.1 defaults breaks Devise 4.9.0 (trackable
    # strategy error). CVE-2025-55193 is fixed by Rails 7.1.6 itself regardless of
    # which defaults version is set. Revisit when upgrading to Devise 5.x.
    config.load_defaults 7.0
    config.autoload_paths << "#{config.root}/lib"
    config.eager_load_paths << "#{config.root}/lib"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end

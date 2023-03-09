source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0.4'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', '~> 1.6.0'
# Use Puma as the app server
gem 'puma', '~> 6.1', '>= 6.1.1'
# Use SCSS for stylesheets
gem 'sassc-rails', '~> 2.1', '>= 2.1.2'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.2.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11', '>= 2.9.1'
gem 'config', '~> 4.1.0'
gem 'google-apis-analytics_v3', '~> 0.13.0'
gem 'googleauth', '~> 1.3.0'
gem 'httparty', '~> 0.21.0'
gem 'devise', '~> 4.9.0'
gem 'jquery-rails', '~> 4.5.1'
gem 'aws-sdk-rails', '~> 3.7.1'
gem 'aws-sdk-core', '~> 3.170'
gem 'aws-sdk-s3', '~> 1.119'
gem 'render_async', '~> 2.1.11'
# Set versions of following gems to fix security vulnerabilities
gem 'rails-html-sanitizer', '>= 1.4.4'
gem 'sprockets', '~> 3.7.2'
gem 'rubyzip', '>= 1.3.0'
gem 'ffi', '>= 1.9.24'
gem 'nokogiri', '>= 1.13.10'
gem 'railties', '>= 5.2.7.1'
gem 'loofah', '>= 2.19.1'
gem 'rack', '>= 2.2.6.2'
gem 'globalid', '>= 1.0.1'

group :production do
  gem 'pg', '~> 1.4.5'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.38'
  gem 'selenium-webdriver', '>= 3.142.3'
  gem 'rspec-core', '~> 3.10'
  gem 'rspec-rails', '~> 6.0.1'
  gem 'awesome_print', '~> 1.9.0'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '~> 4.2.0'
  gem 'listen', '~> 3.8.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 4.1'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

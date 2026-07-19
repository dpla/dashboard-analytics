source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.2.0', '>= 7.2.3.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', '~> 2.9.5'
# Use Puma as the app server
gem 'puma', '~> 8.0'
# Use SCSS for stylesheets
gem 'sassc-rails', '~> 2.1', '>= 2.1.2'
gem 'turbo-rails', '~> 2.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.15'
gem 'config', '~> 5.6.1'
gem 'google-apis-analyticsdata_v1beta', '~> 0.41'
gem 'googleauth', '~> 1.17.1'
gem 'devise', '~> 5.0'
gem 'httparty', '>= 0.24.0'
gem 'jquery-rails', '~> 4.6.1'
gem 'aws-sdk-rails', '~> 5.1.0'
gem 'aws-sdk-core', '~> 3.254'
gem 'aws-sdk-s3', '~> 1.228'
gem 'render_async', '~> 2.1.11'
gem 'coffee-rails', '~> 5.0'
# Set versions of following gems to fix security vulnerabilities
gem 'rails-html-sanitizer', '>= 1.4.4'
gem 'sprockets', '~> 4.2.2'
gem 'rubyzip', '>= 1.3.0'
gem 'ffi', '>= 1.9.24'
gem 'nokogiri', '>= 1.18.9', '< 1.20'  # 1.19+ requires Ruby >= 3.2; app runs 3.1.2
gem 'loofah', '>= 2.19.1'
gem 'rack', '>= 2.2.23'
gem 'globalid', '>= 1.0.1'
gem 'rexml', '>= 3.3.9'
gem 'webrick', '>= 1.8.2'
gem 'net-imap', '>= 0.3.9'
gem 'faraday', '>= 2.14.1'
gem 'bcrypt', '~> 3.1', '>= 3.1.22'
gem 'json', '~> 2.21'
gem 'sentry-ruby', '~> 6.6'
gem 'sentry-rails', '~> 6.6'

group :production do
  gem 'pg', '~> 1.6.3'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.40'
  gem 'selenium-webdriver', '>= 3.142.3'
  gem 'rspec-core', '~> 3.13'
  gem 'rspec-rails', '~> 8.0.4'
  gem 'awesome_print', '~> 1.9.0'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '~> 4.2.1'
  gem 'listen', '~> 3.10.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 4.7'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.7', '>= 5.2.7.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', '~> 1.3.13'
# Use Puma as the app server
gem 'puma', '~> 4.3', '>= 4.3.12'
# Use SCSS for stylesheets
gem 'sassc-rails', '~> 2.1', '>= 2.1.2'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.9', '>= 2.9.1'
gem 'config', '1.7.0'
gem 'google-apis-analytics_v3', '~> 0.7.0'
gem 'googleauth', '~> 0.9', '>= 0.9.0'
gem 'httparty', '~> 0.21.0'
gem 'devise', '~> 4.8.1'
gem 'jquery-rails', '~> 4.5.0'
gem 'aws-sdk-rails', '~> 2', '>= 2.1.0'
gem 'aws-sdk-core', '~> 3.46'
gem 'aws-sdk-s3', '~> 1.30'
gem 'render_async', '~> 1.2.0'
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
  gem 'pg', '~> 1.0.0'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.18', '>= 2.18.0'
  gem 'selenium-webdriver', '>= 3.142.3'
  gem 'rspec-core', '~> 3.10'
  gem 'rspec-rails', '~> 5.1.2', '>= 5.0.3'
  gem 'awesome_print', '1.8.0'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.7.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

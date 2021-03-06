# DPLA Analytics Dashboard

## Prerequisites

    ruby v2.4.1
    rails v5.1.5

## Installation and setup

Initial installation:

    bundle install
    bundle exec rake db:migrate
    bundle exec rails s

Subsequent development:
* Run `bundle update` as necessary

Configuration:

Copy `config/settings.yml.example` to `config/settings.yml` and set appropriate values.
Copy `config/database.yml.example` to `config/database.yml` and set appropriate values.

Get a service account key from Google Analytics.  See `config/google-analytics-key.json.example` for more information.

Inital user:

Create an initial user account from the rails console:

    User.create(email: "user@example.com", admin: true, hub: "All", password: "password")

## Testing

To run rspec tests in your console:

    bundle exec rspec

## Copyright & License

* Copyright Digital Public Library of America, 2018
* License: MIT

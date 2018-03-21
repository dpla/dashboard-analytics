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

## Testing

To run rspec tests in your console:

    bundle exec rspec

## Copyright & License

* Copyright Digital Public Library of America, 2018
* License: MIT

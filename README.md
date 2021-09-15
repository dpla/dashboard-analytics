# DPLA Analytics Dashboard

## Prerequisites

    ruby v2.6.5
    rails v5.1.7

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

## Using Docker

Copy `docker-compose.yml.example` to `docker-compose.yml` and set appropriate values.

To start the application:

    docker-compose build
    docker-compose up

If the database has not yet been created, run:

    docker-compose run web bundle exec rake db:create

If any database migrations need to be executed, run:

    docker-compose run web bundle exec rake db:migrate

To shut down:

    docker-compose down

### Testing

Before testing with Docker, run `docker compose up`.

To create the test database:

    docker-compose run -e "RAILS_ENV=test" web bundle exec rake db:create

To run migrations on the test database:

    docker-compose run -e "RAILS_ENV=test" web bundle exec rake db:migrate

To execute the tests:

    docker-compose run -e "RAILS_ENV=test" web bundle exec rspec

## Copyright & License

* Copyright Digital Public Library of America, 2018
* License: MIT

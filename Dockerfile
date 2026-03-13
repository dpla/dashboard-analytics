FROM ruby:3.1.2

ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true

RUN apt-get update && apt-get install nodejs -y
RUN bundle config --global frozen 1
WORKDIR /opt/dashboard-analytics
COPY Gemfile Gemfile.lock ./
RUN bundle install --deployment
COPY . .
# Devise checks for the presence of SECRET_KEY_BASE during precompile, but the
# environmental vars set in docker-compose are not available in RUN context.
# RUN SECRET_KEY_BASE=decoy-token bundle exec rake assets:precompile
EXPOSE 3000
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0", "-p", "3000"]

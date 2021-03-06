FROM ruby:2.4.1

ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true

RUN apt-get update && apt-get install nodejs -y
RUN bundle config --global frozen 1
WORKDIR /opt/dashboard-analytics
COPY Gemfile Gemfile.lock ./
RUN bundle install --deployment
COPY . .
RUN bundle exec rake assets:precompile
EXPOSE 3000
CMD ["rails", "s"]
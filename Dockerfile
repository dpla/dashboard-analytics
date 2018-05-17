FROM ruby:2.5
RUN apt-get update && apt-get install nodejs -y
RUN bundle config --global frozen 1
WORKDIR /opt/dashboard-analytics
COPY Gemfile Gemfile.lock ./
RUN bundle install --deployment
COPY . .
EXPOSE 3000
CMD ["rails", "s"]
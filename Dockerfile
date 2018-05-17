FROM ruby:2.5
RUN bundle install --deployment
EXPOSE 3000
CMD ["rails", "s"]
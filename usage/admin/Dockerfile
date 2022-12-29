FROM ruby:2.6.3
RUN apt-get update -qq && apt-get install -y nodejs default-libmysqlclient-dev yarn
RUN mkdir /myapp
WORKDIR /myapp
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock
RUN bundle install
# Start the main process.
CMD ["rails", "server", "-b", "0.0.0.0"]

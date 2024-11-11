FROM ruby:3.1.4

RUN apt-get update -qq && apt-get install -y nodejs libsodium-dev

WORKDIR /app

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install

COPY . /app
EXPOSE 3000
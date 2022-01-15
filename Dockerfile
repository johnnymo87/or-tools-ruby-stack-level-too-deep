# Base image
FROM ruby:3.1-bullseye AS base

WORKDIR /app

COPY Gemfile Gemfile.lock .

RUN gem install bundler && \
  bundle config set without 'development test' && \
  bundle install

# Release image
FROM base AS release

COPY . .

CMD irb -Ilib

# Test image
FROM base AS test

ENV TESTOPTS=--pride

RUN bundle config --delete without && \
  bundle install

CMD rake test

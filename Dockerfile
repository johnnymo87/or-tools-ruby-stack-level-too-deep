# Base image
FROM ruby:3.1-bullseye AS base

ARG TARGETPLATFORM
# There's no pre-compiled arm64 or-tools binaries available, so we build them from source.
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
    apt update && \
    apt install -y \
    cmake \
    ninja-build \
    git && \
    git clone -b v9.2 --depth 1 https://github.com/google/or-tools.git /usr/local/src/or-tools && \
    cd /usr/local/src/or-tools && \
    cmake -S. -Bbuild -GNinja -DBUILD_DEPS=ON && \
    cd build && \
    ninja install && \
    bundle config build.or-tools --with-or-tools-dir=/usr/local/include/ortools; \
  fi

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN gem update --system && \
  bundle config set without 'development test' && \
  bundle

# Release image
FROM base AS release

COPY . .

# Dev image
FROM release AS dev

RUN bundle config --delete without && \
  bundle

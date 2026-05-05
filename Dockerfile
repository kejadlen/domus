FROM ruby:3.3-slim AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

FROM base AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without "development test" \
    && bundle install

COPY . .

FROM base

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app .

EXPOSE 9292

CMD ["bundle", "exec", "puma", "-p", "9292"]

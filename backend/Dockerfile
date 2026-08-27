# syntax = docker/dockerfile:1

# Use Ruby 3.3.7
ARG RUBY_VERSION=3.3.7
FROM ruby:$RUBY_VERSION-slim

# Rails app lives here
WORKDIR /rails

# Install base packages
# libyaml-dev and pkg-config are required to build psych, a transitive
# dependency of the debug gem; the slim image does not ship them.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential ca-certificates default-mysql-client default-libmysqlclient-dev git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./

# Gems install into the image default (/usr/local/bundle), which docker-compose
# backs with the `backend_gems` volume. Installing into ./vendor/bundle instead
# put them under the `./backend:/rails` bind mount, where the host directory
# shadowed them on every run.
RUN bundle config set --local deployment 'false' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Entrypoint prepares the database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
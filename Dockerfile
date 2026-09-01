FROM ruby:3.1.6

ENV BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    git \
    curl \
    ca-certificates \
    gnupg \
  && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && npm install -g yarn@1.22.22 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile .

RUN bundle install

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]
CMD ["bash"]
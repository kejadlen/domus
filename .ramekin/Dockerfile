FROM ramekin-agent

# Ruby's build dependencies. ruby-install would normally install these via
# apt itself, but we delete the apt index below, so install them here and pass
# --no-install-deps to ruby-install.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    bison \
    xz-utils \
    libyaml-dev \
    libgdbm-dev \
    libreadline-dev \
    libncurses-dev \
    libssl-dev \
    zlib1g-dev \
    libffi-dev \
    libsqlite3-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install ruby-install
RUN curl -L -o ruby-install-0.10.1.tar.gz https://github.com/postmodern/ruby-install/archive/v0.10.1.tar.gz \
    && tar xzf ruby-install-0.10.1.tar.gz \
    && cd ruby-install-0.10.1 \
    && make install \
    && cd / \
    && rm -rf ruby-install-0.10.1 ruby-install-0.10.1.tar.gz

# Install Ruby 4.0.5
RUN ruby-install --cleanup --no-install-deps ruby 4.0.5

ENV PATH="/opt/rubies/ruby-4.0.5/bin:${PATH}"
ENV GEM_HOME="/usr/local/bundle"
ENV GEM_PATH="/usr/local/bundle"
ENV PATH="${GEM_HOME}/bin:${PATH}"

RUN gem install bundler --no-document

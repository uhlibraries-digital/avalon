FROM ruby:2.7-bullseye

RUN curl -fsSL https://deb.nodesource.com/setup_12.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -q && apt-get install -y \
  build-essential \
  imagemagick \
  ffmpeg \
  mediainfo \
  shared-mime-info \
  lsof \
  git \
  nodejs \
  yarn \
  zip

# Setup lsof since Avalon likes to look in /usr/sbin for it
RUN ln -s /usr/bin/lsof /usr/sbin/lsof

ENV APP_PATH=/avalon-app

RUN mkdir /avalon-app
RUN mkdir -p /streams/hls_streams
RUN mkdir -p /var/avalon/uploads
RUN mkdir -p /var/avalon/dropbox
WORKDIR /avalon-app

# Install gems
COPY Gemfile /avalon-app/Gemfile
COPY Gemfile.lock /avalon-app/Gemfile.lock

RUN  gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)" && \
  bundle config build.nokogiri --use-system-libraries
RUN bundle install --with mysql

ENV RAILS_SERVE_STATIC_FILES=true \
  RAILS_LOG_TO_STDOUT=true \
  RAILS_LOG_LEVEL=debug

# Install entrypoint
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ADD . /avalon-app

# Install node modules
RUN  yarn install

# Install example vocabulary
RUN cp /avalon-app/config/controlled_vocabulary.yml.example /avalon-app/config/controlled_vocabulary.yml
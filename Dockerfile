FROM ruby:2.5.5-stretch

RUN echo "deb http://deb.debian.org/debian stretch-backports main" >> /etc/apt/sources.list
RUN curl -fsSL https://deb.nodesource.com/setup_8.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN wget https://mediaarea.net/repo/deb/repo-mediaarea_1.0-19_all.deb && dpkg -i repo-mediaarea_1.0-19_all.deb && apt-get update
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
  zip \
  nano

# Install ffmpeg
RUN mkdir -p /tmp/ffmpeg && cd /tmp/ffmpeg && \
  curl https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz | tar xJ  && \
  cp `find . -type f -executable` /usr/bin/

# Setup lsof since Avalon likes to look in /usr/sbin for it
RUN ln -s /usr/bin/lsof /usr/sbin/lsof

ENV APP_PATH=/avalon-app

RUN mkdir /avalon-app
RUN mkdir -p /streams/hls_streams
RUN mkdir -p /var/avalon/uploads
RUN mkdir -p /var/avalon/dropbox
RUN mkdir -p /var/avalon/working
WORKDIR /avalon-app

# Install gems
COPY Gemfile /avalon-app/Gemfile
COPY Gemfile.lock /avalon-app/Gemfile.lock

RUN  gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)" && \
  bundle config build.nokogiri --use-system-libraries
RUN bundle install --with mysql

ENV RAILS_SERVE_STATIC_FILES=true \
  RAILS_LOG_TO_STDOUT=true

# Install entrypoint
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ADD . /avalon-app

RUN  yarn install
RUN cp /avalon-app/config/controlled_vocabulary.yml.example /avalon-app/config/controlled_vocabulary.yml
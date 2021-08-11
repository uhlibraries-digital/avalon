FROM ruby:2.4.1

RUN apt-get update -q && apt-get install -y \
  build-essential \
  nodejs \
  imagemagick \
  mediainfo \
  shared-mime-info \
  lsof

# Setup lsof since Avalon likes to look in /usr/sbin for it
RUN ln -s /usr/bin/lsof /usr/sbin/lsof

# Install ffmpeg
RUN echo "deb http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50
RUN apt-get -o Acquire::Check-Valid-Until=false update -q && apt-get install -y ffmpeg

ENV APP_PATH=/avalon-app

RUN mkdir /avalon-app
RUN mkdir -p /streams/hls_streams
RUN mkdir -p /streams/rtmp_streams
RUN mkdir -p /var/avalon/uploads
RUN mkdir -p /var/avalon/dropbox
WORKDIR /avalon-app

ADD Gemfile /avalon-app/Gemfile
ADD Gemfile.lock /avalon-app/Gemfile.lock

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN gem install bundler -v 1.17.3  && bundle install
ADD . /avalon-app
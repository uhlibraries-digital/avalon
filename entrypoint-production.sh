#!/bin/sh

set -e

rm -f $APP_PATH/tmp/pids/server.pid

bundle exec rails s -p 3000 -b 0.0.0.0
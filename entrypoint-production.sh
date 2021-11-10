#!/bin/sh

set -e

rm -f $APP_PATH/tmp/pids/server.pid

BACKGROUND=yes bundle exec rake resque:scheduler &
BACKGROUND=yes QUEUE=* bundle exec rake resque:work &

bundle exec rails s -p 3000 -b 0.0.0.0
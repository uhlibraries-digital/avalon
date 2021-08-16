#!/bin/sh

set -e

echo "ENVIRONMENT: $RAILS_ENV"

bundle check || bundle install

rm -f $APP_PATH/tmp/pids/server.pid

BACKGROUND=yes bundle exec rake resque:scheduler &
BACKGROUND=yes QUEUE=* bundle exec rake resque:work &

bundle exec ${@}
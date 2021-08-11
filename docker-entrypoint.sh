#!/bin/sh

set -e

echo "ENVIRONMENT: $RAILS_ENV"

bundle check || bundle install

rm -f $APP_PATH/tmp/pids/server.pid

BACKGROUND=yes bundle exec rake resque:scheduler & >> $APP_PATH/log/resque_scheduler.log 2>&1
BACKGROUND=yes QUEUE=* bundle exec rake resque:work & >> $APP_PATH/log/resque_worker.log 2>&1

bundle exec ${@}
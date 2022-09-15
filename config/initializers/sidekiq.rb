redis_conn = { url: "redis://#{Settings.redis.host}:#{Settings.redis.port}/#{Settings.redis.db}" }
Sidekiq.configure_server do |s|
  s.redis = redis_conn
  if ENV["RAILS_LOG_LEVEL"].present?
    s.logger.level = ENV["RAILS_LOG_LEVEL"].to_sym
  end
  ActiveJob::Base.logger = s.logger
end

Sidekiq.configure_client do |s|
  s.redis = redis_conn
end

# Turn off Sinatra's sessions, which overwrite the main Rails app's session
# after the first request
require 'sidekiq/web'
Sidekiq::Web.disable(:sessions)

require 'sidekiq/cron/web'
begin
  # Only create cron jobs if Sidekiq can connect to Redis
  Sidekiq.redis(&:info)
  Sidekiq::Cron::Job.create(name: 'Scan for batches - every 1min', cron: '*/1 * * * *', class: 'BatchScanJob')
  Sidekiq::Cron::Job.create(name: 'Status Checking and Email Notification of Existing Batches - every 15min', cron: '*/15 * * * *', class: 'IngestBatchStatusEmailJobs::IngestFinished')
  Sidekiq::Cron::Job.create(name: 'Status Checking and Email Notification for Stalled Batches - every 1day', cron: '0 1 * * *', class: 'IngestBatchStatusEmailJobs::StalledJob')
  Sidekiq::Cron::Job.create(name: 'Clean out user sessions older than 7 days - every 6hour', cron: '0 */6 * * *', class: 'CleanupSessionJob')
  Sidekiq::Cron::Job.create(name: 'Clean out searches older than 20 minutes', cron: '*/20 * * * *', class: 'DeleteOldSearchesJob')
  Sidekiq::Cron::Job.create(name: 'Clean out encode queue older than 1 week', cron: '0 0 * * *', class: 'EncodeQueueJobs::Cleanup')
rescue Redis::CannotConnectError => e
  Rails.logger.warn "Cannot create sidekiq-cron jobs: #{e.message}"
end

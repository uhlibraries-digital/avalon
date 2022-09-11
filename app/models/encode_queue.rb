class EncodeQueue < ApplicationRecord
  serialize :options

  WAIT_TIME = 5.seconds.freeze

  def status?(value)
    status_code == value
  end

  def failed?
    status?('FAILED')
  end

  def succeeded?
    status?('COMPLETED')
  end

  def queued?
    status?('QUEUED')
  end

  def running?
    status?('RUNNING')
  end

  def finished_encoding?
    ['CANCELLED', 'COMPLETED', 'FAILED'].include?(status_code)
  end

  def encode!
    ActiveEncodeJobs::CreateEncodeJob.perform_now(input_path, master_file_id, options)
    EncodeQueueJobs::PollingJob.set(wait: WAIT_TIME).perform_later(id)
  end

  def check_status
    if running?
      EncodeQueueJobs::PollingJob.set(wait: WAIT_TIME).perform_later(id)
    elsif finished_encoding?
      EncodeQueueJobs::ProcessEncodeQueueJob.perform_now()
    end
  end
end

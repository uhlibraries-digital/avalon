module EncodeQueueJobs
  class CreateEncodeQueueJob < ActiveJob::Base
    queue_as :encode_queue

    def perform(input, master_file_id, options = {})
      return unless MasterFile.exists? master_file_id
      master_file = MasterFile.find(master_file_id)
      return if master_file.workflow_id.present?
      title = input.split('/').last
      EncodeQueue.create(
        title: title, 
        input_path: input, 
        master_file_id: master_file_id, 
        options: options, 
        percent_complete: 0, 
        status_code: 'QUEUED')
      EncodeQueueJobs::ProcessEncodeQueueJob.perform_now()
    end
  end

  class PollingJob < ActiveJob::Base
    queue_as :encode_queue

    def perform(encode_queue_id)
      return unless EncodeQueue.exists? encode_queue_id
      eq = EncodeQueue.find(encode_queue_id)
      return unless MasterFile.exists? eq.master_file_id
      master_file = MasterFile.find(eq.master_file_id)
      eq.status_code = master_file.status_code
      eq.percent_complete = master_file.percent_complete
      eq.save!
      eq.check_status
    end
  end

  class ProcessEncodeQueueJob < ActiveJob::Base
    include ActiveJob::Locking::Serialized

    queue_as :encode_queue
    
    def lock_key
      self.class.name
    end

    def perform()
      running = EncodeQueue.where(['status_code = "RUNNING" OR status_code = "STARTING"']).count
      if running < Settings.encoding.encode_limit
        diff = Settings.encoding.encode_limit - running
        EncodeQueue.where(status_code: 'QUEUED').limit(diff).each do |eq|
          Rails.logger.info("<< Encoding Queue #{eq.id} >>")
          eq.status_code = 'STARTING'
          eq.save!
          eq.encode!
        end
      end
    end
  end

  class Delete < ActiveJob::Base
    queue_as :encode_queue

    def perform(master_file_ids)
      master_file_ids.each do |id|
        EncodeQueue.where(master_file_id: id).destroy_all
      end
    end
  end

  class Cleanup < ActiveJob::Base
    queue_as :encode_queue

    def perform()
      EncodeQueue.where(['created_at < ? AND (status_code = "COMPLETED" OR status_code = "FAILED" OR status_code = "CANCELLED")', 1.week.ago]).destroy_all
    end
  end


end
class EncodeQueuePresenter
  include ActionView::Helpers::NumberHelper

  attr_reader :encode_queue

  def initialize(encode_queue)
    @encode_queue = encode_queue
  end

  delegate :id, :title, :master_file_id, :created_at, :percent_complete, to: :encode_queue

  def status
    @encode_queue.status_code.capitalize
  end

  def title
    @encode_queue.title
  end

  def master_file_url
    master_file_id.present? ? Rails.application.routes.url_helpers.master_file_path(master_file_id) : ''
  end

  def started
    DateTime.parse(@raw_object["created_at"]).utc.strftime('%D %r')
  end

  def ended
    DateTime.parse(@raw_object["updated_at"]).utc.strftime('%D %r')
  end

  def progress
    @encode_queue.percent_complete
  end
end
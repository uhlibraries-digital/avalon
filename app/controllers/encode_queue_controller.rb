class EncodeQueueController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:progress]

  def index
    authorize! :read, :encode_dashboard
    @encode_queues = EncodeQueue.all
  end

  def paged_index
    authorize! :read, :encode_dashboard

    columns = %w[status_code id percent_complete title master_file_id created_at].freeze

    records_total = EncodeQueue.count

    @encode_queue = EncodeQueue.all
    filtered_records_total = @encode_queue.count

     # Sort
     sort_column = columns[params['order']['0']['column'].to_i]
     sort_direction = params['order']['0']['dir'] == 'desc' ? 'desc' : 'asc'
     @encode_queue = @encode_queue.order(sort_column + ' ' + sort_direction)

    # Paginate
    page_num = (params['start'].to_i / params['length'].to_i).floor + 1
    @encode_queue = @encode_queue.page(page_num).per(params['length'])
    
    
    response = {
      "draw": params['draw'],
      "recordsTotal": records_total,
      "recordsFiltered": filtered_records_total,
      "data": @encode_queue.collect do |encode|
        encode_presenter = EncodeQueuePresenter.new(encode)
        encode_status = encode_presenter.status.downcase
        unless encode_status == 'completed'
          progress_class = 'progress-bar-striped'
        end
        encode_progress = format_progress(encode_presenter)
        [
          "<span data-encode-id=\"#{encode.id}\" class=\"encode-status\">#{encode_presenter.status}</span>",
          encode_presenter.id,
          "<div class=\"progress\"><div class=\"progress-bar #{encode_status} #{progress_class}\" data-encode-id=\"#{encode.id}\" aria-valuenow=\"#{encode_progress}\" aria-valuemin=\"0\" aria-valuemax=\"100\" style=\"width: #{encode_progress}%\"></div></div>",
          encode_presenter.title,
          view_context.link_to(encode_presenter.master_file_id, encode_presenter.master_file_url),
          encode_presenter.created_at.strftime('%Y-%m-%d %H:%M:%S')
        ]
      end
    }
    respond_to do |format|
      format.json do
        render json: response
      end
    end
  end

  def progress
    authorize! :read, :encode_dashboard
    progress_data = {}
    EncodeQueue.where(id: params[:ids]).each do |encode|
      presenter = EncodeQueuePresenter.new(encode)
      progress_data[encode.id] = { progress: format_progress(presenter), status: presenter.status }
    end
    respond_to do |format|
      format.json do
        render json: progress_data
      end
    end
  end

private

  def format_progress(presenter)
    # Set progress = 100.0 when job failed
    if presenter.status.casecmp("failed") == 0
      100.0
    else
      presenter.progress
    end
  end

end
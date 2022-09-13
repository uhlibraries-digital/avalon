class CreateEncodeQueues < ActiveRecord::Migration[5.2]
  def change
    create_table :encode_queues do |t|
      t.string :title
      t.string :master_file_id
      t.string :status_code
      t.float  :percent_complete
      t.string :options
      t.string :input_path

      t.timestamps
    end
  end
end

class CreateReportingTimes < ActiveRecord::Migration
  def self.up
    create_table :reporting_times do |t|
      t.string :time_in
      t.string :out_time
      t.boolean :is_in_time
      #t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :reporting_times
  end
end

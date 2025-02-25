class CreateAttendanceMesssages < ActiveRecord::Migration
  def self.up
    create_table :attendance_messsages do |t|
      t.string :in_message
      t.string :out_message
      t.string :absent_message
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :attendance_messsages
  end
end

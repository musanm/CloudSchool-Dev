class CreateStudentAttendances < ActiveRecord::Migration
  def self.up
    create_table :student_attendances do |t|
      t.integer :student_id
      t.datetime :in_time
      t.datetime :out_time

      t.timestamps
    end
  end

  def self.down
    drop_table :student_attendances
  end
end

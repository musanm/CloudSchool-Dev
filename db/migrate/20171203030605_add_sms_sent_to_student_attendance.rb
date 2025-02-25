class AddSmsSentToStudentAttendance < ActiveRecord::Migration
  def self.up
    add_column :student_attendances, :sms_sent, :boolean
  end

  def self.down
    remove_column :student_attendances, :sms_sent
  end
end

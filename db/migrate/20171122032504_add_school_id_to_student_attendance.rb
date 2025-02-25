class AddSchoolIdToStudentAttendance < ActiveRecord::Migration
  def self.up
    add_column :student_attendances, :school_id, :integer
  end

  def self.down
    remove_column :student_attendances, :school_id
  end
end

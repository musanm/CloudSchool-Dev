class AddEmployeeIdToStudentAttendance < ActiveRecord::Migration
  def self.up
    add_column :student_attendances, :employee_id, :integer
  end

  def self.down
    remove_column :student_attendances, :employee_id
  end
end

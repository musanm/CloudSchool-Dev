class AddReportingTImeToEmployee < ActiveRecord::Migration
  def self.up
    add_column :employees, :reporting_in_time, :string
    add_column :employees, :reporting_out_time, :string
  end

  def self.down
    remove_column :employees, :reporting_out_time
    remove_column :employees, :reporting_in_time
  end
end

class AddSchoolIdToReportingTime < ActiveRecord::Migration
  def self.up
    add_column :reporting_times, :school_id, :integer
  end

  def self.down
    remove_column :reporting_times, :school_id
  end
end

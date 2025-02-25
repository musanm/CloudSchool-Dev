class AddInTimeToSchoolDetail < ActiveRecord::Migration
  def self.up
    add_column :school_details, :in_time, :datetime
    add_column :school_details, :out_time, :datetime
  end

  def self.down
    remove_column :school_details, :out_time
    remove_column :school_details, :in_time
  end
end

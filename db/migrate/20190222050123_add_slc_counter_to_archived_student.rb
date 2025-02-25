class AddSlcCounterToArchivedStudent < ActiveRecord::Migration
  def self.up
    add_column :archived_students, :slc_counter, :integer
  end

  def self.down
    remove_column :archived_students, :slc_counter
  end
end

class AddSchoolNameToAttachSignature < ActiveRecord::Migration
  def self.up
    add_column :attach_signatures, :school_id, :integer
  end

  def self.down
    remove_column :attach_signatures, :school_id
  end
end

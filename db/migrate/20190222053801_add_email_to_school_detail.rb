class AddEmailToSchoolDetail < ActiveRecord::Migration
  def self.up
    add_column :school_details, :email, :string
    add_column :school_details, :website, :string
  end

  def self.down
    remove_column :school_details, :email
    remove_column :school_details, :website
  end
end

class AddSchoolIdTwo < ActiveRecord::Migration
  def self.up
      add_column :donation_additional_details, :school_id, :integer
      add_column :donation_additional_fields, :school_id, :integer
      add_column :donation_additional_field_options, :school_id, :integer
  
      add_index :donation_additional_details, :school_id
      add_index :donation_additional_fields, :school_id
      add_index :donation_additional_field_options, :school_id
    end

  def self.down
      remove_index :donation_additional_details, :school_id
      remove_index :donation_additional_fields, :school_id
      remove_index :donation_additional_field_options, :school_id
      
      remove_column :donation_additional_details, :school_id
      remove_column :donation_additional_fields, :school_id
      remove_column :donation_additional_field_options, :school_id
    end
end
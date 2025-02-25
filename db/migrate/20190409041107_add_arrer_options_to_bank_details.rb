class AddArrerOptionsToBankDetails < ActiveRecord::Migration
    def self.up
    add_column :bank_details, :remove_arrears, :boolean
    add_column :bank_details, :copy_name_one, :string
    add_column :bank_details, :copy_name_two, :string
    add_column :bank_details, :copy_name_three, :string
    add_column :bank_details, :copy_name_four, :string
  end

  def self.down
    remove_column :bank_details, :remove_arrears
    remove_column :bank_details, :copy_name_one
    remove_column :bank_details, :copy_name_two
    remove_column :bank_details, :copy_name_three
    remove_column :bank_details, :copy_name_four
  end
end

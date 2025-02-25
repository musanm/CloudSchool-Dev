class AddOptionsToBankDetails < ActiveRecord::Migration
    def self.up
    add_column :bank_details, :remove_discounts, :boolean
    add_column :bank_details, :remove_end_date, :boolean
    add_column :bank_details, :display_type, :integer
  end

  def self.down
    remove_column :bank_details, :remove_discounts
    remove_column :bank_details, :remove_end_date
    remove_column :bank_details, :display_type
  end
end

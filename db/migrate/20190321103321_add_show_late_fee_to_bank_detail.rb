class AddShowLateFeeToBankDetail < ActiveRecord::Migration
  def self.up
    add_column :bank_details, :show_late_fee, :boolean
  end

  def self.down
    remove_column :bank_details, :show_late_fee
  end
end

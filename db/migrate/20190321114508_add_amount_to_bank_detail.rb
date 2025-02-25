class AddAmountToBankDetail < ActiveRecord::Migration
  def self.up
    add_column :bank_details, :amount, :string
  end

  def self.down
    remove_column :bank_details, :amount
  end
end

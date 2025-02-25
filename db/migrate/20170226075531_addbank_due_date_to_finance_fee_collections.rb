class AddbankDueDateToFinanceFeeCollections < ActiveRecord::Migration
  def self.up
  	add_column :finance_fee_collections,:bank_due_date, :date
  end

  def self.down
  	remove_column :finance_fee_collections,:bank_due_date
  end
end

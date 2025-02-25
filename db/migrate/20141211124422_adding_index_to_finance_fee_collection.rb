class AddingIndexToFinanceFeeCollection < ActiveRecord::Migration
  def self.up
    add_index :finance_fee_collections,:is_deleted
    add_index :finance_fee_collections,:due_date
    add_index :finance_fee_collections,[:is_deleted,:due_date],:name => :is_deleted_and_due_date
  end

  def self.down
    remove_index :finance_fee_collections,:is_deleted
    remove_index :finance_fee_collections,:due_date
    remove_index :finance_fee_collections,:is_deleted_and_due_date
  end
end

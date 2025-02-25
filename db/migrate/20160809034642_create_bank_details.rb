class CreateBankDetails < ActiveRecord::Migration
  def self.up
    create_table :bank_details do |t|
      t.string :bank_name
      t.string :account_no
      t.string :message
      t.integer :school_id 

      t.timestamps
    end
  end

  def self.down
    drop_table :bank_details
  end
end

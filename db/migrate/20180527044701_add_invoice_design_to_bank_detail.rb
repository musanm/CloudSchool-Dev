class AddInvoiceDesignToBankDetail < ActiveRecord::Migration
  def self.up
    add_column :bank_details, :invoice_design, :string
  end

  def self.down
    remove_column :bank_details, :invoice_design
  end
end

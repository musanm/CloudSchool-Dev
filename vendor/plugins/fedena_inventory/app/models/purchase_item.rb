
class PurchaseItem < ActiveRecord::Base
  belongs_to :user
  belongs_to :purchase_order
  belongs_to :store_item

  validates_presence_of :quantity, :discount, :tax,:store_item_id, :price
  validates_numericality_of  :price,:greater_than => 0, :less_than_or_equal_to => 10000000
  validates_numericality_of  :quantity, :greater_than_or_equal_to => 0, :less_than => 100000
  validates_numericality_of :discount,:tax, :greater_than_or_equal_to => 0, :less_than => 100

  default_scope :conditions => { :is_deleted => false }

  named_scope :active,{ :conditions => { :is_deleted => false }}

  before_save :verify_precision

  def verify_precision
    self.price = FedenaPrecision.set_and_modify_precision self.price
    self.tax = FedenaPrecision.set_and_modify_precision self.tax
    self.discount = FedenaPrecision.set_and_modify_precision self.discount
  end

  def destroy
    update_attributes(:is_deleted => true)
  end

end

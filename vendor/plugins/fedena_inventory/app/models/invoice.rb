class Invoice < ActiveRecord::Base
  has_many :sold_items
  has_many :additional_charges
  has_many :discounts
  has_many :sales_user_details
  has_one :finance_transaction, :as => :finance
  validates_uniqueness_of :invoice_no, :scope => :store_id
  belongs_to :store
  attr_accessor :subtotal, :grandtotal
  accepts_nested_attributes_for :sold_items, :allow_destroy => true
  accepts_nested_attributes_for :additional_charges, :allow_destroy => true, :reject_if => lambda { |a| a.values.all?(&:blank?) }
  accepts_nested_attributes_for :discounts, :allow_destroy => true, :reject_if => lambda { |a| a.values.all?(&:blank?) }
  accepts_nested_attributes_for :sales_user_details, :allow_destroy => true
  #belongs_to :finance_transaction
  validates_numericality_of :tax, :greater_than_or_equal_to => 0, :allow_nil => true
  after_create :update_item_quantity_on_create
  after_validation_on_update :update_item_quantity_on_update
  
  before_destroy :restore_quantities

  validate_on_create :check_store
  validate_on_update :check_store
  
  def update_item_quantity_on_create
    self.sold_items.each do |item|
      new_qty = item.store_item.quantity - item.quantity
      if new_qty >= 0
        item.store_item.update_attribute(:quantity,new_qty)
      else
        item.store_item.update_attribute(:quantity,0)
      end
    end
  end

  def update_item_quantity_on_update
    self.sold_items.each do |item|
      unless item.changes.empty?
        unless item.changes["quantity"].nil?
          qty = item.store_item.quantity + item.changes["quantity"].first
          item.store_item.update_attribute(:quantity,qty)
          new_qty = item.store_item.quantity - item.quantity.to_i
          if new_qty >= 0
            item.store_item.update_attribute(:quantity,new_qty)
          else
            item.store_item.update_attribute(:quantity,0)
          end
        end
      end
    end
  end

  def is_paid?
    return false if self.is_paid == true
    return true
  end

  def restore_quantities
    store_items = self.sold_items
    store_items.each do |item|
      item.store_item.update_attribute(:quantity, item.store_item.quantity + item.quantity)
    end
  end

  def validate
    self.sold_items.group_by(&:store_item_id).each do |k,v|
      errors.add("sold_items","added multiple times") if v.count > 1
      return
    end
    
  end

  def check_store
    store_id = self.store_id
    self.sold_items.each do |item|
      unless item.store_item.nil?
        if item.store_item.store_id != store_id
          errors.add("item","does not belong to store")
        return
        end
      end
    end
  end
  
end

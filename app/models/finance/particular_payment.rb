class ParticularPayment < ActiveRecord::Base
  belongs_to :finance_fee
  belongs_to :finance_fee_particular
  has_many :particular_discounts, :dependent=>:destroy


  accepts_nested_attributes_for :particular_discounts, :allow_destroy=>true
end

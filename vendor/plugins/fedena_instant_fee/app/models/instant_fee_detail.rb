class InstantFeeDetail < ActiveRecord::Base
  belongs_to :instant_fee
  belongs_to :instant_fee_particular
  before_save :verify_precision

  def verify_precision
    self.amount = FedenaPrecision.set_and_modify_precision self.amount
    self.discount = FedenaPrecision.set_and_modify_precision self.discount
    self.net_amount = FedenaPrecision.set_and_modify_precision self.net_amount
  end

  def particular_name
    self.instant_fee_particular.nil? ? self.custom_particular : self.instant_fee_particular.name
  end

  def particular_description
    self.instant_fee_particular.nil? ? "Custom Particular" : self.instant_fee_particular.description
  end
end

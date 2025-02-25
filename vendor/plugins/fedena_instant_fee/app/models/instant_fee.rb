class InstantFee < ActiveRecord::Base
  belongs_to :instant_fee_category
  has_many :instant_fee_details
  has_one :finance_transaction,:as => :finance
  belongs_to :payee, :polymorphic => true

  validates_presence_of :amount,:pay_date
  #  validates_numericality_of :amount
  before_save :verify_precision

  def verify_precision
    self.amount = FedenaPrecision.set_and_modify_precision self.amount
  end
  def name
  category_name
  end

  def category_name
    self.instant_fee_category.nil? ? self.custom_category : self.instant_fee_category.name
  end
  def category_description
    self.instant_fee_category.nil? ? self.custom_description : self.instant_fee_category.description
  end
  def payee_name
    payee = self.payee.nil? ? self.guest_payee : self.payee.full_name
    payee.nil? ? archived_payee_name : payee
  end

  def archived_payee_name
    if self.payee_type=="Student"
      payee = ArchivedStudent.find_by_former_id(self.payee_id)
    elsif self.payee_type=="Employee"
      payee=ArchivedEmployee.find_by_former_id(self.payee_id)
    end
    payee.present?? payee.full_name : "#{t('user_deleted')}"
  end

  def particular_total_amount
    total_amount = 0
    self.instant_fee_details.each do |detail|
      total_amount += detail.amount
    end
    total_amount
  end

  def particular_total_net_amount
    total_net_amount = 0
    self.instant_fee_details.each do |detail|
      total_net_amount += detail.net_amount
    end
    total_net_amount
  end

  def particular_total_discount
    total_amount = self.particular_total_amount
    total_net_amount = self.particular_total_net_amount
    total_discount = total_amount - total_net_amount
    total_discount
  end
  def validate
    if (self.guest_payee.blank? or self.guest_payee.blank?) and self.payee_id.nil?
      return false
    else
      return true
    end
  end
end
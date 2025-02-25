class Payment < ActiveRecord::Base
  belongs_to :payment, :polymorphic => true
  belongs_to :payee, :polymorphic => true
  belongs_to :finance_transaction
  belongs_to :fee_collection, :polymorphic => true
  serialize :gateway_response

  
  def before_create
    if payment_type == "FinanceFee"
      if Payment.find_by_payee_id_and_payment_id_and_payment_type_and_status_and_status_description(payee_id,payment_id,'FinanceFee',1,1).present?
        false
      else
        true
      end
    elsif payment_type == "Application"
      if Payment.find_by_payee_id_and_status(payee_id,1).present?
        false
      else
        true
      end
    end
  end

  def payee_name
    if payee.nil?
      if payee_type == 'Student'
        ArchivedStudent.find_by_former_id(payee_id).try(:full_name) || "NA"
      elsif payee_type == 'Guardian'
        ArchivedGuardian.find_by_former_id(payee_id).try(:full_name) || "NA"
      elsif payee_type == 'Applicant'
        "NA"
      end
    else
      payee.full_name
    end
  end

  def payee_user
    if payee.nil?
      if payee_type == 'Student'
        ArchivedStudent.find_by_former_id(payee_id).try(:admission_no) || "NA"
      elsif payee_type == 'Guardian'
        ArchivedGuardian.find_by_former_id(payee_id).try(:user).try(:username) || "NA"
      elsif payee_type == 'Applicant'
        "NA"
      end
    else
      payee_type == 'Applicant' ? payee.try(:reg_no) : payee.try(:user).try(:username)
    end
  end

  def self.payment_status_mapping
    {
      :success => 1,
      :reverted => 2,
      :failed => 3
    }
  end
  
end

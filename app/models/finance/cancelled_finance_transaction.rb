class CancelledFinanceTransaction < ActiveRecord::Base
  belongs_to :category, :class_name => 'FinanceTransactionCategory', :foreign_key => 'category_id'
  belongs_to :student ,:primary_key => 'payee_id'
  belongs_to :employee ,:primary_key => 'payee_id'
  belongs_to :instant_fee,:foreign_key=>'finance_id',:conditions=>'payee_id is NULL'
  belongs_to :finance, :polymorphic => true
  belongs_to :payee, :polymorphic => true
  belongs_to :master_transaction,:class_name => "FinanceTransaction"
  belongs_to :user
  serialize  :other_details, Hash

  after_create :update_collection_name

  def update_collection_name
    update_attributes(:transaction_date=>created_at.strftime("%m-%d-%Y"))
  end

  def get_archieved_payee_name
    if payee_type=='Student' or payee_type=='Employee'
      archived_payee=("Archived"+payee_type).constantize.find_by_former_id(payee_id)
      if archived_payee.present?
        return "#{archived_payee.full_name}-&#x200E; (#{payee_type=="Student" ? archived_payee.admission_no : archived_payee.employee_number })&#x200E;"
      else
        return "#{t('user_deleted')}"
      end
    else
      return nil
    end
  end

  def payee_name
    if payee_type.present? and payee_id.present?
      if payee.present?
        "#{payee.full_name}-&#x200E; (#{payee_type=="Student" ? payee.admission_no : payee.employee_number })&#x200E;"
      else
        get_archieved_payee_name
      end
    elsif finance_type.present? and !(finance_type.constantize.present? rescue false)
      return nil
    elsif payee.nil? and finance.nil?
      return "#{t('user_deleted')}"
    else payee.nil?
      finance.payee_name
    end
  end
end


class TransportFee < ActiveRecord::Base
  
  belongs_to :transport_fee_collection
  delegate :name,:to=>:transport_fee_collection,:allow_nil=>true
  belongs_to :receiver, :polymorphic => true
  has_one :finance_transaction, :as => :finance
  before_save :verify_precision
  named_scope :active , :joins=>[:transport_fee_collection] ,:conditions=>"transport_fee_collections.is_deleted=false and transport_fees.is_active=true", :readonly => false


  def verify_precision
    self.bus_fare = FedenaPrecision.set_and_modify_precision self.bus_fare
  end

  def next_user
    next_st =  self.transport_fee_collection.transport_fees.first(:conditions => "id > #{self.id}", :order => "id ASC")
    next_st ||= self.transport_fee_collection.transport_fees.first(:order => "id ASC")
  end

  def previous_user
    prev_st = self.transport_fee_collection.transport_fees.first(:conditions => "id < #{self.id}", :order => "id DESC")
    prev_st ||= self.transport_fee_collection.transport_fees.first(:order => "id DESC")
    prev_st ||= self.first(:order => "id DESC")
  end
  def next_default_user
    next_st =  self.transport_fee_collection.transport_fees.first(:conditions => "id > #{self.id} and transaction_id is null", :order => "id ASC")
    next_st ||= self.transport_fee_collection.transport_fees.first( :conditions=>["transaction_id is null"] , :order => "id ASC")
  end

  def previous_default_user
    prev_st = self.transport_fee_collection.transport_fees.first(:conditions => "id < #{self.id} and transaction_id is null", :order => "id DESC")
    prev_st ||= self.transport_fee_collection.transport_fees.first( :conditions=>["transaction_id is null"],:order => "id DESC")
    prev_st ||= self.transport_fee_collection.transport_fees.first( :conditions=>["transaction_id is null"], :order => "id DESC")
  end

  def get_transport_fee_collection(start_date, end_date ,trans_id)
    transport_id = FinanceTransactionCategory.find_by_name('Transport').id
    FinanceTransaction.find(:all,:conditions=>"FIND_IN_SET(id,\"#{trans_id}\") and transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}' and category_id ='#{transport_id}' ")
  end
  
  def former_student
    return ArchivedStudent.find_by_former_id(self.receiver_id)
  end

  def former_employee
    return ArchivedEmployee.find_by_former_id(self.receiver_id)
  end

  def student_id
    return self.receiver_id if self.receiver_type == 'Student'
  end
  def payee_name
    if receiver.nil?
      if receiver_type=="Student"
        if former_student
          "#{former_student.full_name}(#{former_student.admission_no})"
        else
          "#{t('user_deleted')}"
        end
      else
        if former_employee
         "#{former_employee.full_name}(#{former_employee.employee_number})"
        else
           "#{t('user_deleted')}"
        end
      end
    else
      receiver.full_name
    end
  end
end

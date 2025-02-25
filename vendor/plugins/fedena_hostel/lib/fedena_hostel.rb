require 'dispatcher'
# FedenaHostel
module FedenaHostel
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_hostel do
      ::Employee.instance_eval { has_many :wardens, :dependent => :destroy }
      ::FinanceTransaction.instance_eval { include FinanceTransactionExtension }
      ::Student.instance_eval { include StudentExtension }
      ::Batch.instance_eval { include BatchExtension }
    end
  end

  def self.dependency_delete(student)
    student.room_allocations.destroy_all
    student.hostel_fees.destroy_all
  end
  
  def self.dependency_check(record,type)
    if type == "permanant"
      if record.class.to_s == "Student"
        return true if record.room_allocations.all(:conditions=>"is_vacated=0").present?
        return true if record.hostel_fees.active.present?
      elsif record.class.to_s == "Employee"
        return true if record.wardens.all.present?
      end
    end
    return false
  end

  def self.student_profile_fees_hook
    "hostel_fee/student_profile_fees"
  end

  def self.mobile_student_profile_fees_hook
    "hostel_fee/mobile_student_profile_fees"
  end

  module StudentExtension
    def self.included(base)
      base.instance_eval do
        has_many :room_allocations, :dependent => :destroy
        has_many :hostel_fees
        accepts_nested_attributes_for :hostel_fees
        DependencyHook.make_dependency_hook(:hostel_batch_fee, :student,:warning_message=>:hostel_fee_are_already_assigned ) do
          self.batch_hostel_fees_exist
        end
        DependencyHook.make_dependency_hook(:hostel_batch_fee_value, :student ) do
          self.hostel_fee_collections
        end
        DependencyHook.make_dependency_hook(:fedena_hostel_dependency, :student,:warning_message=>:hostel_allotted ) do
          self.hostel_dependencies
        end
      end
    end

    def hostel_dependencies
      return false if self.room_allocations.all(:conditions=>"is_vacated=0").present? or self.hostel_fees.active.present?
      return true
    end
    
    def current_allocation
      RoomAllocation.find_by_student_id(self.id,:conditions=>"is_vacated=0")
    end

    def hostel_fee_transactions(fee_collection)
      HostelFee.find_by_hostel_fee_collection_id_and_student_id(fee_collection.id,self.id)
    end
  
    def hostel_fee_balance(fee_collection_id)
      fee_collection= HostelFeeCollection.find(fee_collection_id)
      hostelfee = self.hostel_fee_transactions(fee_collection)
      paid_fees = hostelfee.finance_transaction unless hostelfee.finance_transaction_id.blank?
      unless paid_fees.nil?
        #      balance= hostelfee.rent.to_f - paid_fees.amount.to_f
        balance=0
      else
        balance=hostelfee.rent.to_f
      end
      return balance
    end

    def hostel_fee_collections
      HostelFeeCollection.find(:all ,:joins=>'INNER JOIN hostel_fees ON hostel_fee_collections.id = hostel_fees.hostel_fee_collection_id',:conditions=>"hostel_fees.student_id = #{self.id} and hostel_fee_collections.is_deleted = 0 and hostel_fees.is_active=1")
    end

    def hostel_fee_collections_exists
      hostel_fee_collections.empty?
    end

    def batch_hostel_fees_exist
      hostel_fees.select{|h| h.try(:hostel_fee_collection).try(:batch_id) == batch_id and !h.try(:hostel_fee_collection).try(:is_deleted)}.empty?
    end
  end

  module BatchExtension
    def self.included(base)
      base.instance_eval do
        has_many :room_allocations, :through => :students
      end
    end

    def room_allocations_present
      flag = false
      unless self.room_allocations.blank?
        self.room_allocations.each do |room|
          flag = true unless room.is_vacated
        end
      end
      return flag
    end
  end

  module FinanceTransactionExtension
    def hosteller
      fee = self.finance
      student = fee.student
      student ||= ArchivedStudent.find_by_former_id(fee.student_id)
      student.full_name
    end
  end
end




#

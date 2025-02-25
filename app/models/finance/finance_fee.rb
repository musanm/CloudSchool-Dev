#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class FinanceFee < ActiveRecord::Base

  belongs_to :finance_fee_collection, :foreign_key => 'fee_collection_id'
  delegate :name,:to=>:finance_fee_collection,:allow_nil=>true
  has_many :finance_transactions, :as => :finance
  has_many :cancelled_finance_transactions, :as => :finance
  has_many :components, :class_name => 'FinanceFeeComponent', :foreign_key => 'fee_id'
  belongs_to :student
  belongs_to :batch
  belongs_to :student_category
  has_many :finance_transactions, :through => :fee_transactions, :dependent => :destroy
  has_many :fee_transactions
  has_one :fee_refund
  has_many :particular_payments, :dependent => :destroy

  accepts_nested_attributes_for :particular_payments
  named_scope :active, :joins => [:finance_fee_collection], :conditions => {:finance_fee_collections => {:is_deleted => false}}

  def check_transaction_done
    unless self.transaction_id.nil?
      return true
    else
      return false
    end
  end

  def former_student
    ArchivedStudent.find_by_former_id(self.student_id)
  end

  def due_date
    format_date(finance_fee_collection.due_date, :format => :long)
  end

  def payee_name
    if student
      "#{student.full_name} - #{student.admission_no}"
    elsif former_student
      "#{former_student.full_name} - #{former_student.admission_no}"
    else
      "#{t('user_deleted')}"
    end
  end

  def self.new_student_fee(date, student)
    fee_particulars = date.finance_fee_particulars.all(:conditions => "batch_id=#{student.batch_id}").select { |par| (par.receiver.present?) and (par.receiver==student or par.receiver==student.student_category or par.receiver==student.batch) }
    discounts=date.fee_discounts.all(:conditions => "batch_id=#{student.batch_id}").select { |par| (par.receiver.present?) and ((par.receiver== student or par.receiver == student.student_category or par.receiver== student.batch) and (par.master_receiver_type!='FinanceFeeParticular' or (par.master_receiver_type=='FinanceFeeParticular' and (par.master_receiver.receiver.present? and par.master_receiver.is_deleted==false) and (par.master_receiver.receiver== student or par.master_receiver.receiver == student.student_category or par.master_receiver.receiver== student.batch)))) }

    total_discount = 0
    total_payable=fee_particulars.map { |l| l.amount }.sum.to_f
    total_discount =discounts.map { |d| d.master_receiver_type=='FinanceFeeParticular' ? (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) : total_payable * d.discount.to_f/(d.is_amount? ? total_payable : 100) }.sum.to_f unless discounts.nil?
    balance=FedenaPrecision.set_and_modify_precision(total_payable-total_discount)
    FinanceFee.create(:student_id => student.id, :fee_collection_id => date.id, :balance => balance, :batch_id => student.batch_id, :student_category_id => student.student_category_id, :is_paid => (balance.to_f<=0))
  end

  def self.csv_batch_fees_head_wise_report(parameters)
    batch_ids=parameters[:batch_ids] if parameters[:batch_ids].present?
    if batch_ids.present?
      students=Student.all(:select => "DISTINCT students.*", :conditions => ["finance_fees.batch_id IN (?)", batch_ids], :joins => :finance_fees, :include => [{:finance_fees => [{:finance_fee_collection => [{:collection_particulars => :finance_fee_particular}, {:collection_discounts => :fee_discount}]}, :finance_transactions, :batch]}], :order => 'first_name ASC')
    else
      students=Student.all(:select => "DISTINCT students.*", :joins => :finance_fees, :include => [{:finance_fees => [{:finance_fee_collection => [{:collection_particulars => :finance_fee_particular}, {:collection_discounts => :fee_discount}]}, :finance_transactions, :batch]}], :order => 'first_name ASC')
    end
    col_heads=["#{t('no_text')}", "#{t('student_name')}", "#{t('batch_name')}", "#{t('fee_collection')} #{t('name')}", "#{t('amount_to_pay')}(#{Configuration.currency})", "#{t('paid')} #{t('amount')}(#{Configuration.currency})", "#{t('particulars')}", "#{t('discount')}"]


    return FinanceFee.csv_make_data(students,col_heads,parameters)
  end


  def self.csv_fee_collection_fees_head_wise_report(parameters)
    students=Student.all(:select => "DISTINCT students.*", :conditions => ["finance_fees.fee_collection_id=? and finance_fees.batch_id = ?", parameters[:fee_collection_id], parameters[:batch_id]], :joins => :finance_fees, :include => [{:finance_fees => [{:finance_fee_collection => [{:collection_particulars => :finance_fee_particular}, {:collection_discounts => :fee_discount}]}, :finance_transactions, :batch]}], :order => 'first_name ASC')
    data=[]
    col_heads=["#{t('no_text')}", "#{t('student_name')}", "#{t('batch_name')}", "#{t('amount_to_pay')}(#{Configuration.currency})", "#{t('paid')} #{t('amount')}(#{Configuration.currency})", "#{t('particulars')}", "#{t('discount')}"]
    return FinanceFee.csv_make_data(students,col_heads,parameters)
  end


  def self.csv_make_data(students, col_heads, parameters)
    data=[]
    data << col_heads
    students.each_with_index do |student, i|
      total_bal=student.finance_fees.collect(&:balance).sum
      total_paid=0
      if col_heads.include? "#{t('fee_collection')} #{t('name')}"
        finance_fees=student.finance_fees
      else
        finance_fees=student.finance_fees.find(:all, :conditions => "fee_collection_id='#{parameters[:fee_collection_id]}'")
      end

      finance_fees.each do |finance_fee|
        total_paid=total_paid+finance_fee.finance_transactions.collect(&:amount).sum
        ffc=finance_fee.finance_fee_collection
        particulars=ffc.collection_particulars.select { |cp| cp.finance_fee_particular.present? and ((cp.finance_fee_particular.batch_id==finance_fee.batch_id and cp.finance_fee_particular.receiver.present?) and (cp.finance_fee_particular.receiver==finance_fee.student_category or cp.finance_fee_particular.receiver==finance_fee.batch or cp.finance_fee_particular.receiver==student)) }
        discounts=ffc.collection_discounts.select { |cd| cd.fee_discount.present? and ((cd.fee_discount.batch_id==finance_fee.batch_id and cd.fee_discount.receiver.present?)and (cd.fee_discount.receiver==finance_fee.student_category or cd.fee_discount.receiver==finance_fee.batch or cd.fee_discount.receiver==student)) }
        count=[particulars.length, discounts.length].max
        k=0
        while k<count
          col=[]
          col<< "#{i+1}"
          if Configuration.enabled_roll_number?
            student_no = "- #{student.roll_number}"
          else
            student_no = "(#{student.admission_no})"
          end
          col<< "#{student.full_name}#{student_no}"
          col<< "#{student.batch.full_name}"
          col<< "#{ffc.name}" if col_heads.include? "#{t('fee_collection')} #{t('name')}"
          if k==0
            col<< "#{finance_fee.balance.nil? ? FedenaPrecision.set_and_modify_precision(0) : FedenaPrecision.set_and_modify_precision(finance_fee.balance)}"
            col<< "#{FedenaPrecision.set_and_modify_precision(finance_fee.finance_transactions.collect(&:amount).sum)}"
          else
            col<<""
            col<<""
          end
          col<< "#{(particulars[k].present?) ? (particulars[k].finance_fee_particular.name+':'+FedenaPrecision.set_and_modify_precision(particulars[k].finance_fee_particular.amount.to_f)) : '-' }"
          col<< "#{(discounts[k].present?) ? (discounts[k].fee_discount.name+':'+FedenaPrecision.set_and_modify_precision(discounts[k].fee_discount.discount.to_f)+(discounts[k].fee_discount.is_amount? ? '' : '%')) : '-' }"
          col=col.flatten
          data<< col
          k=k+1
        end
      end
      if col_heads.include? "#{t('fee_collection')} #{t('name')}"
        data<< ["", "", "", "TOTAL", FedenaPrecision.set_and_modify_precision(total_bal), FedenaPrecision.set_and_modify_precision(total_paid), "", ""]
      else
        data<< ["", "", "TOTAL", FedenaPrecision.set_and_modify_precision(total_bal), FedenaPrecision.set_and_modify_precision(total_paid), "", ""]
      end

    end
    return data
  end

end

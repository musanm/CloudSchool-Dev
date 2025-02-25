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

class FinanceFeeParticular < ActiveRecord::Base

  belongs_to :finance_fee_category
  belongs_to :student_category
  belongs_to :receiver,:polymorphic=>true
  belongs_to :batch
  has_many   :finance_fee_collections,:through=>:collection_particulars
  has_many   :collection_particulars,:dependent => :destroy
  has_many   :fee_discounts
  has_many :particular_payments
  has_many :particular_wise_discounts,:class_name => 'FeeDiscount',:foreign_key => 'master_receiver_id',:conditions=>"fee_discounts.master_receiver_type='FinanceFeeParticular'"
  validates_presence_of :name,:amount,:finance_fee_category_id,:batch_id,:receiver_id,:receiver_type
  validates_numericality_of :amount, :greater_than_or_equal_to => 0, :message => :must_be_positive, :allow_blank => true
  named_scope :active,{ :conditions => { :is_deleted => false}}
  named_scope :batch_particulars,{:conditions=>{:is_deleted=>false,:receiver_type=>'Batch'},:group=>["name,receiver_type"]}
  named_scope :category_particulars,{:conditions=>["is_deleted=false and (receiver_type='Batch' or receiver_type='StudentCategory')"],:group=>["name,receiver_type"]}
  cattr_reader :per_page
  @@per_page = 10
  before_save :verify_precision
  before_update :check_discounts

  def verify_precision
    self.amount = FedenaPrecision.set_and_modify_precision self.amount
  end
  
  def deleted_category
    flag = false
    category = receiver if receiver_type=='StudentCategory'
    if category
      flag = true if category.is_deleted
    end
    return flag
  end

  def student_name
    if receiver_id.present?
      student = Student.find_by_id(receiver_id)
      student ||= ArchivedStudent.find_by_former_id(receiver_id)
      student.present? ? "#{student.first_name} &#x200E;(#{student.admission_no})&#x200E;" : "N.A. (N.A.)"
    end
  end

  def collection_exist
    collection_ids=finance_fee_category.fee_collections.collect(&:id)
    if CollectionParticular.find_by_finance_fee_particular_id_and_finance_fee_collection_id(id,collection_ids)
    errors.add_to_base(t('collection_exists_for_this_category_cant_edit_this_particular'))
      return false
    else
      return true
    end
  end

  def delete_particular
      update_attributes(:is_deleted=>true)
  end

  def self.student_category_batches(name,type)
    Batch.find(:all,:joins=>"INNER JOIN finance_fee_particulars on batches.id=finance_fee_particulars.batch_id INNER JOIN students on students.batch_id=batches.id",:conditions=>"finance_fee_particulars.name='#{name}' and (finance_fee_particulars.receiver_type='#{type}' and finance_fee_particulars.is_deleted<>true)").uniq
    #find(:all,:joins=>"INNER JOIN batches on batches.id=finance_fee_particulars.batch_id INNER JOIN students on students.batch_id=batches.id",:conditions=>"finance_fee_particulars.name='#{name}' and (finance_fee_particulars.receiver_type='#{type}' and finance_fee_particulars.is_deleted<>true)").map{|b| b.batch}.uniq
  end

  def self.add_or_remove_particular_or_discount(particular_or_discount,finance_fee_collection)
    receiver=particular_or_discount.receiver_type.underscore+"_id"

    sql1="UPDATE finance_fees ff SET ff.balance=(select sum(finance_fee_particulars.amount) from finance_fee_particulars INNER JOIN collection_particulars on collection_particulars.finance_fee_particular_id=finance_fee_particulars.id  where collection_particulars.finance_fee_collection_id=#{finance_fee_collection.id} and finance_fee_particulars.finance_fee_category_id='#{finance_fee_collection.fee_category_id}' and finance_fee_particulars.batch_id='#{particular_or_discount.batch_id}' and ((finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id=ff.student_id) or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id=ff.student_category_id) or (finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=ff.batch_id))) where ff.fee_collection_id=#{finance_fee_collection.id} and ff.#{receiver}=#{particular_or_discount.receiver_id} and ff.batch_id=#{particular_or_discount.batch_id}"
    ActiveRecord::Base.connection.execute(sql1)


    sql2="UPDATE finance_fees ff SET ff.balance=ff.balance-(select IFNULL((sum(ff.balance*(IF(fee_discounts.is_amount,(fee_discounts.discount/ff.balance),(fee_discounts.discount/100))))),0) from fee_discounts INNER JOIN collection_discounts on collection_discounts.fee_discount_id=fee_discounts.id where  collection_discounts.finance_fee_collection_id=#{finance_fee_collection.id} and fee_discounts.finance_fee_category_id='#{finance_fee_collection.fee_category_id}' and fee_discounts.batch_id='#{particular_or_discount.batch_id}' and fee_discounts.master_receiver_type<>'FinanceFeeParticular' and ((fee_discounts.receiver_type='Student' and fee_discounts.receiver_id=ff.student_id) or (fee_discounts.receiver_type='StudentCategory' and fee_discounts.receiver_id=ff.student_category_id) or (fee_discounts.receiver_type='Batch' and fee_discounts.receiver_id=ff.batch_id))) where ff.fee_collection_id=#{finance_fee_collection.id} and ff.#{receiver}=#{particular_or_discount.receiver_id} and ff.batch_id=#{particular_or_discount.batch_id}"
    ActiveRecord::Base.connection.execute(sql2)
    particular_wise_discount_subtraction_sql="UPDATE finance_fees ff SET ff.balance=ff.balance-(select IFNULL(sum((finance_fee_particulars.amount)*(if(fd.is_amount,fd.discount/finance_fee_particulars.amount,fd.discount/100))),0) from finance_fee_particulars inner join collection_discounts cd on cd.finance_fee_collection_id=#{finance_fee_collection.id} inner join fee_discounts fd on fd.id=cd.fee_discount_id and fd.master_receiver_type='FinanceFeeParticular' where finance_fee_particulars.id=fd.master_receiver_id and finance_fee_particulars.finance_fee_category_id='#{finance_fee_collection.fee_category_id}' and finance_fee_particulars.batch_id='#{particular_or_discount.batch_id}' and ((fd.receiver_type='Student' and fd.receiver_id=ff.student_id) or (fd.receiver_type='StudentCategory' and fd.receiver_id=ff.student_category_id) or (fd.receiver_type='Batch' and fd.receiver_id=ff.batch_id))) where ff.fee_collection_id=#{finance_fee_collection.id} and ff.#{receiver}=#{particular_or_discount.receiver_id} and ff.batch_id=#{particular_or_discount.batch_id}"
    ActiveRecord::Base.connection.execute(particular_wise_discount_subtraction_sql)
    paid_fees_deduction_sql="Update finance_fees ff set ff.balance=ff.balance-(select IFNULL(sum(finance_transactions.amount-finance_transactions.fine_amount),0) from finance_transactions where finance_transactions.finance_id=ff.id) where ff.fee_collection_id=#{finance_fee_collection.id} and ff.#{receiver}=#{particular_or_discount.receiver_id} and ff.batch_id=#{particular_or_discount.batch_id}"
    ActiveRecord::Base.connection.execute(paid_fees_deduction_sql)
    sql3="UPDATE finance_fees ff SET ff.is_paid=(ff.balance<=0) where ff.fee_collection_id=#{finance_fee_collection.id} and ff.#{receiver}=#{particular_or_discount.receiver_id} and ff.batch_id=#{particular_or_discount.batch_id}"
    ActiveRecord::Base.connection.execute(sql3)
  end

  private

  def check_discounts
    if FeeDiscount.find(:all,:conditions=>"is_deleted = '#{false}' and finance_fee_category_id=#{finance_fee_category_id} and batch_id=#{batch_id}").present? and (amount_changed? or name_changed?)
      errors.add_to_base(t('discounts_exists_for_this_category_cant_delete_or_edit_this_particular'))
      return false
    end
  end


end

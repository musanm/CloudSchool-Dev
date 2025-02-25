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

class FeeDiscount < ActiveRecord::Base

  belongs_to :finance_fee_category
  validates_presence_of :name,:finance_fee_category_id,:discount
  validates_numericality_of :discount, :allow_blank => true
  validates_inclusion_of :discount, :in => 0..100, :unless => :is_amount, :message => :amount_in_percentage_cant_exceed_100, :allow_blank => true
  belongs_to :receiver, :polymorphic => true
  belongs_to :master_receiver, :polymorphic => true
  has_many :finance_fee_collections, :through => :collection_discounts
  has_many :collection_discounts, :dependent => :destroy
  belongs_to :batch
  belongs_to :finance_fee_particular
  before_update :collection_exist
  before_validation :set_master_receiver

  def validate
    if master_receiver_type=='FinanceFeeParticular'
      particular=master_receiver
      if is_amount and discount.to_f > particular.amount.to_f
        errors.add_to_base(t('discount_cannot_be_greater_than_total_amount'))
      end
    end
    if batch_id.blank?
      if master_receiver_type=='FinanceFeeParticular'
        errors.add_to_base("#{t('particular')} #{t('cant_be_blank')}")
      else
        errors.add_to_base(t('batch_cant_be_blank'))
      end
    end
  end

  def total_payable
    payable = finance_fee_category.fee_particulars.active.map(&:amount).compact.flatten.sum
    payable
  end

  def set_master_receiver
    unless master_receiver_type=='FinanceFeeParticular'
      self.master_receiver=self.receiver
    end
  end


  def category_name
    c =StudentCategory.find(self.receiver_id)
    c.name unless c.nil?
  end

  def student_name
    s = Student.find_by_id(self.receiver_id)
    s ||= ArchivedStudent.find_by_former_id(self.receiver_id)
    s.present? ? "#{s.first_name} (#{s.admission_no})" : "N.A. (N.A.)"
  end

  def collection_exist
    unless is_deleted_changed?
      collection_ids=finance_fee_category.fee_collections.collect(&:id)
      if CollectionDiscount.find_by_fee_discount_id_and_finance_fee_collection_id(id, collection_ids)
        errors.add_to_base(t('collection_exists_for_this_category_cant_edit_this_discount'))
        return false
      else
        return true
      end
    end
  end

end

class Placementevent < ActiveRecord::Base
  has_many :placement_registrations ,:dependent=>:destroy
  has_many :students ,:through=>:placement_registrations

  validates_presence_of :title,:date

  named_scope :active,{:conditions=>{:is_active=>true}}
  named_scope :inactive,{:conditions=>{:is_active=>false}}

  def validate
    if self.date.to_date < Date.today
      errors.add_to_base :date_cant_be_past_date
      return false
    else
      return true
    end
  end
end

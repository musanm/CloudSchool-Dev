class PinNumber < ActiveRecord::Base
  belongs_to :pin_group
  validates_presence_of :pin_group_id,:number
  validates_numericality_of :number,:length => 14
  validates_uniqueness_of :number
  
  named_scope :active,{ :conditions => { :is_active => true }}
  named_scope :inactive,{ :conditions => { :is_active => false }}
  named_scope :registered,{ :conditions => { :is_registered => true }}
  
end

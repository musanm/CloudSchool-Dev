class InstantFeeCategory < ActiveRecord::Base
  validates_presence_of :name
  has_many :instant_fee_particulars,:dependent => :destroy
end

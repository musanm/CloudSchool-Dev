class AdditionalCharge < ActiveRecord::Base
   belongs_to :invoice
   validates_numericality_of :amount, :greater_than_or_equal_to => 0, :if => lambda {|attr| attr.amount.present?}, :message => "for additional charge is not valid" #, :on => [:create, :update]
end

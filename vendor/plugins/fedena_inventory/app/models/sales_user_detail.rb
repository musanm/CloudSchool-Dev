class SalesUserDetail < ActiveRecord::Base
  belongs_to :invoice 
  belongs_to :user
  validates_presence_of :username #, :on => [:create, :update]
  attr_accessor :issuer_name
end

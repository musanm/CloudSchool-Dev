class EmailSubscription < ActiveRecord::Base
  #validates_uniqueness_of :student_id
  belongs_to :student
end

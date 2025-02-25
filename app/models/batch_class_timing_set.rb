class BatchClassTimingSet < ActiveRecord::Base
  belongs_to :weekday
  belongs_to :class_timing_set
  named_scope :default,:conditions=>"batch_id IS NULL"

end

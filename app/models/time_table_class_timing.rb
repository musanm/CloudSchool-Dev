class TimeTableClassTiming < ActiveRecord::Base
  belongs_to :batch
  belongs_to :timetable
  belongs_to :class_timing_set
  has_many :time_table_class_timing_sets, :dependent => :destroy

  validates_presence_of :batch_id
end

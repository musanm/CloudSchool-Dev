class ClassTimingSet < ActiveRecord::Base
  validates_presence_of :name
  has_many :class_timings, :dependent => :destroy
  has_many :time_table_class_timings, :dependent => :destroy
  has_many :time_table_class_timing_sets, :dependent => :destroy
  has_many :batches
  before_destroy :check_dependency

  def check_dependency
    error=false
    if BatchClassTimingSet.find_by_class_timing_set_id(self.id).present?
      errors.add_to_base :batch_dependencies_exist
      error=true
    end
    if TimeTableClassTimingSet.find_by_class_timing_set_id(self.id).present?
      errors.add_to_base :timetable_dependencies_exist
      error=true
    end
    if error
      return false
    end
  end
end

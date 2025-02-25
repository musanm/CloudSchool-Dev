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

class TimetableEntry < ActiveRecord::Base
  belongs_to :timetable
  belongs_to :batch
  belongs_to :class_timing
  belongs_to :subject
  belongs_to :employee
  belongs_to :weekday
  delegate :day_of_week,:to=>:weekday
  has_many :timetable_swaps
  has_many :allocated_classrooms 
  before_destroy :attendace_and_timetable_swap_destroy

  def timetable_tracker_check
    if self.timetable_swaps.present?
      errors.add_to_base :timetable_tracker_dependency
      return false
    else
      return true
    end
  end

  def attendace_and_timetable_swap_destroy
    ActiveRecord::Base.transaction do
      subject_leaves=self.subject.subject_leaves.all(:conditions=>{:month_date=>self.timetable.start_date..self.timetable.end_date,:class_timing_id=>self.class_timing_id}).select{|s| s.month_date.to_date.wday==self.weekday_id}
      timetable_swaps=self.timetable_swaps
      classroom_allocations=self.allocated_classrooms
      error=false
      if timetable_swaps.present?
        timetable_swaps.each do |timetable_swap|
          subject_leave= SubjectLeave.all(:conditions=>{:month_date=>timetable_swap.date,:subject_id=>timetable_swap.subject_id,:class_timing_id=>self.class_timing_id,:batch_id=>self.batch_id}).select{|s| s.month_date.to_date.wday==self.weekday_id}
          unless error
            error=SubjectLeave.destroy(subject_leave.collect(&:id)) ? false : true
          end
        end
      end
      unless error
        error=SubjectLeave.destroy(subject_leaves.collect(&:id)) ? false : true
        error=TimetableSwap.destroy(timetable_swaps.collect(&:id)) ? false : true
        error=AllocatedClassroom.destroy(classroom_allocations.collect(&:id)) ? false : true
      end
      if error
        raise ActiveRecord::Rollback
        return false
      else
        return true
      end
    end
  end

end
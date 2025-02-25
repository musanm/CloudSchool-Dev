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
class Timetable < ActiveRecord::Base
  has_many :timetable_entries , :dependent=>:destroy
  has_many :time_table_weekdays, :dependent => :destroy
  has_many :time_table_class_timings, :dependent => :destroy
  has_one :classroom_allocation, :dependent => :destroy
  validates_presence_of :start_date
  validates_presence_of :end_date
  default_scope :order=>'start_date ASC'
  accepts_nested_attributes_for :time_table_weekdays
  accepts_nested_attributes_for :time_table_class_timings

  include CsvExportMod

  def duration
    (self.end_date - self.start_date).to_i + 1
  end

  #  def save_timetable_weekdays
  #    batches = Batch.active.all(:conditions=>["batches.start_date <= ? and batches.end_date >= ?", self.end_date,self.start_date])
  #    batches.each do |batch|
  #      if time_table_weekdays.find_all_by_batch_id(batch.id).blank?
  #        batch_weekday_set = batch.weekday_set_id.nil? ? WeekdaySet.common : batch.weekday_set
  #        time_table_weekdays.build(:batch_id => batch.id,:weekday_set_id => batch_weekday_set.try(:id))
  #      end
  #    end
  #  end

  def save_timetable_class_timings
    batches = Batch.active.all(:conditions=>["batches.start_date <= ? and batches.end_date >= ?", self.end_date,self.start_date])
    batches.each do |batch|
      if time_table_class_timings.find_all_by_batch_id(batch.id).blank?
        ttct=time_table_class_timings.build(:batch_id => batch.id)
        batch.batch_class_timing_sets.each do |cts|
          ttct.time_table_class_timing_sets.build(:batch_id=>batch.id,:class_timing_set_id=>cts.class_timing_set_id,:weekday_id=>cts.weekday_id)
        end
      end
    end
  end

  #  def save_timetable_weekdays_on_split(current_timetable)
  #    batches = Batch.active.all(:conditions=>["batches.start_date <= ? and batches.end_date >= ?", self.end_date,self.start_date]).collect(&:id)
  #    current_time_table_weekdays=current_timetable.time_table_weekdays
  #    current_time_table_weekdays.each do |weekdays|
  #      if batches.include? weekdays.batch_id
  #        self.time_table_weekdays.build(:batch_id => weekdays.batch_id,:weekday_set_id => weekdays.weekday_set_id)
  #      end
  #    end
  #  end

  def save_timetable_classtimings_on_split(current_timetable)
    batches = Batch.active.all(:conditions=>["batches.start_date <= ? and batches.end_date >= ?", self.end_date,self.start_date]).collect(&:id)
    current_time_table_class_timings=current_timetable.time_table_class_timings
    current_time_table_class_timings.each do |class_timings|
      current_timetable_class_timing_sets=class_timings.time_table_class_timing_sets
      if batches.include? class_timings.batch_id
        ttct=self.time_table_class_timings.build(:batch_id => class_timings.batch_id)
        current_timetable_class_timing_sets.each do |ttcts|
          ttct.time_table_class_timing_sets.build(:batch_id=>class_timings.batch_id,:class_timing_set_id=>ttcts.class_timing_set_id,:weekday_id=>ttcts.weekday_id)
        end
      end
    end
  end

  def copy_timetable_entries(current_timetable)
    entries=current_timetable.timetable_entries
    batches = Batch.active.all(:conditions=>["batches.start_date <= ? and batches.end_date >= ?", self.end_date,self.start_date]).collect(&:id)
    entries.each do |e|
      if batches.include? e.batch_id
        new_timetable_entry=e.clone
        new_timetable_entry.timetable_id=self.id
        new_timetable_entry.save
      end
    end
  end

  def dependency_delete(start_date,end_date,tt_id)
    logger = Logger.new("#{RAILS_ROOT}/log/time_table_dependacy_delete.log")
    logger.info "=========Start Deleting #{Time.now.strftime("%d%b%Y%H%M%S")}==========="
    logger.info SubjectLeave.destroy_all(:month_date=>start_date.beginning_of_day..end_date.end_of_day)
    logger.info TimetableSwap.destroy_all(:date=>start_date.beginning_of_day..end_date.end_of_day)
    classroom_alloc_ids = ClassroomAllocation.find(:all, :conditions => {:allocation_type => "date_specific"}).collect{|ca| ca.id}
    tte_ids = Timetable.find(tt_id).timetable_entries.collect{|tte| tte.id}
    AllocatedClassroom.delete_all(["date between ? and ? and classroom_allocation_id IN (?) and timetable_entry_id IN (?)",start_date,end_date,classroom_alloc_ids,tte_ids])
    logger.info "=========Deleted==========="
  end

  def self. tte_for_range(batch,date,subject,employee = nil)
    all_swaps = TimetableSwap.find(:all, :joins => :subject, :conditions => ["subjects.batch_id = ?", batch.id])
    all_time_table_class_timings = TimeTableClassTiming.find_all_by_batch_id(batch.id)
    range = register_range(batch,date)
    holidays = batch.holiday_event_dates
    entries = Array.new
    entered_timetables = all_time_table_class_timings.select{|attct| attct.batch_id == batch.id}.map(&:timetable_id)
    all_timetables = Timetable.find_all_by_id(entered_timetables,:conditions => ["((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?))",range.first,range.last,range.first,range.last,range.first,range.last])
    default_timetables = all_timetables.dup
    all_timetable_entries = TimetableEntry.find_all_by_timetable_id_and_subject_id(entered_timetables,subject.id)
    all_timetables.each do |timetable|
      time_table_class_timings=all_time_table_class_timings.select{|attct| attct.batch_id == batch.id and attct.timetable_id == timetable.id}.first
      class_timings =[]
      if time_table_class_timings.present?
        time_table_class_timings.time_table_class_timing_sets.each do |ttcts|
          class_timings += ttcts.class_timing_set.class_timings.map(&:id)
        end
      else
        []
      end
      weekdays = if time_table_class_timings.present?
        time_table_class_timings.time_table_class_timing_sets.map(&:weekday_id)
      else
        []
      end
      t_entries = all_timetable_entries.select{|atte| atte.timetable_id == timetable.id and atte.subject_id == subject.id and class_timings.include? atte.class_timing_id and weekdays.include? atte.weekday_id and atte.employee_id == employee.try(:id)} if (employee.present? and employee.user.admin == false and !employee.user.privileges.map(&:name).include? "StudentAttendanceRegister")#timetable.timetable_entries.find_all_by_subject_id_and_class_timing_id_and_weekday_id_and_employee_id(subject.id,class_timings,weekdays, employee.try(:id))
      t_entries ||= all_timetable_entries.select{|atte| atte.timetable_id == timetable.id and atte.subject_id == subject.id and class_timings.include? atte.class_timing_id and weekdays.include? atte.weekday_id}
      entries.push(t_entries)
    end
    entries = entries.flatten.compact
    timetable_ids=[]
    timetable_ids << Timetable.all(:joins=>:timetable_entries,:conditions=>['timetable_entries.id IN (?) AND ((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?))',all_swaps.collect(&:timetable_entry_id),range.first,range.last,range.first,range.last,range.first,range.last]).collect(&:id).uniq
    timetable_ids << entries.collect(&:timetable_id).uniq
    timetable_ids=timetable_ids.flatten.uniq

    hsh2=ActiveSupport::OrderedHash.new
    if timetable_ids.present?
      timetables = find(timetable_ids)
      hsh = ActiveSupport::OrderedHash.new
      entries_hash = entries.group_by(&:timetable_id)
      entries_hash.each do |k,val|
        hsh[k] = val.group_by(&:weekday_id)
      end
      timetables.each do |tt|
        ([tt.start_date,range.first].max..[tt.end_date,range.last].min).each do |d|
          swaps = all_swaps.select{|as| as.date == d.to_date and as.subject_id == subject.id and as.employee_id == employee.try(:id)} if (employee.present? and employee.user.admin == false and !employee.user.privileges.map(&:name).include? "StudentAttendanceRegister")
          swaps ||= all_swaps.select{|as| as.date == d.to_date and as.subject_id == subject.id}
          if swaps.present?
            hsh2[d] = swaps.map(&:timetable_entry)
          end
        end
        ([tt.start_date,range.first].max..[tt.end_date,range.last].min).each do |d|
          hsh2[d] = hsh[tt.id][d.wday] unless hsh[tt.id].nil?
          date_swaps = all_swaps.dup
          if date_swaps.present?
            swaps = date_swaps.select{|ds| ds.date == d.to_date and ds.subject_id == subject.id and ds.employee_id == employee.id} if (employee.present? and employee.user.admin == false and !employee.user.privileges.map(&:name).include? "StudentAttendanceRegister")
            swaps ||= date_swaps.select{|ds| ds.date == d.to_date and ds.subject_id == subject.id}
            hsh2[d] = hsh2[d].to_a.dup.reject{|x| date_swaps.any?{|s| s[:timetable_entry_id] == x.id and s[:date] == d}}
            hsh2[d] = (hsh2[d].to_a.dup + swaps.map(&:timetable_entry)).compact.flatten
          end
        end
      end
    else
      default_timetables.each do |tt|
        ([tt.start_date,range.first].max..[tt.end_date,range.last].min).each do |d|
          swaps = all_swaps.select{|as| as.date == d.to_date and as.subject_id == subject.id and as.employee_id == employee.id} if (employee.present? and employee.user.admin == false and !employee.user.privileges.map(&:name).include? "StudentAttendanceRegister")
          swaps ||= all_swaps.select{|as| as.date == d.to_date and as.subject_id == subject.id}
          if swaps.present?
            hsh2[d] = swaps.map(&:timetable_entry)
          end
        end
      end
    end
    holidays.each do |h|
      hsh2.delete(h)
    end
    hsh2
  end

  def self.tte_for_the_day(batch,date)
    entries = TimetableEntry.find(:all,:joins=>[:timetable, :class_timing],:conditions=>["(timetables.start_date <= ? AND timetables.end_date >= ?)  AND timetable_entries.batch_id = ? AND class_timings.is_deleted = false",date,date,batch.id], :order=>"class_timings.start_time")
    if entries.empty?
      today = []
    else
      today = entries.select{|a| a.weekday_id == date.wday}
    end
    today
  end

  def self.tte_for_the_weekday(batch,day)
    date = Date.today
    entries = TimetableEntry.find(:all,:joins=>[:timetable, :class_timing],:conditions=>["(timetables.start_date <= ? AND timetables.end_date >= ?)  AND timetable_entries.batch_id = ? AND class_timings.is_deleted = false",date,date,batch.id], :order=>"class_timings.start_time",:include=>[:employee,:class_timing,:subject])
    if entries.empty?
      today = []
    else
      today = entries.select{|a| a.weekday_id == day}
    end
    today
  end

  def self.employee_tte(employee,date)
    subjects = employee.subjects.select{|sub| sub.elective_group_id.nil?}
    electives = employee.subjects.select{|sub| sub.elective_group_id.present?}
    elective_subjects=electives.map{|x| x.elective_group.subjects.first}
    entries =[]
    entries += TimetableEntry.find(:all,:joins=>[:timetable, :class_timing],:conditions=>["(timetables.start_date <= ? AND timetables.end_date >= ?) AND timetable_entries.subject_id in (?) AND timetable_entries.employee_id = (?) AND class_timings.is_deleted = false",date,date,subjects,employee.id], :order=>"class_timings.start_time")
    entries += TimetableEntry.find(:all,:joins=>[:timetable, :class_timing],:conditions=>["(timetables.start_date <= ? AND timetables.end_date >= ?) AND timetable_entries.subject_id in (?)  AND class_timings.is_deleted = false",date,date,elective_subjects], :order=>"class_timings.start_time")
    if entries.empty?
      today=[]
    else
      today=entries.select{|a| a.weekday_id == date.wday}
    end
    today
  end

  def self.subject_tte(subject_id,date)
    subject=Subject.find(subject_id)
    unless subject.elective_group.nil?
      subject=subject.elective_group.subjects.first
    end
    entries = TimetableEntry.find(:all,:joins=>[:timetable, :class_timing],:conditions=>["(timetables.start_date <= ? AND timetables.end_date >= ?)  AND timetable_entries.subject_id = ? AND class_timings.is_deleted = false AND employee_id=?",date,date,subject.id,Authorization.current_user.employee_record.id],:include=>:timetable_swaps)
    entries=entries.reject{|e| e.timetable_swaps.present?}
    timetable_swaps=subject.timetable_swaps.all(:conditions=>{:date=>date},:include=>:timetable_entry)
    timetable_swaps.each{|ts| entries << ts.timetable_entry} if timetable_swaps.present?
    if entries.empty?
      today=[]
    else
      today=entries.select{|a| a.weekday_id == date.wday}
    end
    today
  end

  def self.register_range(batch,date)
    start=[]
    start<<batch.start_date.to_date
    start<<date.beginning_of_month.to_date
    start<<find(:first,:select=>:start_date,:order=>:start_date).start_date.to_date
    stop=[]
    stop<<batch.end_date.to_date
    stop<<date.end_of_month.to_date
    stop<<find(:last,:select=>:end_date,:order=>:end_date).end_date.to_date
    range=(start.max..stop.min).to_a - batch.holiday_event_dates
  end

  def self.fetch_timetable_data(params)
    timetable_data params
  end
end
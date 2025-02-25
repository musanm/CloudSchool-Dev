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
include FeeDefaultersSqlGenerator
class Batch < ActiveRecord::Base
  GRADINGTYPES = {"1"=>"GPA","2"=>"CWA","3"=>"CCE","4"=>"ICSE"}

  belongs_to :course
  belongs_to :weekday_set
  belongs_to :class_timing_set

  has_many :students
  accepts_nested_attributes_for :students
  has_many :grouped_exam_reports
  has_many :grouped_batches
  has_many :archived_students
  has_many :grading_levels, :conditions => { :is_deleted => false }
  has_many :subjects, :conditions => { :is_deleted => false }
  has_many :employees_subjects, :through =>:subjects
  has_many :exam_groups
  has_many :fee_category , :class_name => "FinanceFeeCategory"
  has_many :elective_groups
  has_many :finance_fee_collections
  has_many :finance_transactions, :through => :students
  has_many :batch_events
  has_many :events , :through =>:batch_events
  has_many :batch_fee_discounts , :foreign_key => 'receiver_id'
  has_many :student_category_fee_discounts , :foreign_key => 'receiver_id'
  has_many :attendances
  has_many :subject_leaves
  has_many :timetable_entries
  has_many :cce_reports
  has_many :assessment_scores
  has_many :class_timings
  has_many :cce_exam_category ,:through=>:exam_groups
  has_many :fa_groups ,:through=>:subjects
  has_many :time_table_class_timings
  has_many :finance_transactions
  has_many :finance_fees
  has_many :batch_class_timing_sets
  has_many :term_exams
  
  has_many :batch_students
  has_and_belongs_to_many :employees,:join_table => "batch_tutors"
  has_many :batch_tutors
  has_many :finance_fee_categories,:through=>:category_batches
  has_many :category_batches
  has_many :finance_fee_particulars
  has_many :finance_fee_collections,:through=>:fee_collection_batches, :conditions => { :is_deleted => false }
  has_many :fee_collection_batches
  has_many :fee_discounts
  has_many :icse_reports
  has_many :ia_scores
  has_many :attendance_weekday_sets
  delegate :course_name,:section_name, :code, :to => :course
  delegate :grading_type,:icse_enabled?,:cce_enabled?, :observation_groups, :cce_weightages, :to=>:course

  validates_presence_of :name, :start_date, :end_date

  attr_accessor :job_type
  accepts_nested_attributes_for :attendance_weekday_sets
  accepts_nested_attributes_for :batch_class_timing_sets,:allow_destroy=>true

  named_scope :active,{ :conditions => { :is_deleted => false, :is_active => true },:joins=>:course,:select=>"`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:order=>"course_full_name",:include=>:course}
  named_scope :inactive,{ :conditions => { :is_deleted => false, :is_active => false },:joins=>:course,:select=>"`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:order=>"course_full_name"}
  named_scope :deleted,{:conditions => { :is_deleted => true },:joins=>:course,:select=>"`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:order=>"course_full_name"}
  named_scope :cce, {:select => "batches.*",:joins => :course,:conditions=>["courses.grading_type = #{GRADINGTYPES.invert["CCE"]} and batches.is_deleted=#{false} and batches.is_active=#{true}"],:order=>:code}
  named_scope :icse, {:select => "batches.*",:joins => :course,:conditions=>["courses.grading_type = #{GRADINGTYPES.invert["ICSE"]} and batches.is_deleted=#{false} and batches.is_active=#{true}"],:order=>:code}
  before_update :attendance_validation
  before_update :timetable_entry_validation
  before_update :weekday_set_updation
  after_update :attendance_weekday_set_updation
  before_create :default_weekdayset_and_attendance_weekday_sets
  after_create :create_batch_class_timing_set_entry

  validates_format_of :roll_number_prefix, :with => /^[A-Z0-9_-]*$/i 
  validates_length_of :roll_number_prefix, :maximum => 6, :allow_blank => true

  def roll_number_generated?
    return Student.find(:all, :conditions => ["batch_id = ? and roll_number != ?" , self.id ,""], :select =>"roll_number").present?
  end

  def get_roll_number_prefix
    self.roll_number_prefix || self.course.roll_number_prefix
  end

  def get_roll_number_suffix
    batch_strength = self.students.count
    suffix_base = batch_strength.to_s.length
    "1".rjust(suffix_base+1, '0')
  end
  
  def validate
    errors.add(:start_date, :should_be_before_end_date) \
      if self.start_date > self.end_date \
      if self.start_date and self.end_date
  end


  def create_batch_class_timing_set_entry
    BatchClassTimingSet.default.each do |bcts|
      BatchClassTimingSet.create(:batch_id=>self.id,:weekday_id=>bcts.weekday_id,:class_timing_set_id=>bcts.class_timing_set_id)
    end
  end

  def default_weekdayset_and_attendance_weekday_sets
    self.weekday_set = WeekdaySet.common
    self.attendance_weekday_sets.build(:weekday_set_id=>self.weekday_set_id,:start_date=>self.start_date,:end_date=>self.end_date)
  end

  def weekday_set_updation
    if ( self.start_date_changed? or self.end_date_changed? )
      last_week_day_sets=self.attendance_weekday_sets.find(:first,:conditions=>["end_date >= ? AND start_date <=?",self.start_date,self.end_date],:order=>"id DESC")
      last_week_day_sets= last_week_day_sets.present? ? last_week_day_sets : self.attendance_weekday_sets.first
      self.weekday_set_id=last_week_day_sets.weekday_set_id
    end
  end

  def attendance_weekday_set_updation
    if ( self.start_date_changed? or self.end_date_changed? )
      valid_week_day_sets=self.attendance_weekday_sets.all(:conditions=>["end_date >= ? AND start_date <=?",self.start_date,self.end_date],:order=>"id ASC")
      valid_week_day_sets=valid_week_day_sets.present? ? valid_week_day_sets : self.attendance_weekday_sets.first.to_a
      removable_week_days=self.attendance_weekday_sets.all(:conditions=>["id NOT IN (?)",valid_week_day_sets.collect(&:id)])
      first_attendance_weekday_set=valid_week_day_sets.first
      first_attendance_weekday_set.update_attributes(:start_date=>self.start_date)
      last_attendance_weekday_set=valid_week_day_sets.last
      last_attendance_weekday_set.update_attributes(:end_date=>self.end_date)
      AttendanceWeekdaySet.destroy(removable_week_days)
    end
  end
  
  def timetable_entry_validation
    if self.timetable_entries.present? and ( self.start_date_changed? or self.end_date_changed? )
      first_timetable_date=self.timetable_entries.find(:first,:select=>"timetables.start_date,timetables.id",:joins=>[:timetable],:order=>"timetables.start_date ASC").start_date.to_date
      last_timetable_date=self.timetable_entries.find(:first,:select=>"timetables.end_date,timetables.id",:joins=>[:timetable],:order=>"timetables.end_date DESC").end_date.to_date
      if self.start_date.to_date <=  first_timetable_date and self.end_date.to_date >= last_timetable_date
        true
      else
        errors.add_to_base :timetable_marked
        false
      end
    else
      return true
    end
  end

  def attendance_validation
    if self.attendances.present? and ( self.start_date_changed? or self.end_date_changed? )
      first_attendance_date= self.attendances.find(:first,:order=>"month_date ASC").month_date
      last_attendance_date= self.attendances.find(:first,:order=>"month_date DESC").month_date
      if self.start_date.to_date <=  first_attendance_date and self.end_date.to_date >= last_attendance_date
        true
      else
        errors.add_to_base :attendance_marked
        false
      end
    else
      return true
    end
  end

  def graduated_students
    prev_students = []
    self.batch_students.map{|bs| ((prev_students << bs.student) if bs.student) }
    prev_students
  end

  def full_name
    "#{code} - #{name}"
  end

  def course_section_name
    "#{course_name} - #{section_name}"
  end

  def inactivate
    update_attribute(:is_deleted, true)
    self.employees_subjects.destroy_all
  end

  def activate
    update_attribute(:is_deleted, false)
    update_attribute(:is_active, true)
  end

  def grading_level_list
    levels = self.grading_levels
    levels.empty? ? GradingLevel.default : levels
  end

  def fee_collection_dates
    FinanceFeeCollection.find_all_by_batch_id(self.id,:conditions => "is_deleted = false")
  end

  def all_students
    Student.find_all_by_batch_id(self.id)
  end

  def normal_batch_subject
    Subject.find_all_by_batch_id(self.id,:conditions=>["elective_group_id IS NULL AND is_deleted = false"], :include => [:timetable_entries,:exams])
  end

  def elective_batch_subject(elect_group)
    Subject.find_all_by_batch_id_and_elective_group_id(self.id,elect_group,:conditions=>["elective_group_id IS NOT NULL AND is_deleted = false"], :include => [:timetable_entries,:exams])
  end

  def all_elective_subjects
    elective_groups.map(&:subjects).compact.flatten.select{|subject| subject.is_deleted == false}
  end

  def has_own_weekday
    weekday_set.present?
  end

  def allow_exam_acess(user)
    flag = true
    if user.employee? and user.role_symbols.include?(:subject_exam)
      flag = false if user.employee_record.subjects.all(:conditions=>"batch_id = '#{self.id}'").blank?
    end
    return flag
  end

  def is_a_holiday_for_batch?(day)
    return true if Event.holidays.count(:all, :conditions => ["start_date <=? AND end_date >= ?", day, day] ) > 0
    false
  end

  def holiday_event_dates
    @common_holidays ||= Event.holidays.is_common
    @batch_holidays=events.holidays
    all_holiday_events = @batch_holidays+@common_holidays
    event_holidays = []
    all_holiday_events.each do |event|
      event_holidays+=event.dates
    end
    return event_holidays #array of holiday event dates
  end

  def return_holidays(start_date,end_date)
    @common_holidays ||= Event.holidays.is_common
    @batch_holidays = self.events(:all,:conditions=>{:is_holiday=>true})
    all_holiday_events = @batch_holidays + @common_holidays
    all_holiday_events.reject!{|h| !(h.start_date>=start_date and h.end_date<=end_date)}
    event_holidays = []
    all_holiday_events.each do |event|
      event_holidays += event.dates
    end
    return event_holidays #array of holiday event dates
  end

  def find_working_days(start_date,end_date)
    start = []
    start << self.start_date.to_date
    start << start_date.to_date
    stop = []
    stop << self.end_date.to_date
    stop << end_date.to_date
    all_days = start.max..stop.min
    weekdays = weekday_set.nil? ? WeekdaySet.common.weekday_ids : weekday_set.weekday_ids
    holidays = return_holidays(start_date,end_date)
    non_holidays = all_days.to_a-holidays
    range = non_holidays.select{|d| weekdays.include? d.wday}
    return range
  end

  def total_days(date)
    start = []
    start << self.start_date.to_date
    start << date.beginning_of_month.to_date
    stop = []
    stop << self.end_date.to_date
    stop << date.end_of_month.to_date
    all_days = start.max..stop.min
    return all_days
  end

  def working_days(date)
    holidays = holiday_event_dates
    range=[]
    start = []
    start << self.start_date.to_date
    start << date.beginning_of_month.to_date
    stop = []
    stop << self.end_date.to_date
    stop << date.end_of_month.to_date
    total_weekday_sets=self.attendance_weekday_sets.all(:conditions=>["start_date <= ? and end_date >=? ",stop.min,start.max])
    total_weekday_sets.each do |weekdayset|
      week_day_start=[]
      week_day_end=[]
      week_day_start << weekdayset.start_date.to_date
      week_day_start << date.beginning_of_month.to_date
      week_day_end << weekdayset.end_date.to_date
      week_day_end << date.end_of_month.to_date
      weekdayset_date_range=week_day_start.max..week_day_end.min
      weekday_ids=weekdayset.weekday_set.weekday_ids
      non_holidays=weekdayset_date_range.to_a-holidays
      range << non_holidays.select{|d| weekday_ids.include? d.wday}
    end
    range=range.flatten
    return range
  end

  def date_range_working_days(start_date,end_date)
    holidays = holiday_event_dates
    range=[]
    total_weekday_sets=self.attendance_weekday_sets.all(:conditions=>["start_date <= ? and end_date >=? ",end_date.to_date,start_date.to_date])
    total_weekday_sets.each do |weekdayset|
      week_day_start=[]
      week_day_end=[]
      week_day_start << weekdayset.start_date.to_date
      week_day_start << start_date.to_date
      week_day_end << weekdayset.end_date.to_date
      week_day_end << end_date.to_date
      weekdayset_date_range=week_day_start.max..week_day_end.min
      weekday_ids=weekdayset.weekday_set.weekday_ids
      non_holidays=weekdayset_date_range.to_a-holidays
      range << non_holidays.select{|d| weekday_ids.include? d.wday}
    end
    range=range.flatten
    return range
  end

  def academic_days
    holidays = holiday_event_dates
    range=[]
    date=Configuration.default_time_zone_present_time.to_date
    end_date_take = (end_date.to_date < date) ? end_date.to_date : date.to_date
    total_weekday_sets=self.attendance_weekday_sets.all(:conditions=>["start_date <= ? and end_date >=? ",end_date_take,self.start_date.to_date])
    total_weekday_sets.each do |weekdayset|
      week_day_start=weekdayset.start_date.to_date
      week_day_end= (weekdayset.end_date < end_date_take) ? weekdayset.end_date.to_date : end_date_take.to_date
      weekdayset_date_range=week_day_start..week_day_end
      weekday_ids=weekdayset.weekday_set.weekday_ids
      non_holidays=weekdayset_date_range.to_a-holidays
      range << non_holidays.select{|d| weekday_ids.include? d.wday}
    end
    range=range.flatten
    return range
  end

  def total_subject_hours(subject_id)
    days=academic_days
    count=0
    unless subject_id == 0
      subject=Subject.find subject_id
      days.each do |d|
        count=count+ Timetable.subject_tte(subject_id, d).count
      end
    else
      days.each do |d|
        count=count+ Timetable.tte_for_the_day(self,d).count
      end
    end
    count
  end

  def find_batch_rank
    @students = Student.find_all_by_batch_id(self.id)
    @grouped_exams = GroupedExam.find_all_by_batch_id(self.id)
    ordered_scores = []
    student_scores = []
    ranked_students = []
    @students.each do|student|
      score = GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(student.id,student.batch_id,"c")
      marks = 0
      unless score.nil?
        marks = score.marks
      end
      ordered_scores << marks
      student_scores << [student.id,marks]
    end
    ordered_scores = ordered_scores.compact.uniq.sort.reverse
    @students.each do |student|
      marks = 0
      student_scores.each do|student_score|
        if student_score[0]==student.id
          marks = student_score[1]
        end
      end
      ranked_students << [(ordered_scores.index(marks) + 1),marks,student.id,student]
    end
    ranked_students = ranked_students.sort
  end

  def find_attendance_rank(start_date,end_date)
    @students = Student.find_all_by_batch_id(self.id)
    ranked_students=[]
    unless @students.empty?
      working_days = self.find_working_days(start_date,end_date).count
      unless working_days == 0
        ordered_percentages = []
        student_percentages = []
        @students.each do|student|
          leaves = Attendance.find(:all,:conditions=>["student_id = ? and month_date >= ? and month_date <= ?",student.id,start_date,end_date])
          absents = 0
          unless leaves.empty?
            leaves.each do|leave|
              if leave.forenoon == true and leave.afternoon == true
                absents = absents + 1
              else
                absents = absents + 0.5
              end
            end
          end
          percentage = ((working_days.to_f - absents).to_f/working_days.to_f)*100
          ordered_percentages << percentage
          student_percentages << [student.id,(working_days - absents),percentage]
        end
        ordered_percentages = ordered_percentages.compact.uniq.sort.reverse
        @students.each do |student|
          stu_percentage = 0
          attended = 0
          working_days
          student_percentages.each do|student_percentage|
            if student_percentage[0]==student.id
              attended = student_percentage[1]
              stu_percentage = student_percentage[2]
            end
          end
          ranked_students << [(ordered_percentages.index(stu_percentage) + 1),stu_percentage,student.first_name,working_days,attended,student]
        end
      end
    end
    return ranked_students
  end

  def gpa_enabled?
    Configuration.has_gpa? and self.grading_type=="1"
  end

  def cwa_enabled?
    Configuration.has_cwa? and self.grading_type=="2"
  end

  def normal_enabled?
    self.grading_type.nil? or self.grading_type=="0"
  end

  def generate_batch_reports
    grading_type = self.grading_type
    students = self.students
    grouped_exams = self.exam_groups.reject{|e| !GroupedExam.exists?(:batch_id=>self.id, :exam_group_id=>e.id)}
    unless grouped_exams.empty?
      subjects = self.subjects(:conditions=>{:is_deleted=>false})
      unless students.empty?
        st_scores = GroupedExamReport.find_all_by_student_id_and_batch_id(students,self.id)
        unless st_scores.empty?
          st_scores.map{|sc| sc.destroy}
        end
        subject_marks=[]
        exam_marks=[]
        grouped_exams.each do|exam_group|
          subjects.each do|subject|
            exam = Exam.find_by_exam_group_id_and_subject_id(exam_group.id,subject.id)
            unless exam.nil?
              students.each do|student|
                is_assigned_elective = 1
                unless subject.elective_group_id.nil?
                  assigned = StudentsSubject.find_by_student_id_and_subject_id(student.id,subject.id)
                  if assigned.nil?
                    is_assigned_elective=0
                  end
                end
                unless is_assigned_elective==0
                  percentage = 0
                  marks = 0
                  score = ExamScore.find_by_exam_id_and_student_id(exam.id,student.id)
                  if grading_type.nil? or self.normal_enabled?
                    unless score.nil? or score.marks.nil?
                      percentage = exam.maximum_marks.to_f==0 ? 0.0 : (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
                      marks = score.marks.to_f
                    end
                  elsif self.gpa_enabled?
                    unless score.nil? or score.grading_level_id.nil?
                      percentage = (score.grading_level.credit_points.to_f)*((exam_group.weightage.to_f)/100)
                      marks = (score.grading_level.credit_points.to_f) * (subject.credit_hours.to_f)
                    end
                  elsif self.cwa_enabled?
                    unless score.nil? or score.marks.nil?
                      percentage = exam.maximum_marks.to_f==0 ? 0.0 : (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
                      marks = exam.maximum_marks.to_f==0 ? 0.0 : (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*(subject.credit_hours.to_f)
                    end
                  end
                  flag=0
                  subject_marks.each do|s|
                    if s[0]==student.id and s[1]==subject.id
                      s[2] << percentage.to_f
                      flag=1
                    end
                  end

                  unless flag==1
                    subject_marks << [student.id,subject.id,[percentage.to_f]]
                  end
                  e_flag=0
                  exam_marks.each do|e|
                    if e[0]==student.id and e[1]==exam_group.id
                      e[2] << marks.to_f
                      if grading_type.nil? or self.normal_enabled?
                        e[3] << exam.maximum_marks.to_f
                      elsif self.gpa_enabled? or self.cwa_enabled?
                        e[3] << subject.credit_hours.to_f
                      end
                      e_flag = 1
                    end
                  end
                  unless e_flag==1
                    if grading_type.nil? or self.normal_enabled?
                      exam_marks << [student.id,exam_group.id,[marks.to_f],[exam.maximum_marks.to_f]]
                    elsif self.gpa_enabled? or self.cwa_enabled?
                      exam_marks << [student.id,exam_group.id,[marks.to_f],[subject.credit_hours.to_f]]
                    end
                  end
                end
              end
            end
          end
        end
        subject_marks.each do|subject_mark|
          student_id = subject_mark[0]
          subject_id = subject_mark[1]
          marks = subject_mark[2].sum.to_f
          prev_marks = GroupedExamReport.find_by_student_id_and_subject_id_and_batch_id_and_score_type(student_id,subject_id,self.id,"s")
          unless prev_marks.nil?
            prev_marks.update_attributes(:marks=>marks)
          else
            GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>marks,:score_type=>"s",:subject_id=>subject_id)
          end
        end
        exam_totals = []
        exam_marks.each do|exam_mark|
          student_id = exam_mark[0]
          exam_group = ExamGroup.find(exam_mark[1])
          score = exam_mark[2].sum
          max_marks = exam_mark[3].sum
          tot_score = 0
          percent = 0
          unless max_marks.to_f==0
            if grading_type.nil? or self.normal_enabled?
              tot_score = (((score.to_f)/max_marks.to_f)*100)
              percent = (((score.to_f)/max_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
            elsif self.gpa_enabled? or self.cwa_enabled?
              tot_score = ((score.to_f)/max_marks.to_f)
              percent = ((score.to_f)/max_marks.to_f)*((exam_group.weightage.to_f)/100)
            end
          end
          prev_exam_score = GroupedExamReport.find_by_student_id_and_exam_group_id_and_score_type(student_id,exam_group.id,"e")
          unless prev_exam_score.nil?
            prev_exam_score.update_attributes(:marks=>tot_score)
          else
            GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>tot_score,:score_type=>"e",:exam_group_id=>exam_group.id)
          end
          exam_flag=0
          exam_totals.each do|total|
            if total[0]==student_id
              total[1] << percent.to_f
              exam_flag=1
            end
          end
          unless exam_flag==1
            exam_totals << [student_id,[percent.to_f]]
          end
        end
        exam_totals.each do|exam_total|
          student_id=exam_total[0]
          total=exam_total[1].sum.to_f
          prev_total_score = GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(student_id,self.id,"c")
          unless prev_total_score.nil?
            prev_total_score.update_attributes(:marks=>total)
          else
            GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>total,:score_type=>"c")
          end
        end
      end
    end
  end

  def generate_previous_batch_reports
    grading_type = self.grading_type
    students=[]
    batch_students= BatchStudent.find_all_by_batch_id(self.id)
    batch_students.each do|bs|
      stu = Student.find_by_id(bs.student_id)
      students.push stu unless stu.nil?
    end
    grouped_exams = self.exam_groups.reject{|e| !GroupedExam.exists?(:batch_id=>self.id, :exam_group_id=>e.id)}
    unless grouped_exams.empty?
      subjects = self.subjects(:conditions=>{:is_deleted=>false})
      unless students.empty?
        st_scores = GroupedExamReport.find_all_by_student_id_and_batch_id(students,self.id)
        unless st_scores.empty?
          st_scores.map{|sc| sc.destroy}
        end
        subject_marks=[]
        exam_marks=[]
        grouped_exams.each do|exam_group|
          subjects.each do|subject|
            exam = Exam.find_by_exam_group_id_and_subject_id(exam_group.id,subject.id)
            unless exam.nil?
              students.each do|student|
                is_assigned_elective = 1
                unless subject.elective_group_id.nil?
                  assigned = StudentsSubject.find_by_student_id_and_subject_id(student.id,subject.id)
                  if assigned.nil?
                    is_assigned_elective=0
                  end
                end
                unless is_assigned_elective==0
                  percentage = 0
                  marks = 0
                  score = ExamScore.find_by_exam_id_and_student_id(exam.id,student.id)
                  if grading_type.nil? or self.normal_enabled?
                    unless score.nil? or score.marks.nil?
                      percentage = exam.maximum_marks.to_f==0 ? 0.0 : (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
                      marks = score.marks.to_f
                    end
                  elsif self.gpa_enabled?
                    unless score.nil? or score.grading_level_id.nil?
                      percentage = (score.grading_level.credit_points.to_f)*((exam_group.weightage.to_f)/100)
                      marks = (score.grading_level.credit_points.to_f) * (subject.credit_hours.to_f)
                    end
                  elsif self.cwa_enabled?
                    unless score.nil? or score.marks.nil?
                      percentage = exam.maximum_marks.to_f==0 ? 0.0 : (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
                      marks = exam.maximum_marks.to_f==0 ? 0.0 : (((score.marks.to_f)/exam.maximum_marks.to_f)*100)*(subject.credit_hours.to_f)
                    end
                  end
                  flag=0
                  subject_marks.each do|s|
                    if s[0]==student.id and s[1]==subject.id
                      s[2] << percentage.to_f
                      flag=1
                    end
                  end

                  unless flag==1
                    subject_marks << [student.id,subject.id,[percentage.to_f]]
                  end
                  e_flag=0
                  exam_marks.each do|e|
                    if e[0]==student.id and e[1]==exam_group.id
                      e[2] << marks.to_f
                      if grading_type.nil? or self.normal_enabled?
                        e[3] << exam.maximum_marks.to_f
                      elsif self.gpa_enabled? or self.cwa_enabled?
                        e[3] << subject.credit_hours.to_f
                      end
                      e_flag = 1
                    end
                  end
                  unless e_flag==1
                    if grading_type.nil? or self.normal_enabled?
                      exam_marks << [student.id,exam_group.id,[marks.to_f],[exam.maximum_marks.to_f]]
                    elsif self.gpa_enabled? or self.cwa_enabled?
                      exam_marks << [student.id,exam_group.id,[marks.to_f],[subject.credit_hours.to_f]]
                    end
                  end
                end
              end
            end
          end
        end
        subject_marks.each do|subject_mark|
          student_id = subject_mark[0]
          subject_id = subject_mark[1]
          marks = subject_mark[2].sum.to_f
          prev_marks = GroupedExamReport.find_by_student_id_and_subject_id_and_batch_id_and_score_type(student_id,subject_id,self.id,"s")
          unless prev_marks.nil?
            prev_marks.update_attributes(:marks=>marks)
          else
            GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>marks,:score_type=>"s",:subject_id=>subject_id)
          end
        end
        exam_totals = []
        exam_marks.each do|exam_mark|
          student_id = exam_mark[0]
          exam_group = ExamGroup.find(exam_mark[1])
          score = exam_mark[2].sum
          max_marks = exam_mark[3].sum
          if grading_type.nil? or self.normal_enabled?
            tot_score = (((score.to_f)/max_marks.to_f)*100)
            percent = (((score.to_f)/max_marks.to_f)*100)*((exam_group.weightage.to_f)/100)
          elsif self.gpa_enabled? or self.cwa_enabled?
            tot_score = ((score.to_f)/max_marks.to_f)
            percent = ((score.to_f)/max_marks.to_f)*((exam_group.weightage.to_f)/100)
          end
          prev_exam_score = GroupedExamReport.find_by_student_id_and_exam_group_id_and_score_type(student_id,exam_group.id,"e")
          unless prev_exam_score.nil?
            prev_exam_score.update_attributes(:marks=>tot_score)
          else
            GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>tot_score,:score_type=>"e",:exam_group_id=>exam_group.id)
          end
          exam_flag=0
          exam_totals.each do|total|
            if total[0]==student_id
              total[1] << percent.to_f
              exam_flag=1
            end
          end
          unless exam_flag==1
            exam_totals << [student_id,[percent.to_f]]
          end
        end
        exam_totals.each do|exam_total|
          student_id=exam_total[0]
          total=exam_total[1].sum.to_f
          prev_total_score = GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(student_id,self.id,"c")
          unless prev_total_score.nil?
            prev_total_score.update_attributes(:marks=>total)
          else
            GroupedExamReport.create(:batch_id=>self.id,:student_id=>student_id,:marks=>total,:score_type=>"c")
          end
        end
      end
    end
  end

  def teaches_in_this_batch?
    cur_user=Authorization.current_user
    if cur_user.has_required_subjects? and cur_user.has_required_batches?
      sub_ids=cur_user.employee_record.subjects.collect(&:id)
      if cur_user.employee_record.batch_ids.include?(self.id)
        unless (self.subject_ids & sub_ids).empty?
          return true
        end
      end
    end
    return false
  end
  
  def has_employee_privilege
    Authorization.current_user.has_common_remark_privilege(id)
  end

  def can_view_day_wise_report?
    cur_user = Authorization.current_user
    attendance_type = Configuration.get_config_value('StudentAttendanceType')
    if cur_user.admin? or (cur_user.employee? and cur_user.privileges.map{|p| p.name}.include?('StudentAttendanceView'))
      return attendance_type == "Daily"
    else
      return (cur_user.employee_record.batch_ids.include? id and attendance_type == "Daily")
    end
  end

  def subject_hours(starting_date,ending_date,subject_id)
    entries = Array.new
    timetables = Timetable.all(:conditions => ["((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?))", starting_date, ending_date,starting_date, ending_date,starting_date, ending_date], :include => :timetable_entries).reject{|tt| tt.timetable_entries.select{|tte| tte.batch_id == id}.blank?}
    subject = Subject.find(subject_id, :include => [:batch, :elective_group]) unless subject_id == 0
    batch = subject.batch unless subject.nil? and subject_id == 0
    elective_group = subject.elective_group unless subject.nil? and subject_id == 0
    elective_group_subjects = elective_group.nil? ? Array.new : elective_group.subjects
    all_timetable_class_timings = TimeTableClassTiming.find_all_by_batch_id(id)
    all_timetable_entries = TimetableEntry.find_all_by_timetable_id_and_batch_id(timetables.map(&:id),id)
    all_timetable_swaps = TimetableSwap.find(:all, :joins => :subject, :conditions => ["subjects.batch_id = ?", batch.id]) unless batch.nil? and subject_id == 0
    all_timetable_swaps ||= TimetableSwap.find(:all, :joins => :subject, :conditions => ["subjects.batch_id = ?", id])
    configuration_time = Configuration.default_time_zone_present_time.to_date
    timetables.each do |timetable|
      time_table_class_timing = all_timetable_class_timings.select{|attct| attct.timetable_id == timetable.id}.first
      class_timings=[]
      if(time_table_class_timing.present?)
        time_table_class_timing.time_table_class_timing_sets.each do |ttcts|
          class_timings += ttcts.class_timing_set.class_timings.map(&:id)
        end
        weekdays = time_table_class_timing.time_table_class_timing_sets.map(&:weekday_id)
        unless subject_id == 0
          unless elective_group.nil?
            subject = elective_group_subjects
          end
          t_entries = all_timetable_entries.select{|ate| class_timings.include? ate.class_timing_id and weekdays.include? ate.weekday_id and subject.to_a.include? ate.subject and ate.timetable_id == timetable.id}
        else
          t_entries = all_timetable_entries.select{|ate| class_timings.include? ate.class_timing_id and weekdays.include? ate.weekday_id and ate.timetable_id == timetable.id}
        end
        entries.push(t_entries)
      end
    end
    timetable_entries = entries.flatten.compact.dup
    entries = entries.flatten.compact.group_by(&:timetable_id)
    timetable_ids = entries.keys
    hsh2 = Hash.new
    holidays = holiday_event_dates
    unless timetable_ids.nil?
      timetables = timetables.select{|tt| timetable_ids.include? tt.id}
      hsh = Hash.new
      entries.each do |k,val|
        hsh[k] = val.group_by(&:weekday_id)
      end
      timetables.each do |tt|
        ([starting_date,start_date.to_date,tt.start_date].max..[tt.end_date,end_date.to_date,ending_date,configuration_time].min).each do |d|
          hsh2[d] = hsh[tt.id][d.wday].to_a.dup if hsh[tt.id].present?
        end
      end
    end
    holidays.each do |h|
      hsh2.delete(h)
    end
    unless subject_id == 0
      swapped_timetable_entries = all_timetable_swaps.select{|attsws| timetable_entries.map(&:id).include? attsws.timetable_entry_id}
      subject_swapped_entries = all_timetable_swaps.select{|sse| sse.subject_id == subject_id}
      swapped_timetable_entries.each do |swapped_timetable_entry|
        hsh2[swapped_timetable_entry.date.to_date].to_a.each do |hash_entry|
          if hash_entry.subject_id != swapped_timetable_entry.subject_id and hash_entry.id == swapped_timetable_entry.timetable_entry_id
            hash_entries = hsh2[swapped_timetable_entry.date.to_date].dup
            hash_entries.delete(hash_entry)
            hsh2[swapped_timetable_entry.date.to_date] = hash_entries.dup
          end
        end
      end

      subject_swapped_entries.each do |subject_swapped_entry|
        hsh2[subject_swapped_entry.date.to_date].to_a << all_timetable_entries.select{|atte| atte.id == subject_swapped_entry.timetable_entry_id}
        hsh2[subject_swapped_entry.date.to_date].to_a.compact
      end
      if hsh2.empty? and subject_swapped_entries.present?
        subject_swapped_entries.each do |subject_swapped_entry|
          hs={subject_swapped_entry.date.to_date => subject_swapped_entry.timetable_entry}
          hsh2.merge!(hs)
        end
      end
    end
    hsh2
  end

  def create_coscholastic_reports
    report_hash={}
    observation_groups.scoped(:include=>[{:observations=>:assessment_scores},{:cce_grade_set=>:cce_grades}]).each do |og|
      og.observations.each do |o|
        report_hash[o.id]={}
        o.assessment_scores.scoped(:conditions=>{:exam_id=>nil,:batch_id=>id}).group_by(&:student_id).each{|k,v| report_hash[o.id][k]=(v.sum(&:grade_points)/v.count.to_f).round}
        report_hash[o.id].each do |key,val|
          o.cce_reports.build(:student_id=>key, :grade_string=>og.cce_grade_set.grade_string_for(val), :batch_id=> id)
        end
        o.save
      end
    end
  end

  def delete_coscholastic_reports
    CceReport.delete_all({:batch_id=>id,:exam_id=>nil})
  end

  def fa_groups
    FaGroup.all(:joins=>:subjects, :conditions=>{:subjects=>{:batch_id=>id}}).uniq
  end

  def create_scholastic_reports
    report_hash={}
    fa_groups.each do |fg|
      fg.fa_criterias.all(:include=>:assessment_scores).each do |f|
        report_hash[f.id]={}
        f.assessment_scores.scoped(:conditions=>["exam_id IS NOT NULL AND batch_id = ?",id]).group_by(&:exam_id).each do |k1,v1|
          report_hash[f.id][k1]={}
          v1.group_by(&:student_id).each{|k2,v2| report_hash[f.id][k1][k2]=(fg.di_formula == 1 ? (((v2.sum(&:grade_points)/v2.count)/f.max_marks)*100).to_f : ((v2.sum(&:grade_points)/f.max_marks).to_f)*100)}
        end
        report_hash[f.id].each do |k1,v1|
          v1.each do |k2,v2|
            f.cce_reports.build(:student_id=>k2, :grade_string=>v2,:exam_id=>k1, :batch_id=> id)
          end
        end
        f.save
      end
    end
  end

  def delete_scholastic_reports
    CceReport.delete_all(["batch_id = ? AND exam_id > 0", id])
  end

  def generate_cce_reports
    CceReport.transaction do
      delete_scholastic_reports
      create_scholastic_reports
      delete_coscholastic_reports
      create_coscholastic_reports
    end
  end

  def delete_icse_reports
    self.icse_reports.destroy_all
  end

  def generate_icse_reports
    self.exam_groups.all(:joins=>:icse_exam_category,:include=>{:exams=>[:exam_scores,:ia_scores]}).each do |exam_group|
      exam_group.exams.each do |exam|
        exam_scores=exam.exam_scores
        ia_scores=exam.ia_scores.all(:select=>"ia_scores.mark,ia_groups.id as ia_group_id,ia_indicators.indicator,ia_indicators.max_mark,ia_calculations.formula,ia_scores.student_id,ia_scores.exam_id",:joins=>[:ia_indicator=>{:ia_group=>:ia_calculation}])
        only_ia_score_student_ids=(ia_scores.collect(&:student_id).uniq)-(exam_scores.collect(&:student_id))
        exam_scores.each do |student_score|
          student_ia_scores=ia_scores.select{|s| s.student_id==student_score.student_id}
          ia_mark=ia_mark_calculation(student_ia_scores)
          weightage=student_score.exam.subject.icse_weightages.find_by_icse_exam_category_id(exam_group.icse_exam_category_id)
          if student_score.marks.present?
            ea_mark=(student_score.marks.to_f/student_score.exam.maximum_marks.to_f)*100
            weightage_ea=weightage.present?? (ea_mark/100)*weightage.ea_weightage : 0
            weightage_ea=weightage_ea.to_f.round
          end
          weightage_ia=weightage.present?? (ia_mark/100)*weightage.ia_weightage : 0
          total_mark=(weightage_ea.to_f.round)+(weightage_ia.to_f.round)
          IcseReport.create("batch_id"=>self.id, "ea_score"=>ea_mark, "total_score"=>total_mark.to_f.round, "exam_id"=>exam.id, "ia_score"=>ia_mark.to_f.round, "student_id"=>student_score.student_id,"ia_mark"=> weightage_ia.to_f.round,"ea_mark"=>weightage_ea)
        end
        if only_ia_score_student_ids.present?
          only_ia_score_student_ids.each do |student_id|
            student_ia_scores=ia_scores.select{|s| s.student_id==student_id}
            ia_mark=ia_mark_calculation(student_ia_scores)
            weightage=exam.subject.icse_weightages.find_by_icse_exam_category_id(exam_group.icse_exam_category_id)
            weightage_ia=weightage.present?? (ia_mark/100)*weightage.ia_weightage : 0
            if weightage.is_co_curricular?
              total_mark=weightage_ia.to_f.round
            end
            IcseReport.create("batch_id"=>self.id, "exam_id"=>exam.id, "ia_score"=>ia_mark.to_f.round, "student_id"=>student_id,"ia_mark"=> weightage_ia.to_f.round,"total_score"=>total_mark)
          end
        end
      end
    end
  end
  
  def ia_mark_calculation(ia_scores)
    ia_formula=ia_scores.collect(&:formula).uniq.first
    #obtained  score calculation
    if ia_formula.present?
      ia_obtained_score_hash={}
      ia_scores.group_by(&:indicator).each do |indicator,mark|
        hsh={indicator=>(mark[0].mark.to_f/mark[0].max_mark.to_f)}
        ia_obtained_score_hash.merge!hsh
      end
      assign_values=[]
      ia_obtained_score_hash.each{|ias,m| assign_values << "#{ias}=#{m}"}
      assign_values.each{|s| instance_eval(s.gsub("`",""))}
      ia_obtained_mark= begin
        instance_eval(ia_formula)
      rescue
        0
      end
        
      #maximum mark calculation
      ia_max_score_hash={}
      ia_scores.group_by(&:indicator).each do |indicator,mark|
        hsh={indicator=>(mark[0].max_mark.to_f/mark[0].max_mark.to_f)}
        ia_max_score_hash.merge!hsh
      end
      assign_values=[]
      ia_max_score_hash.each{|ias,m| assign_values << "#{ias}=#{m}"}
      assign_values.each{|s| instance_eval(s.gsub("`",""))}
      ia_max_mark= begin
        instance_eval(ia_formula)
      rescue
        1
      end
      
      ia_mark=(ia_obtained_mark.to_f/ia_max_mark.to_f)*100
    else
      ia_mark=0
    end
    return ia_mark
  end

  def avg(*args)
    count=args.length
    total=0
    args.each{|s| total+=s.to_f}
    return (total.to_f/count.to_f)
  end

  def best(*args)
    count=args[0]
    scores=args-args[0].to_a
    order=scores.sort_by{|d| d.to_f}.reverse
    values=order[0..(count-1)]
    total=0
    values.each{|s| total+=s.to_f}
    return total
  end

  def generate_icse_exam_reports
    IcseReport.transaction do
      delete_icse_reports
      generate_icse_reports
    end
  end
  
  def perform
    #this is for cce_report_generation use flags if need job for other works

    if job_type=="1"
      generate_batch_reports
    elsif job_type=="2"
      generate_previous_batch_reports
    elsif job_type=="3"
      generate_cce_reports
    elsif job_type=="4"
      generate_icse_exam_reports
    end
    prev_record = Configuration.find_by_config_key("job/Batch/#{self.job_type}")
    if prev_record.present?
      prev_record.update_attributes(:config_value=>Time.now)
    else
      Configuration.create(:config_key=>"job/Batch/#{self.job_type}", :config_value=>Time.now)
    end
  end

  def delete_student_cce_report_cache
    students.all(:select=>"id, batch_id").each do |s|
      s.delete_individual_cce_report_cache
    end
  end

  def check_credit_points
    grading_level_list.select{|g| g.credit_points.nil?}.empty?
  end

  def user_is_authorized?(u)
    employees.collect(&:user_id).include? u.id
  end

  def self.batch_details(parameters)
    sort_order=parameters[:sort_order]
    if sort_order.nil?
      batches=Batch.all(:select=>"batches.id,name,start_date,end_date,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,course_id,courses.code,count(students.id) as student_count",:joins=>"LEFT OUTER JOIN `students` ON students.batch_id = batches.id LEFT OUTER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'batches.id',:conditions=>{:is_deleted=>false,:is_active=>true},:include=>[:course,:employees],:order=>'code ASC')
    else
      batches=Batch.all(:select=>"batches.id,name,start_date,end_date,count(IF(students.gender like '%m%',1,NULL)) as male_count,count(IF(students.gender like '%f%',1,NULL)) as female_count,course_id,courses.code,count(students.id) as student_count",:joins=>"LEFT OUTER JOIN `students` ON students.batch_id = batches.id LEFT OUTER JOIN `courses` ON `courses`.id = `batches`.course_id",:group=>'batches.id',:conditions=>{:is_deleted=>false,:is_active=>true},:include=>[:course,:employees],:order=>sort_order)
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('start_date')}","#{t('end_date')}","#{t('tutor')}","#{t('students')}","#{t('male')}","#{t('female')}"]
    data << col_heads
    batches.each_with_index do |obj,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{obj.code}-#{obj.name}"
      col<< "#{format_date(obj.start_date.to_date)}"
      col<< "#{format_date(obj.end_date.to_date)}"
      col << "#{obj.employees.map{|em| "#{em.full_name} ( #{em.employee_number})"}.join("\n ")}"
      col<< "#{obj.student_count}"
      col<< "#{obj.male_count}"
      col<< "#{obj.female_count}"
      col=col.flatten
      data<< col
    end
    return data
  end

  def self.batch_fee_defaulters(parameters)

    sort_order=parameters[:sort_order]||nil
    course_id=parameters[:course_id]
    batches=Batch.all(:select=>"batches.id,batches.course_id,batches.name,batches.start_date,batches.end_date,sum(balance) balance,count(DISTINCT collection_id) fee_collections_count",:joins=>"INNER JOIN #{derived_sql_table} finance on finance.batch_id=batches.id",:group=>'batches.id',:include=>:course,:conditions=>{:course_id=>course_id,:is_deleted=>false,:is_active=>true},:order=>sort_order)
    employees=Employee.all(:select=>'batches.id as batch_id,employees.first_name,employees.last_name,employees.middle_name,employees.id as employee_id,employees.employee_number',:conditions=>{:batches=>{:course_id=>course_id}} ,:joins=>[:batches]).group_by(&:batch_id)
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('start_date')}","#{t('end_date')}","#{t('tutor')}","#{t('fee_collections')}","#{t('balance')}(#{Configuration.currency})"]
    data << col_heads
    batches.each_with_index do |b,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{b.code}-#{b.name}"
      col<< "#{format_date(b.start_date.to_date)}"
      col<< "#{format_date(b.end_date.to_date)}"
      unless employees.blank?
        unless employees[b.id.to_s].nil?
          emp=[]
          employees[b.id.to_s].each do |em|
            emp << "#{em.full_name} ( #{em.employee_number} )"
          end
          col << "#{emp.join("\n")}"
        else
          col << "--"
        end
      else
        col << "--"
      end
      col<< "#{b.fee_collections_count}"
      col<< "#{b.balance.nil?? 0 : b.balance}"
      col=col.flatten
      data<< col
    end
    return data
  end

  def validate_students(students_admission_no)
    all_admission_nos=students.collect(&:admission_no)
    rejected_admission_no=students_admission_no-all_admission_nos
    return rejected_admission_no
  end
  def name_for_particular_wise_discount
    " &#x200E;(#{full_name})&#x200E;"
  end
  
  def fetch_activities_summary(date)
    @date=date
    first_day = @date.beginning_of_day
    last_day = @date.end_of_day
    @calender_events=[]
    #        events section==================================================
    common_event = Event.find_all_by_is_common_and_is_holiday(true,false, :conditions => ["(start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or (? BETWEEN start_date AND end_date) or (? BETWEEN start_date AND end_date)",first_day,last_day,first_day,last_day,first_day,last_day])
    @common_event_array = []
    common_event.each do |h|
      if h.start_date.to_date == h.end_date.to_date
        @common_event_array.push h if h.start_date.to_date == @date
      else
        (h.start_date.to_date..h.end_date.to_date).each do |d|
          @common_event_array.push h if d == @date
        end
      end
    end
    non_common_events = Event.find_all_by_is_common_and_is_holiday_and_is_exam_and_is_due(false,false,false,false, :conditions => ["(start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or (? BETWEEN start_date AND end_date) or (? BETWEEN start_date AND end_date)",first_day,last_day,first_day,last_day,first_day,last_day],:include=>[:batch_events])
    @student_batch_not_common_event_array = []
    non_common_events.each do |h|
      if h.start_date.to_date == "#{h.end_date.year}-#{h.end_date.month}-#{h.end_date.day}".to_date
        if "#{h.start_date.year}-#{h.start_date.month}-#{h.start_date.day}".to_date == @date
          @student_batch_not_common_event_array.push(h) if h.batch_events.collect(&:batch_id).include?(self.id)
        end
      else
        (h.start_date.to_date..h.end_date.to_date).each do |d|
          if d == @date
            @student_batch_not_common_event_array.push(h) if h.batch_events.collect(&:batch_id).include?(self.id)
          end
        end
      end
    end
    @calender_events += @common_event_array + @student_batch_not_common_event_array
    #=================================================================================================================
    #Holiday Events++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    common_holiday_event = Event.find_all_by_is_common_and_is_holiday(true,true, :conditions => ["(start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or (? BETWEEN start_date AND end_date) or (? BETWEEN start_date AND end_date)",first_day,last_day,first_day,last_day,first_day,last_day])
    @common_holiday_event_array = []
    common_holiday_event.each do |h|
      if h.start_date.to_date == h.end_date.to_date
        @common_holiday_event_array.push h if h.start_date.to_date == @date
      else
        ( h.start_date.to_date..h.end_date.to_date).each do |d|
          @common_holiday_event_array.push h if d == @date
        end
      end
    end
    non_common_holiday_events = Event.find_all_by_is_common_and_is_holiday(false,true, :conditions => ["(start_date BETWEEN ? AND ?) or (end_date BETWEEN ? AND ?) or (? BETWEEN start_date AND end_date) or (? BETWEEN start_date AND end_date)",first_day,last_day,first_day,last_day,first_day,last_day],:include=>[:batch_events])
    @student_batch_not_common_holiday_event_array = []
    non_common_holiday_events.each do |h|
      if h.start_date.to_date == h.end_date.to_date
        if h.start_date.to_date == @date
          @student_batch_not_common_holiday_event_array.push(h) if h.batch_events.collect(&:batch_id).include?(self.id)
        end
      else
        (h.start_date.to_date..h.end_date.to_date).each do |d|
          if d == @date
            @student_batch_not_common_holiday_event_array.push(h) if h.batch_events.collect(&:batch_id).include?(self.id)
          end
        end
      end
    end
    @calender_events += @common_holiday_event_array.to_a + @student_batch_not_common_holiday_event_array.to_a
    #+++==================================================================================================================================
    return @calender_events
  end
  
  def fetch_timetable_summary(date)
    tt=self.time_table_class_timings.first(:include=>[:timetable,{:time_table_class_timing_sets=>{:class_timing_set=>:class_timings}}],:conditions=>["timetables.start_date <= ? and timetables.end_date >= ?",date,date])
    if tt.present?
      tt_id=tt.timetable_id
      entries=[]
      entries+=TimetableEntry.all(:select=>"timetable_entries.*,subjects.name as sname,subjects.id as suid,employees.id as eid,employees.first_name as ename,classrooms.name as cname,buildings.name as bname,ac.date as ddate",:conditions=>["timetable_entries.batch_id=? and timetable_id=? and weekday_id=? and subjects.elective_group_id IS NULL",self.id,tt_id,date.to_date.wday],:include=>[:class_timing,:subject,:employee,:timetable_swaps],:joins=>"INNER JOIN subjects on subjects.id=timetable_entries.subject_id LEFT OUTER JOIN employees on employees.id=timetable_entries.employee_id LEFT OUTER JOIN allocated_classrooms ac on ac.timetable_entry_id=timetable_entries.id LEFT OUTER JOIN classrooms on classrooms.id=ac.classroom_id LEFT OUTER JOIN buildings on buildings.id=classrooms.building_id")
      entries+=TimetableEntry.all(:select=>"timetable_entries.*,ts2.id as suid,ts2.name as sname,employees.id as eid,employees.first_name as ename,classrooms.name as cname,buildings.name as bname,ac.date as ddate",:conditions=>["timetable_entries.batch_id=? and timetable_id=? and weekday_id=?",self.id,tt_id,date.to_date.wday],:include=>[:class_timing,{:subject=>:elective_group},:employee,:timetable_swaps],:joins=>"INNER JOIN subjects ts1 on ts1.id=timetable_entries.subject_id INNER JOIN elective_groups eg1 on eg1.id=ts1.elective_group_id LEFT OUTER JOIN subjects ts2 on ts2.elective_group_id=eg1.id LEFT OUTER JOIN employees_subjects on employees_subjects.subject_id=ts2.id LEFT OUTER JOIN employees on employees.id=employees_subjects.employee_id LEFT OUTER JOIN allocated_classrooms ac on ac.subject_id=ts2.id and ac.timetable_entry_id=timetable_entries.id LEFT OUTER JOIN classrooms on ac.classroom_id=classrooms.id LEFT OUTER JOIN buildings on buildings.id=classrooms.building_id")
      entries=entries.sort{|a,b| a.class_timing.start_time <=> b.class_timing.start_time}
      ct_hash = entries.group_by(&:class_timing_id)
      hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }

      ct_hash.each do |ctid,v|
        tcount=0
        class_timing = v.detect{|c| c.class_timing_id == ctid}
        hash[ctid][:class_timing] = "#{format_date(class_timing.class_timing.start_time,:format=>:time)} - #{format_date(class_timing.class_timing.end_time,:format=>:time)}"
        subjects = v.group_by(&:suid)

        subjects.each do |suid,v1|
          subject = v1.first
          hash[ctid][:subjects][suid][:subject_name] = subject.timetable_swaps.present? ? subject.timetable_swaps.first.subject.name : subject.sname
          employees = v1.group_by(&:eid)
          scount=0
          employees.each do |emid,v2|
            employee = v2.first
            hash[ctid][:subjects][suid][:employees][emid][:employee_name] = subject.timetable_swaps.present? ? subject.timetable_swaps.first.employee.first_name : employee.ename
            date_specific=v2.collect{|r| [r.cname,r.bname] if (r.ddate.present? and r.ddate.to_date==date)}
            non_date_specific=v2.collect{|r| [r.cname,r.bname] unless (r.ddate.present?)}
            unless date_specific.compact.empty?
              hash[ctid][:subjects][suid][:employees][emid][:rooms]=date_specific.compact
              tcount+=date_specific.compact.count==0 ? 1 : date_specific.compact.count
              scount+=date_specific.compact.count==0 ? 1 : date_specific.compact.count
              hash[ctid][:subjects][suid][:employees][emid][:ecount]=date_specific.compact.count==0 ? 1 : date_specific.compact.count
            else
              hash[ctid][:subjects][suid][:employees][emid][:rooms]=non_date_specific.compact
              tcount+=non_date_specific.compact.count==0 ? 1 : non_date_specific.compact.count
              scount+=non_date_specific.compact.count==0 ? 1 : non_date_specific.compact.count
              hash[ctid][:subjects][suid][:employees][emid][:ecount]=non_date_specific.compact.count==0 ? 1 : non_date_specific.compact.count
            end
          end
          hash[ctid][:subjects][suid][:scount] = scount
        end
        hash[ctid][:tcount] = tcount
      end
      hash
    end
  end

  def subject_wise_normal_subjects(timetable_id)
    normal_subjects=Subject.all(:select=>"subjects.*,employees.id as eid,employees.first_name as ename,employees.last_name,timetable_entries.id as tid",:conditions=>["subjects.is_deleted = ? and subjects.batch_id=? and subjects.elective_group_id IS NULL",false,self.id],:joins=>"LEFT OUTER JOIN timetable_entries on timetable_entries.subject_id=subjects.id and timetable_entries.timetable_id='#{timetable_id}' LEFT OUTER JOIN employees on employees.id=timetable_entries.employee_id ")
    sub_hash = normal_subjects.group_by{|s| s.id}
    hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    sub_hash.each do |sub_id,v|
      record = normal_subjects.detect{|s| s.id == sub_id}
      hsh[sub_id][:subject_name] = record.name
      hsh[sub_id][:total_periods] =v.reject{|s| s.tid.nil?}.count
      employees = v.group_by(&:eid)
      hsh[sub_id][:employee_count]=employees.count
      employees.each do |eid,v1|
        emp_record=v1.first
        hsh[sub_id][:employees][eid][:employee_name]=emp_record.ename
        hsh[sub_id][:employees][eid][:emp_periods]=v1.reject{|p| p.tid.nil?}.count
        hsh[sub_id][:employees][eid][:periods_present]=v1.reject{|p| p.tid.nil?}.count > 0 ? true : false
      end
    end
    hsh
  end

  def employee_wise_normal_subjects(timetable_id)
    normal_employees=Employee.all(:select=>"employees.*,tte.employee_id as eid,employees.first_name as ename,tte.id,subjects.name as sname,subjects.id as sid",:joins=>"RIGHT OUTER JOIN timetable_entries tte on tte.employee_id=employees.id LEFT OUTER JOIN subjects on subjects.id=tte.subject_id",:conditions=>["tte.timetable_id=? and tte.batch_id=? and subjects.elective_group_id IS NULL",timetable_id,self.id])
    emp_hash = normal_employees.group_by{|e| e.eid}
    hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    emp_hash.each do |emp_id,v|
      record = normal_employees.detect{|e| e.eid == emp_id}
      hsh[emp_id][:emp_name] = record.ename
      hsh[emp_id][:total_periods]=v.count
      subjects=v.group_by(&:sid)
      hsh[emp_id][:subjects_count]=subjects.count
      subjects.each do |sid,v1|
        sub_record=v1.first
        hsh[emp_id][:subjects][sid][:subject_name]=sub_record.sname
        hsh[emp_id][:subjects][sid][:subject_count]=v1.count
      end
    end
    hsh
  end

  def employee_wise_electives_timetable_assignments (timetable_id)
    elective_subjects = self.subjects.scoped(:select=>'subjects.id,subjects.elective_group_id,subjects.name,eg.name as elective_group_name,tte.id as ttid,em.first_name,em.last_name,em.id as emid',
      :conditions=>["subjects.elective_group_id is not null and em.id is not null and (tte.timetable_id = ? or tte.timetable_id is null)",timetable_id],
      :joins=>"INNER JOIN `elective_groups` eg ON eg.id = `subjects`.elective_group_id
                                          LEFT OUTER JOIN `timetable_entries` tte ON tte.subject_id = subjects.id
                                          LEFT OUTER JOIN employees_subjects es on es.subject_id = subjects.id
                                          INNER JOIN employees em on em.id=es.employee_id ")
    elective_subjects.reject!{|eg| eg.ttid.nil?}
    em_hash = elective_subjects.group_by{|es| es.emid unless es.emid.nil?}
    hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    em_hash.each do |emid,v|
      record = elective_subjects.detect{|es| es.emid == emid}
      hsh[emid][:employee_name] = record.first_name + ' ' + record.last_name
      v.reject!{|s| s.ttid.nil?}
      hsh[emid][:total] = v.count
      electives = v.group_by(&:elective_group_id)
      electives.each do |egid,v1|
        elective = elective_subjects.detect{|es| es.elective_group_id == egid}
        hsh[emid][:elective_groups][egid][:group_name] = elective.elective_group_name
        hsh[emid][:elective_groups][egid][:subjects] = v1.collect(&:name).uniq
        hsh[emid][:elective_groups][egid][:count] = v1.collect(&:ttid).uniq.count
      end
    end
    hsh
  end
end

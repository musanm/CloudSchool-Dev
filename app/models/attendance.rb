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

class Attendance < ActiveRecord::Base
  belongs_to :student
  belongs_to :batch

  #  attr_accessor :quick_mode
  validates_presence_of :month_date,:batch_id,:student_id
  validates_uniqueness_of :student_id, :scope => [:month_date],:message=>"already marked as absent"
  named_scope :by_month, lambda { |d| { :conditions  => { :month_date  => d.beginning_of_month..d.end_of_month } } }
  named_scope :by_month_and_batch, lambda { |d,b| {:conditions  => { :month_date  => d.beginning_of_month..d.end_of_month,:batch_id=>b } } }
  before_save :daily_wise_attendance_check

  after_create :verify_and_send_sms

  include CsvExportMod

  def verify_and_send_sms
    sms_setting = SmsSetting.new()
    student = self.student
    if sms_setting.application_sms_active and student.is_sms_enabled and sms_setting.attendance_sms_active
      recipients = []
      unless Configuration.find_by_config_key('StudentAttendanceType').config_value=="SubjectWise"
        if self.is_full_day
          guardian_temp_message = "#{t('dear_parent')}, #{student.first_and_last_name} #{t('flash_msg7')} #{format_date(self.month_date)}. #{t('thanks')}"
          student_temp_message = "#{t('hi_you_are_marked_absent_on')} #{format_date(self.month_date)}. #{t('thanks')}"
          school = student.school rescue nil
          attendance_messsage = AttendanceMesssage.find_by_school_id(school.try(:id)) rescue nil
          student_message = attendance_messsage.try(:absent_message).gsub("[[NAME]]", student.first_and_last_name).gsub("[[TIME]]", format_date(self.month_date) ) rescue student_temp_message
          guardian_message = attendance_messsage.try(:absent_message).gsub("[[NAME]]", student.first_and_last_name).gsub("[[TIME]]", format_date(self.month_date) ) rescue guardian_temp_message
        elsif self.forenoon == true and self.afternoon == false
          guardian_message = "#{t('dear_parent')}, #{student.first_and_last_name} #{t('flash_msg7')} #{format_date(self.month_date)} #{t('during_forenoon')}. #{t('thanks')}"
          student_message = "#{t('hi_you_are_marked_absent_on')} #{format_date(self.month_date)} #{t('during_forenoon')}. #{t('thanks')}"
        elsif self.afternoon == true and self.forenoon == false
          guardian_message = "#{t('dear_parent')}, #{student.first_and_last_name} #{t('flash_msg7')} #{format_date(self.month_date)} #{t('during_afternoon')}. #{t('thanks')}"
          student_message = "#{t('hi_you_are_marked_absent_on')} #{format_date(self.month_date)} #{t('during_afternoon')}. #{t('thanks')}"
        end
      else
        guardian_message = "#{t('your_ward')} #{student.first_and_last_name} #{t('flash_msg7')} #{format_date(self.month_date)} #{t('for_subject')} #{self.subject.name} #{t('during_period')} #{self.class_timing.try(:name)}. #{t('thanks')}"
        student_message = "#{t('hi_you_are_marked_absent_on')} #{format_date(self.month_date)} #{t('for_subject')} #{self.subject.name} #{t('during_period')} #{self.class_timing.try(:name)}. #{t('thanks')}"
      end
      if sms_setting.student_sms_active
        recipients.push student.phone2.split(',') unless student.phone2.nil?
        if recipients.present?
          recipients.flatten!
          recipients.uniq!
          Delayed::Job.enqueue(SmsManager.new(student_message,recipients))
        end
      end
      recipients = []
      if sms_setting.parent_sms_active
        if student.immediate_contact.present?
          guardian = Guardian.find(student.immediate_contact_id)
          recipients.push guardian.mobile_phone.split(',') if guardian.mobile_phone.present?
          if recipients.present?
            recipients.flatten!
            recipients.uniq!
            Delayed::Job.enqueue(SmsManager.new(guardian_message,recipients))
          end
        end
      end
    end
  end
  
  def validate
    unless self.student.nil?
      if self.student.batch_id == self.batch_id
        if self.afternoon==false and self.forenoon==false
          errors.add_to_base :select_leave_session
        end
      else
        errors.add('batch_id',"attendance is not marked for present batch")
      end
      unless self.month_date.nil?
        errors.add :attendance_before_the_date_of_admission  if self.month_date < self.student.admission_date
      else
        errors.add :month_date_cant_be_blank
      end
    end
    errors.add(:month_date, :cant_be_a_future_date) if (month_date.present? and month_date > Configuration.default_time_zone_present_time.to_date)
  end

  def daily_wise_attendance_check
    config = Configuration.find_by_config_key('StudentAttendanceType')
    unless config.config_value=="SubjectWise"
      batch=self.batch
      working_days=batch.working_days(self.month_date.to_date)
      if working_days.include? self.month_date.to_date
        return true
      else
        errors.add_to_base :attendance_date_invalid
        return false
      end
    end
  end

  def is_full_day
    forenoon == true and afternoon == true
  end

  def is_half_day
    forenoon == true or afternoon == true
  end

  def month_dates
    format_date(month_date,:format=>:long)
  end

  def leave_info
    if forenoon and !afternoon
      return "#{t('forenoon')}"
    elsif afternoon and !forenoon
      "#{t('afternoon')}"
    end
  end

  def self.fetch_student_attendance_data(params) 
    student_attendance_report params
  end

  def self.fetch_day_wise_report_data(params)
    day_wise_report params
  end
end
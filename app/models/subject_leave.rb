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
class SubjectLeave < ActiveRecord::Base
  belongs_to :student
  belongs_to :batch
  belongs_to :subject
  belongs_to :employee
  belongs_to :class_timing

#  attr_accessor :quick_mode

  validates_presence_of :subject_id
  validates_presence_of :batch_id
  validates_presence_of :student_id
  validates_presence_of :month_date
  validates_presence_of :class_timing_id
  #validates_presence_of :reason

  named_scope :by_month_and_subject, lambda { |d,s| { :conditions  => { :month_date  => d.beginning_of_month..d.end_of_month , :subject_id => s} } }
  named_scope :by_month_batch_subject, lambda { |d,b,s| {  :conditions  => { :month_date  => d.beginning_of_month..d.end_of_month , :subject_id => s,:batch_id=>b} } }
  validates_uniqueness_of :student_id,:scope=>[:class_timing_id,:month_date],:message=>"already marked as absent"
  
  after_create :verify_and_send_sms

  def validate
    unless student.nil?
      errors.add :attendance_before_the_date_of_admission  if self.month_date < self.student.admission_date unless month_date.nil?
    end
    errors.add(:month_date, :future_attendance_cannot_be_marked) if month_date > Configuration.default_time_zone_present_time.to_date
  end

  def formatted_date
    format_date(month_date,:format=>:long)
  end

  def verify_and_send_sms
    sms_setting = SmsSetting.new()
    student = self.student
    if sms_setting.application_sms_active and student.is_sms_enabled and sms_setting.attendance_sms_active
      recipients = []
      unless Configuration.find_by_config_key('StudentAttendanceType').config_value=="SubjectWise"
        if self.is_full_day
          guardian_message = "#{t('dear_parent')}, #{student.first_and_last_name} #{t('flash_msg7')} #{format_date(self.month_date)}. #{t('thanks')}"
          student_message = "#{t('hi_you_are_marked_absent_on')} #{format_date(self.month_date)}. #{t('thanks')}"
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
end

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

class Event < ActiveRecord::Base
  validates_presence_of :title, :description, :start_date, :end_date

  named_scope :holidays, :conditions => {:is_holiday => true}
  named_scope :exams, :conditions => {:is_exam => true}
  has_many :batch_events, :dependent => :destroy
  has_many :employee_department_events, :dependent => :destroy
  has_many :user_events, :dependent => :destroy
  belongs_to :origin , :polymorphic => true

  attr_accessor :manual
  accepts_nested_attributes_for :user_events , :allow_destroy => true

  def verify_update_and_send_sms
    recipients = []
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active and sms_setting.event_news_sms_active and manual ## only for events created from fedena calendar
      if self.is_common == true
        users = User.active.find(:all)
        users.each do |u|
          if u.student == true
            student = u.student_record
            if student.present?
              if sms_setting.student_sms_active and student.is_sms_enabled
                recipients.push student.phone2 if student.phone2.present?
              end
              if sms_setting.parent_sms_active
                guardian = student.immediate_contact if student.immediate_contact.present?
                recipients.push guardian.mobile_phone if guardian.present? and guardian.mobile_phone.present?
              end
            end
          else
            if sms_setting.employee_sms_active
              employee = u.employee_record
              recipients.push employee.mobile_phone if employee.present? and employee.mobile_phone.present?
            end
          end
        end
      else
        batch_event = BatchEvent.find_all_by_event_id(self.id)
        unless batch_event.empty?
          batch_event.each do |b|
            batch_students = Student.find(:all, :conditions=>"batch_id = #{b.batch_id}")
            batch_students.each do |s|
              if sms_setting.student_sms_active and s.is_sms_enabled
                recipients.push s.phone2 if s.phone2.present? 
              end
              if sms_setting.parent_sms_active
                guardian = s.immediate_contact if s.immediate_contact.present?                
                recipients.push guardian.mobile_phone if guardian.present? and guardian.mobile_phone.present?
              end
            end
          end
        end
        department_event = EmployeeDepartmentEvent.find_all_by_event_id(self.id)
        if sms_setting.employee_sms_active
          unless department_event.empty?
            department_event.each do |d|
              dept_emp = Employee.find(:all, :conditions=>"employee_department_id = #{d.employee_department_id}")
              dept_emp.each do |e|
                recipients.push e.mobile_phone if e.mobile_phone.present?
              end
            end
          end
        end
      end
    end
    if recipients.present?
      recipients = recipients.collect { |x| x.split(',') }
      recipients.flatten!
      recipients.uniq!
      message = "#{t('event_text')} #{self.title} #{t('is_scheduled_from')} #{format_date(self.start_date,:format=>:short_date)} #{t('to_text')} #{format_date(self.end_date,:format=>:short_date)}. #{t('thanks')}"
      until recipients.empty? # loop till recipients list gets empty
        recipient_set = recipients.take(500) # take first 500
        recipients = recipients.drop(500) # drop selected 500 from unprocessed set to push in delayed job
        Delayed::Job.enqueue(SmsManager.new(message,recipient_set))
      end
    end    
  end

  def validate
    unless self.start_date.nil? or self.end_date.nil?
      errors.add(:end_time, :can_not_be_before_the_start_time) if self.end_date < self.start_date
    end
  end

  def is_student_event(student)
    flag = false
    base = self.origin
    unless base.blank?
      if base.respond_to?('batch_id')
        if (origin_type=="FinanceFeeCollection" and base.fee_collection_batches.collect(&:batch_id).include? student.batch_id) or base.batch_id == student.batch_id
          finance = base.fee_table
          if finance.present?
            flag = true if finance.map{|fee|fee.student_id}.include?(student.id)
          end
        end
      end
    end
    user_events = self.user_events
    unless user_events.nil?
      flag = true if user_events.map{|x|x.user_id }.include?(student.user.id)
    end
    return flag
  end

  def is_employee_event(user)
    user_events = self.user_events
    unless user_events.nil?
      return true if user_events.map{|x|x.user_id }.include?(user.id)
    end
    return false
  end

  def is_published_exam
    if self.origin_type == "Exam"
      return self.origin.exam_group.is_published if self.origin.present? and self.origin.exam_group.present?
    end
  end

  def is_active_event
    flag = false
    unless self.origin.nil?
      if self.origin.respond_to?('is_deleted')
        unless self.origin.is_deleted
          flag = true
        end
      else
        flag = true
      end 
    else
      flag = true
    end
    return flag
  end

  def dates
    (start_date.to_date..end_date.to_date).to_a
  end

  class << self
    def is_a_holiday?(day)
      return true if Event.holidays.count(:all, :conditions => ["start_date <=? AND end_date >= ?", day, day] ) > 0
      false
    end
  end


  def event_member_emails
    member_email=[]

    if self.is_common
      EmployeeDepartment.active_and_ordered.each do |d| member_email=member_email+d.employees.collect(&:email).zip(d.employees.collect(&:first_name));end
      Batch.active.each do |d| member_email=member_email+d.students.select{|s| s.is_email_enabled?}.collect(&:email).zip(d.students.select{|s| s.is_email_enabled?}.collect(&:first_name));end
      Student.all.select{|s| s.is_email_enabled and s.immediate_contact.present? and s.immediate_contact.email.present?}.each do |st|
        member_email=member_email+st.immediate_contact.email.zip(st.immediate_contact.first_name)
      end
    end
    #member_email=member_email.flatten.reject{|e| e.empty?}
    return member_email
  end
  
  def event_days
    if (start_date.strftime "%a,%d %b %Y")== (end_date.strftime "%a,%d %b %Y")
      "#{format_date(start_date,:format=>:long_date)} #{format_date(start_date,:format=>:time)} to #{format_date(end_date,:format=>:time)}"
    else
      "#{format_date(start_date,:format=>:long)} to #{format_date(end_date,:format=>:long)}"
    end
  end

  def school_details
    name=Configuration.get_config_value('InstitutionName').present? ? "#{Configuration.get_config_value('InstitutionName')}," :""
    address=Configuration.get_config_value('InstitutionAddress').present? ? "#{Configuration.get_config_value('InstitutionAddress')}," :""
    Configuration.get_config_value('InstitutionPhoneNo').present?? phone="#{' Ph:'}#{Configuration.get_config_value('InstitutionPhoneNo')}" :""
    return (name+"#{' '}#{address}"+"#{phone}").chomp(',')
  end
  
  def school_name
    Configuration.get_config_value('InstitutionName')
  end
  
end

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

class User < ActiveRecord::Base
  attr_accessor :password, :role, :old_password, :new_password, :confirm_password

  validates_uniqueness_of :username,:case_sensitive => false #, :email
  validates_length_of     :username, :within => 1..20
  validates_length_of     :password, :within => 4..40, :allow_nil => true
  validates_format_of     :username, :with => /^[A-Z0-9_-]*$/i,
    :message => :must_contain_only_letters
  validates_format_of     :email, :with => /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i,   :allow_blank=>true,
    :message => :must_be_a_valid_email_address
  validates_presence_of   :role , :on=>:create
  validates_presence_of   :password, :on => :create
  validates_presence_of   :first_name

  has_and_belongs_to_many :privileges
  has_many  :user_events
  has_many  :events,:through=>:user_events

  has_many :user_menu_links
  has_many :menu_links, :through=>:user_menu_links
  has_many :remarks,:foreign_key=>'submitted_by'

  has_one :student_entry,:class_name=>"Student",:foreign_key=>"user_id"
  has_one :guardian_entry,:class_name=>"Guardian",:foreign_key=>"user_id"
  has_one :archived_student_entry,:class_name=>"ArchivedStudent",:foreign_key=>"user_id"
  has_one :employee_entry,:class_name=>"Employee",:foreign_key=>"user_id"
  has_one :archived_employee_entry,:class_name=>"ArchivedEmployee",:foreign_key=>"user_id"
  has_one :biometric_information, :dependent => :destroy

  named_scope :active, :conditions => { :is_deleted => false }
  named_scope :inactive, :conditions => { :is_deleted => true }
  named_scope :username_equals, lambda{|username|{:conditions => ["username LIKE BINARY (?)",username]}}

  after_save :create_default_menu_links
  before_destroy :remove_user_news_comments
  def before_save
    self.salt = random_string(8) if self.salt == nil
    self.hashed_password = Digest::SHA1.hexdigest(self.salt + self.password) unless self.password.nil?
    if self.new_record?
      self.admin, self.student, self.employee = false, false, false
      self.admin    = true if self.role == 'Admin'
      self.student  = true if self.role == 'Student'
      self.employee = true if self.role == 'Employee'
      self.parent = true if self.role == 'Parent'
      self.is_first_login = true
    end
  end

  def activate
    self.update_attribute('is_deleted',false)
  end

  def create_default_menu_links
    changes_to_be_checked = ['admin','student','employee','parent']
    check_changes = self.changed & changes_to_be_checked
    if (self.new_record? or check_changes.present?)
      self.menu_links = []
      default_links = []
      if self.admin?
        main_links = MenuLink.find_all_by_name_and_higher_link_id(["human_resource","settings","students","calendar_text","news_text","event_creations"],nil)
        default_links = default_links + main_links
        main_links.each do|link|
          sub_links = MenuLink.find_all_by_higher_link_id(link.id)
          default_links = default_links + sub_links
        end
      elsif self.employee?
        own_links = MenuLink.find_all_by_user_type("employee")
        default_links = own_links + MenuLink.find_all_by_name(["news_text","calendar_text"])
      else
        own_links = MenuLink.find_all_by_name_and_user_type(["my_profile","timetable_text","academics"],"student")
        default_links = own_links + MenuLink.find_all_by_name(["news_text","calendar_text"])
      end
      self.menu_links = default_links
    end
  end

  def remove_user_news_comments
    comment_ids=NewsComment.all(:conditions=>["author_id=? AND is_approved=?",self.id,false]).collect(&:id)
    NewsComment.delete(comment_ids)
  end

  def delete_user_menu_caches
    Rails.cache.delete("user_quick_links#{self.id}")
    menu_cats = MenuLinkCategory.all
    menu_cats.each do|cat|
      Rails.cache.delete("user_cat_links_#{cat.id}_#{self.id}")
    end
  end


  def student_record
    self.is_deleted ? self.archived_student_entry : self.student_entry
  end

  def employee_record
    self.is_deleted ? self.archived_employee_entry : self.employee_entry
  end

  def get_next_admission_no (current_no)
    ((current_no=~/\d+$/).nil? ? current_no.next : current_no.gsub(/\d+$/, current_no.scan(/\d+$/)[0].next))
  end

  def self.next_admission_no (user_type)
    last_user = User.last(:select=>"username",:conditions=>["#{user_type}=?",true])
    if last_user
      next_admission_no = last_user.get_next_admission_no(last_user.username)
      while User.exists?(:username=>next_admission_no) do
        next_admission_no = last_user.get_next_admission_no(next_admission_no)
      end
      return next_admission_no
    end
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def check_reminders
    reminders =[]
    reminders = Reminder.find(:all , :conditions => ["recipient = '#{self.id}'"])
    count = 0
    reminders.each do |r|
      unless r.is_read
        count += 1
      end
    end
    return count
  end

  def self.authenticate?(username, password)
    u = User.active.first(:conditions => ["username LIKE BINARY(?)",username])
    u.hashed_password == Digest::SHA1.hexdigest(u.salt + password)
  end

  def random_string(len)
    randstr = ""
    chars = ("0".."9").to_a + ("a".."z").to_a + ("A".."Z").to_a
    len.times { randstr << chars[rand(chars.size - 1)] }
    randstr
  end

  def role_name
    return "#{t('admin')}" if self.admin?
    return "#{t('student_text')}" if self.student?
    return "#{t('employee_text')}" if self.employee?
    return "#{t('parent')}" if self.parent?
    return nil
  end

  def role_symbols
    prv = []
    privileges.map { |privilege| prv << privilege.name.underscore.to_sym } unless @privilge_symbols

    @privilge_symbols ||= if admin?
      [:admin] + prv
    elsif student?
      [:student] + prv
    elsif employee?
      [:employee] + prv
    elsif parent?
      [:parent] + prv
    else
      prv  
    end
  end

  def is_allowed_to_mark_attendance?
    if self.employee?
      attendance_type = Configuration.get_config_value('StudentAttendanceType')
      if ((self.employee_record.subjects.present? and attendance_type == 'SubjectWise') or (self.employee_record.batches.find(:all,:conditions=>{:is_deleted=>false,:is_active=>true}).present? and attendance_type == 'Daily'))
        return true
      end
    end
    return false
  end

  def can_view_results?
    if self.employee?
      return true if self.employee_record.batches.find(:all,:conditions=>{:is_deleted=>false,:is_active=>true}).present?
    end
    return false
  end

  def can_view_day_wise_report?
    attendance_type = Configuration.get_config_value('StudentAttendanceType')
    if self.admin? or (self.employee? and self.privileges.map{|p| p.name}.include?('StudentAttendanceView'))
      return (attendance_type == "Daily")
    else
      return (can_view_results? and attendance_type == "Daily")
    end
  end

  def has_assigned_subjects?
    if self.employee?
      employee_subjects= self.employee_record.subjects
      if employee_subjects.empty?
        return false
      else
        return true
      end
    else
      return false
    end
  end

  def roll_number_enabled?
    return Configuration.find_or_create_by_config_key('EnableRollNumber').config_value == "1" ? true : false
  end
  def has_required_control?
    if has_assigned_subjects?
      return true
    else
      if can_view_results?
        return true
      else
        return false
      end
    end
  end

  def has_required_controls?
    @config=Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value == "Daily"
      return can_view_results?
    else
      return true if has_assigned_subjects?
      return true if can_view_results?
      return false
    end
  end
    
  def has_exam_privileges?
    return true if self.admin? or self.privileges.map(&:name).include? "ExaminationControl" or self.privileges.map(&:name).include? "EnterResults" or self.privileges.map(&:name).include? "ViewResults"
  end

  def has_required_exam_privileges?
    return true if self.admin? or self.privileges.map(&:name).include? "ExaminationControl" or self.privileges.map(&:name).include? "EnterResults"
  end

  def has_required_custom_remarks_privileges?
    return true if self.admin? or self.privileges.map(&:name).include? "StudentsControl"
  end

  def has_required_batches?
    if !self.parent? and !self.student? and self.employee_record.batches.present?
      self.employee_record.batches.each do |batch|
        return true if batch.course.grading_type=="3" and batch.course.is_deleted==false
      end
      return false
    elsif self.student?
      return true if self.student_record.batch.course.grading_type=="3" and self.student_record.batch.course.is_deleted==false
    elsif self.parent?
      return true if self.parent_record.batch.course.grading_type=="3" and self.parent_record.batch.course.is_deleted==false
    else
      return false
    end
  end
  def has_required_subjects?
    if self.employee_record.subjects.present?
      self.employee_record.subjects.each do |subject|
        return true if subject.batch.course.grading_type=="3" and subject.batch.course.is_deleted==false
      end
      return false
    else
      return false
    end
  end

  def has_cce_subjects?
    if has_assigned_subjects?
      self.employee_record.subjects.each do |subject|
        return true if subject.batch.course.grading_type=="3" and subject.batch.course.is_deleted==false
      end
    else
      if can_view_results?
        self.employee_record.batches.each do |batch|
          return true if batch.course.grading_type=="3" and batch.course.is_deleted==false
        end
        return false
      end
    end
    return false
  end

  def icse_enabled?
    Configuration.icse_enabled?
  end

  def gpa_enabled?
    Configuration.has_gpa?
  end
  

  def clear_menu_cache
    Rails.cache.delete("user_main_menu#{self.id}")
    Rails.cache.delete("user_autocomplete_menu#{self.id}")
  end
  def clear_school_name_cache(request_host)
    Rails.cache.delete("current_school_name/#{request_host}")
  end

  def parent_record
    #    p=Student.find_by_admission_no(self.username[1..self.username.length])
    unless guardian_entry.nil?
      guardian_entry.current_ward
    else
      Student.find_by_admission_no(self.username[1..self.username.length])
    end

    #    p '-------------'
    #    p self.username[1..self.username.length]
    #     Student.find_by_sibling_no_and_immediate_contact(self.username[1..self.username.length])
    #guardian_entry.ward
  end

  def has_subject_in_batch(b)
    employee_record.subjects.collect(&:batch_id).include? b.id
  end

  def has_subject_privilege(sub_id)
    sub_ids = employee_record.subject_ids
    employee_record.batches.each{|e| sub_ids.concat(e.subject_ids)}
    return sub_ids.include? sub_id
  end

  def has_common_remark_privilege(batch_id)
    has_required_exam_privileges? or employee_record.batch_ids.include? batch_id
  end

  def days_events(date)
    all_events=[]
    case(role_name)
    when "Admin"
      all_events=Event.find(:all,:conditions => ["? between date(events.start_date) and date(events.end_date)",date])
    when "Student"
      all_events+= events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= student_record.batch.events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= Event.all(:conditions=>["(? between date(events.start_date) and date(events.end_date)) and is_common = true",date])
    when "Parent"
      all_events+= events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= parent_record.user.events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= parent_record.batch.events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= Event.all(:conditions=>["(? between date(events.start_date) and date(events.end_date)) and is_common = true",date])
    when "Employee"
      all_events+= events.all(:conditions=>["? between events.start_date and events.end_date",date])
      all_events+= employee_record.employee_department.events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= Event.all(:conditions=>["(? between date(events.start_date) and date(events.end_date)) and is_exam = true",date])
      all_events+= Event.all(:conditions=>["(? between date(events.start_date) and date(events.end_date)) and is_common = true",date])
    end
    all_events
  end

  def next_event(date)
    all_events=[]
    case(role_name)
    when "Admin"
      all_events=Event.find(:all,:conditions => ["? < date(events.end_date)",date],:order=>"start_date")
    when "Student"
      all_events+= events.all(:conditions=>["? < date(events.end_date)",date])
      all_events+= student_record.batch.events.all(:conditions=>["? < date(events.end_date)",date],:order=>"start_date")
      all_events+= Event.all(:conditions=>["(? < date(events.end_date)) and is_common = true",date],:order=>"start_date")
    when "Parent"
      all_events+= events.all(:conditions=>["? < date(events.end_date)",date])
      all_events+= parent_record.user.events.all(:conditions=>["? < date(events.end_date)",date])
      all_events+= parent_record.batch.events.all(:conditions=>["? < date(events.end_date)",date],:order=>"start_date")
      all_events+= Event.all(:conditions=>["(? < date(events.end_date)) and is_common = true",date],:order=>"start_date")
    when "Employee"
      all_events+= events.all(:conditions=>["? < date(events.end_date)",date],:order=>"start_date")
      all_events+= employee_record.employee_department.events.all(:conditions=>["? < date(events.end_date)",date],:order=>"start_date")
      all_events+= Event.all(:conditions=>["(? < date(events.end_date)) and is_exam = true",date],:order=>"start_date")
      all_events+= Event.all(:conditions=>["(? < date(events.end_date)) and is_common = true",date],:order=>"start_date")
    end
    start_date=all_events.collect(&:start_date).min
    unless start_date
      return ""
    else
      next_date=(start_date.to_date<=date ? date+1.days : start_date )
      next_date
    end
  end
  def soft_delete
    self.update_attributes(:is_deleted =>true)
  end

  def user_type
    admin? ? "Admin" : employee? ? "Employee" : student? ? "Student" : "Parent"
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

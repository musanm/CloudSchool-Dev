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
class Student < ActiveRecord::Base

  attr_accessor_with_default(:biometric_id) {BiometricInformation.find_by_user_id(user_id).try(:biometric_id)}

  include CceReportMod
  include CsvExportMod
  validates_uniqueness_of :roll_number, :scope => "batch_id", :message => "already taken", :allow_blank => true
  validates_format_of     :roll_number, :with => /^[A-Z0-9_-]*$/i, :message => :must_contain_only_letters, :allow_blank => true
  validates_length_of :roll_number, :maximum => 12, :allow_blank => true
  belongs_to :country
  belongs_to :batch
  belongs_to :student_category
  belongs_to :nationality, :class_name => 'Country'
  belongs_to :user
  

  before_validation :update_roll_number

  #  has_one    :immediate_contact,:class_name => 'Guardian',:foreign_key => 'id',:primary_key => 'immediate_contact_id'
  belongs_to    :immediate_contact,:class_name => 'Guardian'
  has_one    :student_previous_data
  has_many   :student_previous_subject_mark
  #  has_many   :guardians, :foreign_key => 'ward_id'
  has_many   :guardians, :foreign_key => 'ward_id', :primary_key=>:sibling_id
  has_many   :finance_transactions, :as => :payee
  has_many   :cancelled_finance_transactions, :foreign_key => :payee_id,:conditions => ['payee_type = ?', 'Student']
  has_many   :attendances
  has_many   :finance_fees
  has_many   :fee_category ,:class_name => "FinanceFeeCategory"
  has_many   :students_subjects
  has_many   :subjects ,:through => :students_subjects
  has_many   :student_additional_details
  has_many   :batch_students
  has_many   :subject_leaves
  has_many   :grouped_exam_reports
  has_many   :cce_reports
  has_many   :assessment_scores
  has_many   :exam_scores
  has_many   :previous_exam_scores
  has_many   :icse_reports
  has_many   :multi_fees_transactions
  has_many   :remarks
  has_many   :student_discounts,:class_name => 'FeeDiscount',:foreign_key => 'receiver_id',:conditions=>"receiver_type='Student'"
  has_many   :student_particulars,:class_name => 'FinanceFeeParticular',:foreign_key => 'receiver_id',:conditions=>"receiver_type='Student'"
  has_many   :student_attendances
  accepts_nested_attributes_for :remarks
  #has_many   :siblings,:class_name=>'Student',:primary_key=>:sibling_id


  named_scope :admission_no_equals, lambda{|adm_no|{:conditions=>["students.admission_no LIKE BINARY(?)",adm_no]}}
  named_scope :country_name_equals,  lambda{|name|{:joins => [:country,:nationality],:conditions => ["countries.name = ?", name]}}
  named_scope :nationality_name_equals,  lambda{|name|{:joins => [:country,:nationality],:conditions => ["nationalities_students.name = ?", name]}}
  named_scope :name_or_admssn_no_as, lambda{|query|{:conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR admission_no LIKE ? OR concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ?","#{query}%","#{query}%", "#{query}%", "#{query}%", "#{query}%", "#{query}%"]}}
  named_scope :student_name_as, lambda{|query|{:conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ?","#{query}%", "#{query}%", "#{query}%", "#{query}%", "#{query}%"]}}
  named_scope :active, :conditions => { :is_active => true }
  named_scope :with_full_name_only, :select=>"id, CONCAT_WS('',first_name,' ',last_name) AS name,first_name,last_name", :order=>:first_name
  named_scope :with_name_admission_no_only, :select=>"id, CONCAT_WS('',first_name,' ',last_name,' - ',admission_no) AS name,first_name,last_name,admission_no", :order=>:first_name
  named_scope :with_full_name_admission_no, :select=>"id, CONCAT_WS('',first_name,' ',last_name,' (',admission_no,')') AS name,first_name,last_name,admission_no,admission_date", :order=>:first_name
  named_scope :with_full_name_roll_number, :select=>"id, CONCAT_WS('',first_name,' ',last_name,' (',roll_number,')') AS name,first_name,last_name,roll_number,admission_date", :order=>:first_name
  
  named_scope :by_first_name, :order=>'first_name',:conditions => { :is_active => true }

  validates_presence_of :admission_no, :admission_date, :first_name, :batch_id, :date_of_birth,:nationality_id
  validates_uniqueness_of :admission_no,:case_sensitive => false
  validates_presence_of :gender
  validates_format_of     :email, :with => /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i,   :allow_blank=>true,
    :message => :must_be_a_valid_email_address
  validates_format_of     :admission_no, :with => /^[A-Z0-9_-]*$/i,
    :message => :must_contain_only_letters

  #  validates_associated :user
  after_validation :create_user_and_validate

  before_save :is_active_true

  before_save :save_biometric_info

  after_create :set_sibling, :verify_and_send_sms

  after_update :verify_update_and_send_sms

  before_destroy :handle_student_additional_data

  before_update :batch_update,:if=>Proc.new{|s| s.batch_id_changed?}

  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']

  has_attached_file :photo,
    :styles => {:original=> "125x125#"},
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :reject_if => proc { |attributes| attributes.present? },
    :max_file_size => 512000,
    :permitted_file_types =>VALID_IMAGE_TYPES
  
  validates_attachment_content_type :photo, :content_type =>VALID_IMAGE_TYPES,
    :message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.photo_file_name.blank? }
  validates_attachment_size :photo, :less_than => 512000,\
    :message=>'must be less than 500 KB.',:if=> Proc.new { |p| p.photo_file_name_changed? }

  def verify_and_send_sms
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active and sms_setting.student_admission_sms_active and is_sms_enabled and phone2.present?
      
      message = "#{t('student_admission_done_for')} #{first_and_last_name}. #{t('username_is')} #{admission_no}, #{t('guardian_password_is')} #{admission_no}123. #{t('thanks')}"
      
      recipients = phone2.split(',')
      if recipients.present?
        recipients.flatten!
        recipients.uniq!
        Delayed::Job.enqueue(SmsManager.new(message,recipients))
      end
    end
    verify_update_and_send_sms if self.changed and self.changed.include? 'immediate_contact_id'
  end

  def verify_update_and_send_sms
    if self.changed and self.changed.include? 'immediate_contact_id'
      sms_setting = SmsSetting.new()
      if sms_setting.application_sms_active and sms_setting.student_admission_sms_active and self.is_sms_enabled and self.immediate_contact.present?
        recipients = []
        message = "#{t('you_are_added_as_an_emergency_contact_for')} #{self.full_name}. #{t('your_username_is')} #{self.immediate_contact.user.username}, #{t('guardian_password_is')} #{self.immediate_contact.user.username}123. #{t('thanks')}"
        if sms_setting.parent_sms_active
          guardian = Guardian.find(self.immediate_contact_id)
          recipients.push guardian.mobile_phone.split(',') if guardian.mobile_phone.present?
          if recipients.present?
            recipients.flatten! if recipients.present?
            recipients.uniq! if recipients.present?
            Delayed::Job.enqueue(SmsManager.new(message,recipients))
          end
        end
      end
    end
  end
  
  def save_biometric_info
    biometric_info = BiometricInformation.find_or_initialize_by_user_id(user_id)
    biometric_info.update_attributes(:user_id => user_id,:biometric_id => biometric_id)
    biometric_info.errors.each{|attr,msg| errors.add(attr.to_sym,"#{msg}")}
    unless errors.blank?
      raise ActiveRecord::Rollback
    end
  end

  def handle_student_additional_data
    self.student_additional_details.destroy_all unless ArchivedStudent.find_by_former_id(self.id).present?
  end

  def validate
    errors.add(:admission_date, :not_less_than_hundred_year) if self.admission_date.year < Date.today.year - 100 \
      if self.admission_date.present?
    errors.add(:date_of_birth, :not_less_than_hundred_year) if self.date_of_birth.year < Date.today.year - 100 \
      if self.date_of_birth.present?
    errors.add(:admission_date, :not_less_than_date_of_birth) if self.admission_date < self.date_of_birth \
      if self.date_of_birth.present? and self.admission_date.present?
    errors.add(:date_of_birth, :cant_be_a_future_date) if self.date_of_birth >= Date.today \
      if self.date_of_birth.present?
    errors.add(:gender, :error2) unless ['m', 'f'].include? self.gender.downcase \
      if self.gender.present?
    errors.add(:admission_no,:error3) if self.admission_no=='0'
    errors.add(:admission_no, :should_not_be_admin) if self.admission_no.to_s.downcase== 'admin'
    unless student_additional_details.blank?
      student_additional_details.each do |student_additional_detail|
        errors.add_to_base(student_additional_detail.errors.full_messages.map{|e| e.to_s+". Please add additional details."}.join(', ')) unless student_additional_detail.valid?
      end
    end
  end

  def is_active_true
    unless self.is_active==1
      self.is_active=1
    end
  end

  def update_roll_number
    if self.roll_number.present? && self.batch.present?
      batch_prefix = self.batch.get_roll_number_prefix || ""
      self.roll_number.to_s.slice!(batch_prefix.to_s)
      self.roll_number = batch_prefix + self.roll_number.to_s if self.roll_number.to_s.present?
    end
  end
  
  def create_user_and_validate
    if self.new_record?
      if self.user.present?
        self.user.activate
      else
        user_record = self.build_user
        user_record.first_name = self.first_name
        user_record.last_name = self.last_name
        user_record.username = self.admission_no.to_s
        user_record.password = self.admission_no.to_s + "123"
        user_record.role = 'Student'
        user_record.email = self.email.blank? ? "" : self.email.to_s
        check_user_errors(user_record)
        return false unless errors.blank?
      end
    else

      self.user.role = "Student"
      changes_to_be_checked = ['admission_no','first_name','last_name','email','immediate_contact_id']
      check_changes = self.changed & changes_to_be_checked
      unless check_changes.blank?
        self.user.username = self.admission_no if check_changes.include?('admission_no')
        self.user.first_name = self.first_name if check_changes.include?('first_name')
        self.user.last_name = self.last_name if check_changes.include?('last_name')
        self.user.email = self.email if check_changes.include?('email')
        self.user.password = (self.admission_no.to_s + "123") if check_changes.include?('admission_no')
        self.user.save if check_user_errors(self.user)
      end

      if check_changes.include?('immediate_contact_id') or check_changes.include?('admission_no')
        Guardian.shift_user(self)
      end

    end
    self.email = "" if self.email.blank?
    return false unless errors.blank?
  end

  def check_user_errors(user)
    unless user.valid?
      er_attrs = []
      errors.each do|a,m|
        er_attrs.push([t(a.to_sym),"#{m}"])
      end
      user.errors.each{|attr,msg| errors.add(t(attr.to_sym),"#{msg}") unless er_attrs.include?([t(attr.to_sym),"#{msg}"]) }
    end
    user.errors.blank?
  end

  def first_and_last_name
    "#{first_name} #{last_name}"
  end

  def full_name
    "#{first_name} #{middle_name} #{last_name}"
  end

  def gender_as_text
    return 'Male' if gender.downcase == 'm'
    return 'Female' if gender.downcase == 'f'
    nil
  end

  def graduated_batches
    self.batch_students.map{|bt| bt.batch}
  end

  def all_batches
    self.graduated_batches + self.batch.to_a
  end

  def image_file=(input_data)
    return if input_data.blank?
    self.photo_filename     = input_data.original_filename
    self.photo_content_type = input_data.content_type.chomp
    self.photo_data         = input_data.read
  end

  def next_student
    next_st = self.batch.students.first(:conditions => "id > #{self.id}", :order => "id ASC")
    next_st ||= batch.students.first(:order => "id ASC")
  end

  def previous_student
    prev_st = self.batch.students.first(:conditions => "id < #{self.id}", :order => "admission_no DESC")
    prev_st ||= batch.students.first(:order => "id DESC")
    prev_st ||= self.batch.students.first(:order => "id DESC")
  end

  def previous_fee_student(date,student_batch_id)
    fee = FinanceFee.first(:conditions => "student_id < #{self.id} and fee_collection_id = #{date} and FIND_IN_SET(students.id,'#{student_batch_id}')", :joins=>'INNER JOIN students ON finance_fees.student_id = students.id',:order => "student_id DESC")
    prev_st = fee.student unless fee.blank?
    fee ||= FinanceFee.first(:conditions=>"fee_collection_id = #{date} and FIND_IN_SET(students.id,'#{student_batch_id}')", :joins=>'INNER JOIN students ON finance_fees.student_id = students.id',:order => "student_id DESC")
    prev_st ||= fee.student unless fee.blank?
    #    prev_st ||= self.batch.students.first(:order => "id DESC")
  end

  def next_fee_student(date,student_batch_id)
    fee = FinanceFee.first(:conditions => "student_id > #{self.id} and fee_collection_id = #{date} and FIND_IN_SET(students.id,'#{student_batch_id}')", :joins=>'INNER JOIN students ON finance_fees.student_id = students.id', :order => "student_id ASC")
    next_st = fee.student unless fee.nil?
    fee ||= FinanceFee.first(:conditions=>"fee_collection_id = #{date} and FIND_IN_SET(students.id,'#{student_batch_id}')", :joins=>'INNER JOIN students ON finance_fees.student_id = students.id',:order => "student_id ASC")
    next_st ||= fee.student unless fee.nil?
    #    prev_st ||= self.batch.students.first(:order => "id DESC")
  end

  def exam_retaken(exam_id)
    if self.previous_exam_scores.find_by_exam_id(exam_id).present?
      return true
    else
      return false
    end
  end

  def finance_fee_by_date(date)
    FinanceFee.find_by_fee_collection_id_and_student_id(date.id,self.id)
  end

  def check_fees_paid(date)
    particulars = date.fees_particulars(self)
    total_fees=0
    financefee = date.fee_transactions(self.id)
    batch_discounts = BatchFeeCollectionDiscount.find_all_by_finance_fee_collection_id(date.id)
    student_discounts = StudentFeeCollectionDiscount.find_all_by_finance_fee_collection_id_and_receiver_id(date.id,self.id)
    category_discounts = StudentCategoryFeeCollectionDiscount.find_all_by_finance_fee_collection_id_and_receiver_id(date.id,self.student_category_id)
    total_discount = 0
    total_discount += batch_discounts.map{|s| s.discount}.sum unless batch_discounts.nil?
    total_discount += student_discounts.map{|s| s.discount}.sum unless student_discounts.nil?
    total_discount += category_discounts.map{|s| s.discount}.sum unless category_discounts.nil?
    if total_discount > 100
      total_discount = 100
    end
    particulars.map { |s|  total_fees += s.amount.to_f}
    total_fees -= total_fees*(total_discount/100)
    paid_fees_transactions = FinanceTransaction.find(:all,:select=>'amount,fine_amount',:conditions=>"FIND_IN_SET(id,\"#{financefee.transaction_id}\")") unless financefee.nil?
    paid_fees = 0
    paid_fees_transactions.map { |m| paid_fees += (m.amount.to_f - m.fine_amount.to_f) } unless paid_fees_transactions.nil?
    amount_pending = total_fees.to_f - paid_fees.to_f
    if amount_pending == 0
      return true
    else
      return false
    end

    #    unless particulars.nil?
    #      return financefee.check_transaction_done unless financefee.nil?
    #
    #    else
    #      return false
    #    end
  end

  def has_retaken_exam(subject_id)
    retaken_exams = PreviousExamScore.find_all_by_student_id(self.id)
    if retaken_exams.empty?
      return false
    else
      exams = Exam.find_all_by_id(retaken_exams.collect(&:exam_id))
      if exams.collect(&:subject_id).include?(subject_id)
        return true
      end
      return false
    end

  end

  def check_fee_pay(date)
    FedenaPrecision.set_and_modify_precision(date.finance_fees.first(:conditions=>"student_id = #{self.id}").balance).to_f == FedenaPrecision.set_and_modify_precision(0).to_f
  end

  def self.next_admission_no
    '' #stub for logic to be added later.
  end

  def get_fee_strucure_elements(date)
    elements = FinanceFeeStructureElement.get_student_fee_components(self,date)
    elements[:all] + elements[:by_batch] + elements[:by_category] + elements[:by_batch_and_category]
  end

  def total_fees(particulars)
    total = 0
    particulars.each do |fee|
      total += fee.amount
    end
    total
  end

  def has_associated_fee_particular?(fee_category)
    status = false
    status = true if fee_category.fee_particulars.find(:all,:conditions=>{:admission_no=>admission_no,:is_deleted=>false}).count > 0
    status = true if student_category_id.present? and fee_category.fee_particulars.find(:all,:conditions=>{:student_category_id=>student_category_id,:is_deleted=>false}).count > 0
    return status
  end

  def archive_student(status,leaving_date)
    student_attributes = self.attributes
    student_attributes["former_id"]= self.id
    student_attributes["status_description"] = status
    student_attributes["former_has_paid_fees"] = self.has_paid_fees
    student_attributes["former_has_paid_fees_for_batch"] = self.has_paid_fees_for_batch
    student_attributes.merge!(:sibling_id=>sibling_id)
    student_attributes.delete "id"
    student_attributes.delete "has_paid_fees"
    student_attributes.delete "has_paid_fees_for_batch"
    student_attributes.delete "created_at"
    archived_student = ArchivedStudent.new(student_attributes)
    archived_student.photo = self.photo if self.photo.file?
    archived_student.date_of_leaving = leaving_date
    slc_counter = (ArchivedStudent.all.map(&:slc_counter).compact.max {|a,b| a <=> b } || 0) + 1
    archived_student.slc_counter = slc_counter
    if archived_student.save
      guardians = self.guardians
      self.user.soft_delete
      if archived_student.siblings.present?
        archived_guardians=archived_student.archived_guardians
        archived_guardians.each do |ag|
          ag.destroy
        end
      end
      guardians.each do |g|
        g.archive_guardian(archived_student.id,self.id)
      end
      self.destroy
    end
  end

  def check_dependency
    return true if self.students_subjects.present? or self.finance_transactions.present? or self.graduated_batches.present? or self.attendances.present? or self.finance_fees.active.present? or Exam.find(:all, :joins => :exam_scores, :conditions => {:exam_scores => {:student_id => self.id}}).present? or  self.subject_leaves.present? or self.assessment_scores.present? or self.cce_reports.present?
    return true if FedenaPlugin.check_dependency(self,"permanant").present?
    return false
  end

  def student_dependencies_list
    warning_msg = []
    warning_msg << "#{t('finance_records_present')}" if self.finance_transactions.present? or self.finance_fees.active.present?
    warning_msg << "#{t('graduated_batch_present')}" if self.graduated_batches.present?
    warning_msg << "#{t('attendance_are_already_marked')}" if self.attendances.present? or self.subject_leaves.present?
    warning_msg << "#{t('already_appeared_for_exam')}" if Exam.find(:all, :joins => :exam_scores, :conditions => {:exam_scores => {:student_id => self.id}}).present? or self.assessment_scores.present? or self.cce_reports.present?
    warning_msg << "#{t('elective_subjects_are_assigned')}" if self.students_subjects.present?
    plugins = []
    FedenaPlugin::AVAILABLE_MODULES.each do |mod|
      plugins << (mod[:name] + "_dependency").to_sym
    end
    DependencyHook.check_dependency_for(self,:only => plugins).each do |dependency|
      warning_msg << dependency.warning unless dependency.result
    end
    return warning_msg
  end
  
  def former_dependency
    plugin_dependencies = FedenaPlugin.check_dependency(self,"former")
  end

  def assessment_score_for(indicator_id,exam_id,batch_id)
    assessment_score = self.assessment_scores.find(:first, :conditions => { :student_id => self.id,:descriptive_indicator_id=>indicator_id,:exam_id=>exam_id,:batch_id=>batch_id })
    assessment_score.nil? ? assessment_scores.build(:descriptive_indicator_id=>indicator_id,:exam_id=>exam_id,:batch_id=>batch_id) : assessment_score
  end
  def observation_score_for(indicator_id,batch_id)
    assessment_score = self.assessment_scores.find(:first, :conditions => { :student_id => self.id,:descriptive_indicator_id=>indicator_id,:batch_id=>batch_id })
    assessment_score.nil? ? assessment_scores.build(:descriptive_indicator_id=>indicator_id,:batch_id=>batch_id) : assessment_score
  end

  #  def create_default_menu_links
  #    default_links = MenuLink.find_all_by_user_type("student")
  #    self.user.menu_links = default_links
  #  end

  def has_higher_priority_ranking_level(ranking_level_id,type,subject_id)
    ranking_level = RankingLevel.find(ranking_level_id)
    higher_levels = RankingLevel.find(:all,:conditions=>["course_id = ? AND priority < ?", ranking_level.course_id,ranking_level.priority])
    if higher_levels.empty?
      return false
    else
      higher_levels.each do|level|
        if type=="subject"
          score = GroupedExamReport.find_by_student_id_and_subject_id_and_batch_id_and_score_type(self.id,subject_id,self.batch_id,"s")
          unless score.nil?
            if self.batch.gpa_enabled?
              return true if((score.marks < level.gpa if level.marks_limit_type=="upper") or (score.marks >= level.gpa if level.marks_limit_type=="lower") or (score.marks == level.gpa if level.marks_limit_type=="exact"))
            else
              return true if((score.marks < level.marks if level.marks_limit_type=="upper") or (score.marks >= level.marks if level.marks_limit_type=="lower") or (score.marks == level.marks if level.marks_limit_type=="exact"))
            end
          end
        elsif type=="overall"
          unless level.subject_count.nil?
            unless level.full_course==true
              subjects = self.batch.subjects
              scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>self.id,:batch_id=>self.batch.id,:subject_id=>subjects.collect(&:id),:score_type=>"s"})
            else
              scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>self.id,:score_type=>"s"})
            end
            unless scores.empty?
              if self.batch.gpa_enabled?
                scores.reject!{|s| !((s.marks < level.gpa if level.marks_limit_type=="upper") or (s.marks >= level.gpa if level.marks_limit_type=="lower") or (s.marks == level.gpa if level.marks_limit_type=="exact"))}
              else
                scores.reject!{|s| !((s.marks < level.marks if level.marks_limit_type=="upper") or (s.marks >= level.marks if level.marks_limit_type=="lower") or (s.marks == level.marks if level.marks_limit_type=="exact"))}
              end
              unless scores.empty?
                sub_count = level.subject_count
                if level.subject_limit_type=="upper"
                  return true if scores.count < sub_count
                elsif level.subject_limit_type=="exact"
                  return true if scores.count == sub_count
                else
                  return true if scores.count >= sub_count
                end
              end
            end
          else
            unless level.full_course==true
              score = GroupedExamReport.find_by_student_id(self.id,:conditions=>{:batch_id=>self.batch.id,:score_type=>"c"})
            else
              total_student_score = 0
              avg_student_score = 0
              marks = GroupedExamReport.find_all_by_student_id_and_score_type(self.id,"c")
              unless marks.empty?
                marks.map{|m| total_student_score+=m.marks}
                avg_student_score = total_student_score.to_f/marks.count.to_f
                marks.first.marks = avg_student_score
                score = marks.first
              end
            end
            unless score.nil?
              if self.batch.gpa_enabled?
                return true if((score.marks < level.gpa if level.marks_limit_type=="upper") or (score.marks >= level.gpa if level.marks_limit_type=="lower") or (score.marks == level.gpa if level.marks_limit_type=="exact"))
              else
                return true if((score.marks < level.marks if level.marks_limit_type=="upper") or (score.marks >= level.marks if level.marks_limit_type=="lower") or (score.marks == level.marks if level.marks_limit_type=="exact"))
              end
            end
          end
        elsif type=="course"
          unless level.subject_count.nil?
            scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>self.id,:score_type=>"s"})
            unless scores.empty?
              if level.marks_limit_type=="upper"
                scores.reject!{|s| !(((s.marks < level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks < level.marks unless level.marks.nil?))}
              elsif level.marks_limit_type=="exact"
                scores.reject!{|s| !(((s.marks == level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks == level.marks unless level.marks.nil?))}
              else
                scores.reject!{|s| !(((s.marks >= level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks >= level.marks unless level.marks.nil?))}
              end
              unless scores.empty?
                sub_count = level.subject_count
                unless level.full_course==true
                  batch_ids = scores.collect(&:batch_id)
                  batch_ids.each do|batch_id|
                    unless batch_ids.empty?
                      count = batch_ids.count(batch_id)
                      if level.subject_limit_type=="upper"
                        return true if count < sub_count
                      elsif level.subject_limit_type=="exact"
                        return true if count == sub_count
                      else
                        return true if count >= sub_count
                      end
                      batch_ids.delete(batch_id)
                    end
                  end
                else
                  if level.subject_limit_type=="upper"
                    return true if scores.count < sub_count
                  elsif level.subject_limit_type=="exact"
                    return true if scores.count == sub_count
                  else
                    return true if scores.count >= sub_count
                  end
                end
              end
            end
          else
            unless level.full_course==true
              scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>self.id,:score_type=>"c"})
              unless scores.empty?
                if level.marks_limit_type=="upper"
                  scores.reject!{|s| !(((s.marks < level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks < level.marks unless level.marks.nil?))}
                elsif level.marks_limit_type=="exact"
                  scores.reject!{|s| !(((s.marks == level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks == level.marks unless level.marks.nil?))}
                else
                  scores.reject!{|s| !(((s.marks >= level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks >= level.marks unless level.marks.nil?))}
                end
                return true unless scores.empty?
              end
            else
              total_student_score = 0
              avg_student_score = 0
              marks = GroupedExamReport.find_all_by_student_id_and_score_type(self.id,"c")
              unless marks.empty?
                marks.map{|m| total_student_score+=m.marks}
                avg_student_score = total_student_score.to_f/marks.count.to_f
                if level.marks_limit_type=="upper"
                  return true if(((avg_student_score < level.gpa unless level.gpa.nil?) if self.batch.gpa_enabled?) or (avg_student_score < level.marks unless level.marks.nil?))
                elsif level.marks_limit_type=="exact"
                  return true if(((avg_student_score == level.gpa unless level.gpa.nil?) if self.batch.gpa_enabled?) or (avg_student_score == level.marks unless level.marks.nil?))
                else
                  return true if(((avg_student_score >= level.gpa unless level.gpa.nil?) if self.batch.gpa_enabled?) or (avg_student_score >= level.marks unless level.marks.nil?))
                end
              end
            end
          end
        end
      end
    end
    return false
  end

  def get_profile_data
    student = self
    biometric_id = BiometricInformation.find_by_user_id(user_id).try(:biometric_id)
    additional_data = Hash.new
    additional_fields = StudentAdditionalField.all(:conditions=>"status = true")
    additional_fields.each do |additional_field|
      detail = StudentAdditionalDetail.find_by_additional_field_id_and_student_id(additional_field.id,student.try(:id))
      additional_data[additional_field.name] = detail.try(:additional_info)
    end
    [student,additional_data,biometric_id]
  end

  def siblings
    @siblings ||= (self.class.find_all_by_sibling_id_and_immediate_contact_id(sibling_id,self.immediate_contact_id) - [self])
  end
  def all_siblings
    self.class.find_all_by_sibling_id(sibling_id)-[self]
  end
  def old_batch
    "#{ Batch.find(changes["batch_id"].last).full_name}"
  end

  def new_batch
    Batch.find(changes["batch_id"].first).full_name
  end

  #  def guardians_with_siblings
  #    if siblings.present?
  #      self.class.first(:select=>"students.*,count(guardians.id) as gc",
  #        :conditions=>["students.id IN (?)",siblings.collect(&:id)+[id]],
  #        :joins=>:guardians).try(:guardians_without_siblings) || guardians_without_siblings
  #    else
  #      guardians_without_siblings
  #    end
  #  end
  #  alias_method_chain :guardians,:siblings

  def set_sibling
    Student.connection.execute("UPDATE `students` SET `sibling_id` = '#{id}' WHERE `id` = #{id};")
  end

  def self.students_details (parameters)
    subject_id=parameters[:subject_id]
    sort_order=parameters[:sort_order]
    if subject_id.nil?
      if sort_order.nil?
        students= Student.all(:select=>"roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",:group=>'students.id',:order=>'first_name ASC')
      else
        students= Student.all(:select=>"roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",:group=>'students.id',:order=>sort_order)
      end
    else
      if sort_order.nil?
        students= Student.all(:select=>"roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id INNER JOIN `students_subjects` ON students_subjects.student_id = students.id",:group=>'students.id',:conditions=>["students_subjects.subject_id=? and students.batch_id=students_subjects.batch_id",subject_id],:order=>'first_name ASC')
      else
        students= Student.all(:select=>"roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id INNER JOIN `students_subjects` ON students_subjects.student_id = students.id",:group=>'students.id',:conditions=>["students_subjects.subject_id=? and students.batch_id=students_subjects.batch_id",subject_id],:order=>sort_order)
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('admission_no') }","#{t('admission_date') }","#{t('batch_name')}","#{t('course_name')}","#{t('gender')}","#{t('fees_paid')}"]
    col_heads.insert(2,t('roll_no')) if Configuration.enabled_roll_number?
    data << col_heads
    students.each_with_index do |obj,i|
      col=[]
      col << "#{i+1}"
      col << "#{obj.full_name}"
      col << obj.roll_number if Configuration.enabled_roll_number?
      col << "#{obj.admission_no}"
      col << "#{format_date(obj.admission_date)}"
      col << "#{obj.batch_name}"
      col << "#{obj.course_name} #{obj.code}-#{obj.section_name}"
      col <<  "#{obj.gender.downcase=='m'? t('m') : t('f')}"
      col << "#{obj.fee_count.to_i!= 0? t('no_texts') : t('yes_text')}"
      col=col.flatten
      data << col
    end
    return data
  end

  def self.batch_wise_students (parameters)
    sort_order=parameters[:sort_order]
    batch_id=parameters[:batch_id]
    gender=parameters[:gender]
    batch=Batch.find batch_id
    month_date=batch.start_date.to_date
    end_date=Time.now.to_date
    config=Configuration.find_by_config_key('StudentAttendanceType')
    unless config.config_value == 'Daily'
      academic_days=batch.subject_hours(month_date, end_date, 0).values.flatten.compact.count
      unless gender.present?
        if sort_order.nil?
          students= Student.all(:select=>"students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{batch_id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id',:group=>'students.id',:conditions=>{:batch_id=>batch_id},:order=>'first_name ASC')
        else
          students= Student.all(:select=>"students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{batch_id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id',:group=>'students.id',:conditions=>{:batch_id=>batch_id},:order=>sort_order)
        end
      else
        if sort_order.nil?
          students= Student.all(:select=>"students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{batch_id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id' ,:group=>'students.id',:conditions=>["students.batch_id=? AND students.gender LIKE?",batch_id,gender],:order=>'first_name ASC')
        else
          students= Student.all(:select=>"students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{batch_id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id' ,:group=>'students.id',:conditions=>["students.batch_id=? AND students.gender LIKE?",batch_id,gender],:order=>sort_order)
        end
      end
    else
      academic_days=batch.academic_days.count
      unless gender.present?
        if sort_order.nil?
          students= Student.all(:select=>"students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{batch_id},attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL)))))/#{academic_days}*100 as percent,count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id',:group=>'students.id',:conditions=>{:batch_id=>batch_id},:order=>'first_name ASC')
        else
          students= Student.all(:select=>"students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{batch_id},attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL)))))/#{academic_days}*100 as percent,count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id',:group=>'students.id',:conditions=>{:batch_id=>batch_id},:order=>sort_order)
        end
      else
        if sort_order.nil?
          students= Student.all(:select=>"students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{batch_id},attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL)))))/#{academic_days}*100 as percent,count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id',:group=>'students.id',:conditions=>["students.batch_id=? AND students.gender LIKE ?",batch_id,gender],:order=>'first_name ASC')
        else
          students= Student.all(:select=>"students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{batch_id},attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL)))))/#{academic_days}*100 as percent,count(DISTINCT IF(finance_fees.balance > 0,finance_fees.id,NULL)) as fee_count", :joins=>'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id',:group=>'students.id',:conditions=>["students.batch_id=? AND students.gender LIKE ?",batch_id,gender],:order=>sort_order)
        end
      end
    end
    data=[]    
    unless gender.present?
      col_heads=["#{t('no_text')}","#{t('name')}","#{t('admission_no') }","#{t('admission_date') }","#{t('gender')}","#{t('attendance')}","#{t('fees_paid')}"]
      col_heads.insert(2,t('roll_no')) if Configuration.enabled_roll_number?
    else
      col_heads=["#{t('no_text')}","#{t('name')}","#{t('admission_no') }","#{t('admission_date') }","#{t('attendance')}","#{t('fees_paid')}"]
      col_heads.insert(2,t('roll_no')) if Configuration.enabled_roll_number?
    end
    data << col_heads
    students.each_with_index do |obj,i|
      col=[]
      col << "#{i+1}"
      col << "#{obj.full_name}"
      col << obj.roll_number if Configuration.enabled_roll_number?
      col << "#{obj.admission_no}"
      col << "#{format_date(obj.admission_date)}"
      unless gender.present?
        col <<  "#{obj.gender.downcase=='m'? t('m') : t('f')}"
      end
      col << "#{obj.percent.to_f.round(2)}"
      col << "#{obj.fee_count.to_i!= 0? t('no_texts') : t('yes_text')}"
      col=col.flatten
      data << col
    end
    return data
  end

  def self.course_wise_students(parameters)
    sort_order=parameters[:sort_order]
    course_id=parameters[:course_id]
    gender=parameters[:gender]
    unless gender.present?
      if sort_order.nil?
        students= Student.all(:select=>"roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",:group=>'students.id',:conditions=>{:courses=>{:id=>course_id}},:order=>'first_name ASC')
      else
        students= Student.all(:select=>"roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",:group=>'students.id',:conditions=>{:courses=>{:id=>course_id}},:order=>sort_order)
      end
    else
      if sort_order.nil?
        students= Student.all(:select=>"roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",:group=>'students.id',:conditions=>["courses.id=? AND students.gender LIKE ?" ,course_id,gender],:order=>'first_name ASC')
      else
        students= Student.all(:select=>"roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count",:joins=>"INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",:group=>'students.id',:conditions=>["courses.id=? AND students.gender LIKE ?" ,course_id,gender],:order=>sort_order)
      end
    end
    data=[]
    unless gender.present?
      col_heads=["#{t('no_text')}","#{t('name')}","#{t('admission_no') }","#{t('admission_date') }","#{t('batch_name')}","#{t('gender')}","#{t('fees_paid')}"]
      col_heads.insert(2,t('roll_no')) if Configuration.enabled_roll_number?
    else
      col_heads=["#{t('no_text')}","#{t('name')}","#{t('admission_no') }","#{t('admission_date') }","#{t('batch_name')}","#{t('fees_paid')}"]
      col_heads.insert(2,t('roll_no')) if Configuration.enabled_roll_number?
    end
    data << col_heads
    students.each_with_index do |obj,i|
      col=[]
      col << "#{i+1}"
      col << "#{obj.full_name}"
      col << "#{obj.roll_number}" if Configuration.enabled_roll_number?
      col << "#{obj.admission_no}"
      col << "#{format_date(obj.admission_date)}"
      col << "#{obj.batch_name}"
      unless gender.present?
        col <<  "#{obj.gender.downcase=='m'? t('m') : t('f')}"
      end
      col << "#{obj.fee_count.to_i!= 0? t('no_texts') : t('yes_text')}"
      col=col.flatten
      data << col
    end
    return data
  end

  def self.students_fee_defaulters(parameters)
    sort_order=parameters[:sort_order]
    fee_collection_id=parameters[:fee_collection_id]
    batch_id=parameters[:batch_id]
    transaction_class=parameters[:transaction_class]
    if sort_order.nil?
      if transaction_class=="HostelFeeCollection"
        students=Student.all(:select=>"students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,rent as balance",:joins=>[:hostel_fees] ,:conditions=>["hostel_fees.hostel_fee_collection_id=? and hostel_fees.finance_transaction_id is NULL",fee_collection_id],:order=>"balance DESC")
      elsif transaction_class=="TransportFeeCollection"
        students=Student.all(:select=>"students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,bus_fare as balance",:joins=>"INNER JOIN transport_fees on transport_fees.receiver_id=students.id" ,:conditions=>["transport_fees.transport_fee_collection_id=? and transport_fees.transaction_id is NULL",fee_collection_id],:order=>"balance DESC")
      else
        students=Student.all(:select=>"students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance",:joins=>[:finance_fees] ,:conditions=>["finance_fees.fee_collection_id=? and finance_fees.balance !=? and finance_fees.batch_id=?",fee_collection_id,0.0,batch_id],:order=>"balance DESC")
      end
    else
      if transaction_class=="HostelFeeCollection"
        students=Student.all(:select=>"students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,rent as balance",:joins=>[:hostel_fees] ,:conditions=>["hostel_fees.hostel_fee_collection_id=? and hostel_fees.finance_transaction_id is NULL",fee_collection_id],:order=>sort_order)
      elsif transaction_class=="TransportFeeCollection"
        students=Student.all(:select=>"students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,bus_fare as balance",:joins=>"INNER JOIN transport_fees on transport_fees.receiver_id=students.id" ,:conditions=>["transport_fees.transport_fee_collection_id=? and transport_fees.transaction_id is NULL",fee_collection_id],:order=>sort_order)
      else
        students=Student.all(:select=>"students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance",:joins=>[:finance_fees] ,:conditions=>["finance_fees.fee_collection_id=? and finance_fees.balance !=? and finance_fees.batch_id=?",fee_collection_id,0.0,batch_id],:order=>sort_order)
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('admission_no')}","#{t('admission_date')}","#{t('balance')}(#{ Configuration.currency})"]
    col_heads.insert(2,t('roll_no')) if Configuration.enabled_roll_number?
    data << col_heads
    students.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.full_name}"
      col<< s.roll_number if Configuration.enabled_roll_number?
      col<< "#{s.admission_no}"
      col<< "#{format_date(s.admission_date)}"
      col<< "#{s.balance.nil?? 0 : s.balance}"
      col=col.flatten
      data<< col
    end
    return data
  end

  def self.students_wise_fee_defaulters(parameters)
    sort_order=parameters[:sort_order]||nil
    students=Student.all(:select=>'students.roll_number,students.id,students.admission_no,students.first_name,students.middle_name,students.last_name,students.batch_id,sum(balance) balance,count(IF(balance>0,balance,NULL)) fee_collections_count',:joins=>"INNER JOIN #{derived_sql_table} finance on finance.student_id=students.id",:group=>'students.id',:include=>{:batch=>:course},:order=>sort_order)
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('admission_no') }","#{t('course_name')}","#{t('batch_name')}","#{t('fee_collections')}","#{t('balance')}(#{ Configuration.find_by_config_key("CurrencyType").config_value})"]
    col_heads.insert(2,t('roll_no')) if Configuration.enabled_roll_number?
    data << col_heads
    students.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.full_name}"
      col<< "#{s.roll_number}" if Configuration.enabled_roll_number?
      col<< "#{s.admission_no}"
      col<< "#{s.batch.course_name} #{s.batch.code} #{s.batch.section_name}"
      col<< "#{s.batch.name}"
      col<< "#{s.fee_collections_count}"
      col<< "#{precision_label(s.balance) }"
      col=col.flatten
      data<< col
    end
    return data
  end

  def self.student_wise_fee_collections(parameters)
    student_id=parameters[:student_id]
    fee_collections = FinanceFeeCollection.all(:select => "finance_fee_collections.name,finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,balance", :joins => "LEFT OUTER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id INNER JOIN students on students.id=finance_fees.student_id", :conditions => ["students.id=? and finance_fee_collections.is_deleted=? and finance_fee_collections.due_date < ? and finance_fees.balance > ?", student_id, false,Date.today,0.0], :order => 'balance DESC')
    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      fee_collections+= HostelFeeCollection.all(:select => "name,start_date,end_date,due_date,hostel_fees.rent as balance", :joins => [:hostel_fees], :conditions => ["`hostel_fee_collections`.`is_deleted` = ? AND `hostel_fees`.`student_id` = ? AND `hostel_fees`.`finance_transaction_id` IS NULL and hostel_fees.rent > ? AND hostel_fee_collections.due_date < ?",false,student_id,0.0,Date.today], :order => "balance DESC")
    end
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      fee_collections+= TransportFeeCollection.all(:select => "transport_fee_collections.id,name,start_date,end_date,due_date,transport_fees.bus_fare as balance", :joins => "INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id", :conditions => ["transport_fee_collections.is_deleted = ? AND `transport_fees`.`receiver_id` = ? AND `transport_fees`.`receiver_type` = 'Student' AND `transport_fees`.`transaction_id` IS NULL and transport_fees.bus_fare > ? AND transport_fee_collections.due_date < ?",false,student_id,0.0,Date.today], :order => "balance DESC")
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('start_date')}","#{t('end_date')}","#{t('due_date')}","#{t('balance')}(#{Configuration.find_by_config_key("CurrencyType").config_value})"]
    data << col_heads
    fee_collections.each_with_index do |b,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{b.name}"
      col<< "#{format_date(b.start_date.to_date)}"
      col<< "#{format_date(b.end_date.to_date)}"
      col<< "#{format_date(b.due_date.to_date)}"
      col<< "#{b.balance.nil?? 0 : b.balance}"
      col=col.flatten
      data<< col
    end
    return data
  end

  
  def self.fetch_student_advance_search_result(params)
    student_advanced_search params
  end
  
  def previous_batch
    batch_students.sort_by{|s| s.updated_at||50.years.ago}.last
  end

  def subject_exam(sub_id)
    exam_scores.select{|e| e.try(:exam).try(:subject_id) == sub_id}.empty?
  end

  def revert_batch_transfer_eligiblity
    warning_messages=[]
    warning_messages << "#{t('elective_subjects_are_assigned')}" unless students_subjects.select{|s| s.try(:batch_id) ==  batch_id}.empty?
    warning_messages << "#{t('fees_are_already_assigned')}" unless finance_fees.select{|f| f.try(:batch_id) == batch_id}.empty?
    warning_messages << "#{t('already_appeared_for_exam')}" unless exam_scores.select{|e| e.try(:exam).try(:exam_group).try(:batch_id) == batch_id}.empty?
    warning_messages << "#{t('attendance_are_already_marked')}" unless subject_leaves.select{|s| s.try(:batch_id) == batch_id}.empty? and attendances.select{|a| a.try(:batch_id) == batch_id}.empty?
    DependencyHook.check_dependency_for(self,:only => [:transport_batch_fee,:hostel_batch_fee,:assigned_assignments,:online_batch_exams,:batch_poll_votes]).each do |dependency|
      warning_messages << dependency.warning unless dependency.result
    end
    return warning_messages
  end
  def full_name_with_admission_no
    "#{full_name} &#x200E;(#{admission_no})&#x200E;"
  end
  def full_name_with_roll_no
    "#{full_name} &#x200E;- #{roll_number}&#x200E;"
  end
  def name_for_particular_wise_discount
    " &#x200E;(#{full_name})&#x200E;"
  end
  def batch_update
    self.has_paid_fees_for_batch=0
  end

  def self.get_grades(marks)
    marks = marks.to_f
      if marks >= 90 
        "A+"
      elsif (marks < 90 && marks >= 80) 
        "A"
      elsif  (marks < 80 && marks >= 70) 
        "B+"
      elsif (marks < 70 && marks >= 60) 
        "B"
      elsif (marks < 60 && marks >= 50) 
        "C"
      elsif (marks < 50 && marks >= 40) 
        "D"
      else 
        "F"
     end 
  end
  
  def is_horizontal_invoice_design?
    bank_detail = BankDetail.find_by_school_id(school.id) rescue nil
    invoice_status = (bank_detail.invoice_design == "Horizontal" ? true : false) rescue false
    return invoice_status
  end
end

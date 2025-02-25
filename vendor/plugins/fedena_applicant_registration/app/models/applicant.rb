
class Applicant < ActiveRecord::Base
  require 'set'
  require 'fileutils'


  serialize :subject_ids
  serialize :normal_subject_ids
  
  has_one :applicant_guardian,:autosave=>true
  has_one :applicant_previous_data,:autosave=>true
  has_many :applicant_addl_values
  has_many :applicant_additional_details, :dependent => :destroy
  
  belongs_to :registration_course
  belongs_to :country
  belongs_to :nationality,:class_name=>"Country"

  validates_presence_of :first_name,:registration_course_id,:date_of_birth,:gender,:last_name
  validates_presence_of :subject_ids,:if => :is_subject_based_and_minimum_electives_is_not_zero

  validates_format_of  :email, :with => /^[\+A-Z0-9\._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i,:if=>:check_email, :message => :must_be_a_valid_email_address

  before_create :generate_reg_no
  #  before_save :check_course_is_active
  before_create :set_pending_status

  after_create :save_print_token
  before_save :verify_precision

  def verify_precision
    self.amount = FedenaPrecision.set_and_modify_precision self.amount
  end
  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']
  has_attached_file :photo,
    :styles => {:original=> "125x125#"},
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :default_url => "master_student/profile/default_student.png",
    :reject_if => proc { |attributes| attributes.present? },
    :max_file_size => 512000,
    :permitted_file_types =>VALID_IMAGE_TYPES
  
  validates_attachment_content_type :photo, :content_type =>VALID_IMAGE_TYPES,
    :message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.photo_file_name.blank? }
  validates_attachment_size :photo, :less_than => 512000,\
    :message=>'must be less than 500 KB.',:if=> Proc.new { |p| p.photo_file_name_changed? }

  has_many :applicant_addl_attachments
  accepts_nested_attributes_for :applicant_addl_attachments, :allow_destroy => true , :reject_if => lambda { |a| a.values.all?(&:blank?) }
  accepts_nested_attributes_for :applicant_additional_details


  attr_accessor :addl_field

  def is_subject_based_and_minimum_electives_is_not_zero
    self.registration_course.is_subject_based_registration.to_s == "true" and self.registration_course.min_electives!=0
  end

  def validate
    check_mandatory_fields
    subject_count = subject_ids.nil? ? 0 : subject_ids.count
    min_subject_count = registration_course.min_electives.nil? ? 0 : registration_course.min_electives
    max_subject_count = registration_course.max_electives.nil? ? 0 : registration_course.max_electives
    if subject_count < min_subject_count or subject_count > max_subject_count
      errors.add_to_base :select_elective_range
    end

    errors.add(:date_of_birth, :cannot_be_future) if date_of_birth > Date.today
  end

  #  def before_save
  #    if registration_course.subject_based_fee_colletion == true
  #      all_subjects = subject_ids
  #      all_subjects += normal_subject_ids unless normal_subject_ids.nil?
  #      total_amount = registration_course.course.subject_amounts.find(:all,:conditions => {:code => all_subjects}).flatten.compact.map(&:amount).sum
  #      self.amount = total_amount.to_f
  #    else
  #      self.amount = registration_course.amount.to_f
  #    end
  #  end


  def set_pending_status
    self.status="pending"
  end

  def check_email
    !email.blank?
  end

  #  def check_course_is_active
  #    unless self.registration_course.is_active
  #      errors.add_to_base :error1
  #      false
  #    else
  #      true
  #    end
  #  end

  def generate_reg_no
    last_reg_no = Applicant.last
    if last_reg_no
      last_reg_no = Applicant.last.reg_no.to_i
    else
      last_reg_no = 0
    end
    self.reg_no = last_reg_no.next
  end

  def full_name
    first_name + " " + last_name
  end

  def gender_as_text
    return "Male" if gender.downcase == "m"
    return "Female" if gender.downcase == "f"
  end

  def admit(batchid)
    flag = 0
    msg = []
    if self.registration_course.enable_approval_system == true
      if self.is_academically_cleared == true and self.is_financially_cleared == true
        unless self.status=="alloted"
          attr = self.attributes
          ["id","created_at","updated_at","status","reg_no","registration_course_id","applicant_previous_data_id",\
              "school_id","applicant_guardians_id","has_paid","photo_file_size","photo_file_name","photo_content_type","pin_number","print_token","subject_ids","is_academically_cleared","is_financially_cleared","amount","normal_subject_ids"].each{|a| attr.delete(a)}
          student = Student.new(attr)
          app_prev_data = self.applicant_previous_data
          if app_prev_data.present? and app_prev_data.last_attended_school.present?
            prev_data = student.build_student_previous_data(:institution=>app_prev_data.last_attended_school,\
                :year=>"#{app_prev_data.qualifying_exam_year}",
              :course=>"#{app_prev_data.qualifying_exam}(#{app_prev_data.qualifying_exam_roll})",
              :total_mark=>app_prev_data.qualifying_exam_final_score	)
          end
          if self.applicant_guardian.present?
            guardian_attr = self.applicant_guardian.attributes
            ["created_at","updated_at","applicant_id","school_id"].each{|a| guardian_attr.delete(a)}
            guardian = student.guardians.new(guardian_attr)
          end
          batch = Batch.find(batchid)
          if registration_course.is_subject_based_registration == true
            subject_codes = Set.new(batch.subjects.all(:conditions => {:is_deleted => false}).map(&:code))
            applicant_subject_codes = Set.new(((subject_ids.nil? ? [] : subject_ids) + (normal_subject_ids.nil? ? [] : normal_subject_ids)).compact.flatten)
            if applicant_subject_codes.subset?(subject_codes)
              student.batch_id = batch.id
              subjects = student.batch.subjects.find(:all,:conditions => {:code => subject_ids})
              subjects.map{|subject| student.students_subjects.build(:batch_id => student.batch_id,:subject_id => subject.id)}
            else
              student.errors.add_to_base :batch_not_contain_the_applicant_choosen
            end
          else
            student.batch_id = batchid
          end
          student.admission_no = User.next_admission_no("student")||"#{batch.course.code}-#{Date.today.year}-1"
          student.admission_date = Date.today
          student.photo = self.photo if self.photo.file?
          if student.errors.blank? and student.save
            msg << "#{t('alloted_to')}"
            flag = 1
            if guardian
              guardian.ward_id= student.id
              guardian.save
              student.immediate_contact_id = guardian.id
              student.save
            end
            if self.applicant_addl_attachments.present? and self.registration_course.transfer_documents
              attachments = self.applicant_addl_attachments
              attachments.each do |att|
                s =  StudentAddlAttachment.new
                s.attachment = att.attachment
                s.student_id = student.id
                s.save
              end
            end
            prev_data.save if prev_data
            self.status = "alloted"
            self.save
          else
            msg << student.errors.full_messages
          end
        else
          msg << "#{t('applicant')} ##{self.reg_no} #{t('already_alloted')}"
        end
      else
        msg << "#{t('applicant')} ##{self.reg_no} #{t('not_cleared')}"
      end
    else
      unless self.status=="alloted"
        attr = self.attributes
        ["id","created_at","updated_at","status","reg_no","registration_course_id","applicant_previous_data_id",\
            "school_id","applicant_guardians_id","has_paid","photo_file_size","photo_file_name","photo_content_type","pin_number","print_token","subject_ids","is_academically_cleared","is_financially_cleared","amount","normal_subject_ids"].each{|a| attr.delete(a)}
        student = Student.new(attr)
        app_prev_data = self.applicant_previous_data
        if app_prev_data.present? and app_prev_data.last_attended_school.present?
          prev_data = student.build_student_previous_data(:institution=>app_prev_data.last_attended_school,\
              :year=>"#{app_prev_data.qualifying_exam_year}",
            :course=>"#{app_prev_data.qualifying_exam}(#{app_prev_data.qualifying_exam_roll})",
            :total_mark=>app_prev_data.qualifying_exam_final_score	)
        end
        if self.applicant_guardian.present?
          guardian_attr = self.applicant_guardian.attributes
          ["created_at","updated_at","applicant_id","school_id"].each{|a| guardian_attr.delete(a)}
          guardian = student.guardians.new(guardian_attr)
        end
        batch = Batch.find(batchid)
        if registration_course.is_subject_based_registration == true
          subject_codes = Set.new(batch.subjects.all(:conditions => {:is_deleted => false}).map(&:code))
          applicant_subject_codes = Set.new(((subject_ids.nil? ? [] : subject_ids) + (normal_subject_ids.nil? ? [] : normal_subject_ids)).compact.flatten)
          if applicant_subject_codes.subset?(subject_codes)
            student.batch_id = batch.id
            subjects = student.batch.subjects.find(:all,:conditions => {:code => subject_ids})
            subjects.map{|subject| student.students_subjects.build(:batch_id => student.batch_id,:subject_id => subject.id)}
          else
            student.errors.add_to_base :batch_not_contain_the_applicant_choosen
          end
        else
          student.batch_id = batchid
        end
        student.admission_no = User.next_admission_no("student")||"#{batch.course.code}-#{Date.today.year}-1"
        student.admission_date = Date.today
        student.photo = self.photo if self.photo.file?
        if student.errors.blank? and student.save
          msg << "#{t('alloted_to')}"
          flag = 1
          if guardian
            guardian.ward_id= student.id
            guardian.save
            student.immediate_contact_id = guardian.id
            student.save
          end
                       
          if self.applicant_addl_attachments.present? and self.registration_course.transfer_documents
            attachments = self.applicant_addl_attachments
            attachments.each do |att|
              s =  StudentAddlAttachment.new
              s.attachment = att.attachment
              s.student_id = student.id
              s.save
            end
          end
          prev_data.save if prev_data
          self.status = "alloted"
          self.save
        else
          msg << student.errors.full_messages
        end
      else
        msg << "#{t('applicant')} ##{self.reg_no} #{t('already_alloted')}"
      end
    end
    copy_additional_details(student) unless student.nil?
    [msg,flag]
  end

  def copy_additional_details(student)
    if registration_course.include_additional_details == true
      applicant_additional_details.each do |applicant_additional_detail|
        unless applicant_additional_detail.additional_field.nil?
          student.student_additional_details.build(:additional_field_id => applicant_additional_detail.additional_field_id,:additional_info => applicant_additional_detail.additional_info)
        end
      end
      student.save
    end
  end
  
  def self.process_search_params(s)
    course_min_score = RegistrationCourse.find(s[:registration_course_id])
    if s[:status]=="eligible"
      s[:applicant_previous_data_qualifying_exam_final_score_gte]=course_min_score.minimum_score
      s.delete(:status)
    elsif s[:status]=="noteligible"
      s[:applicant_previous_data_qualifying_exam_final_score_lte]=course_min_score.minimum_score
      s.delete(:status)
    end
    s
  end

  def self.commit(ids,batchid,act)
    if act.downcase=="allot"
      allot_to(ids,batchid)
    elsif act.downcase=="discard"
      discard(ids)
    end
  end

  def self.search_by_order(registration_course, sorted_order, search_by)

    condition_keys = "registration_course_id = ?"
    condition_values = []
    condition_values << registration_course

    all_conditions=[]
    if search_by[:status].present?
      if search_by[:status]=="pending" or search_by[:status]=="alloted" or search_by[:status]=="discarded"
        condition_keys+=" and status = ?"
        condition_values << search_by[:status]
      end
    end
    if search_by[:created_at_gte].present?
      condition_keys+=" and created_at >= ?"
      condition_values << search_by[:created_at_gte].to_time.beginning_of_day
    end
    if search_by[:created_at_lte].present?
      condition_keys+=" and created_at <= ?"
      condition_values << search_by[:created_at_lte].to_time.end_of_day
    end

    all_conditions << condition_keys
    all_conditions += condition_values

    case sorted_order
    when "reg_no-descend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "reg_no desc")
    when "reg_no-ascend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "reg_no asc")
    when "name-descend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "first_name desc")
    when "name-ascend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "first_name asc")
    when "da_te-descend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "created_at desc")
    when "da_te-ascend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "created_at asc")
    when "status-descend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "status desc")
    when "status-ascend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "status asc")
    when "paid-descend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "has_paid desc")
    when "paid-ascend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "has_paid asc")
    else
      applicants=self.find(:all, :conditions=>all_conditions)
    end
    if search_by[:status]=="eligible"
      registration_course_data = RegistrationCourse.find_by_id(registration_course)
      unless registration_course_data.nil?
        applicants.reject!{|a| !(a.applicant_previous_data.present? and a.applicant_previous_data.qualifying_exam_final_score.to_i >=registration_course_data.minimum_score.to_i )}
      end
    elsif search_by[:status]=="noteligible"
      registration_course_data = RegistrationCourse.find_by_id(registration_course)
      unless registration_course_data.nil?
        applicants = applicants.select{|a| !(a.applicant_previous_data.present? and a.applicant_previous_data.qualifying_exam_final_score.to_i >= registration_course_data.minimum_score.to_i )}
      end
    end
    return applicants
  end

  def self.allot_to(ids,batchid)
    errs = []
    if ids.kind_of?(Array)
      apcts = self.find(ids)
      apcts.each do |apt|
        errs <<  apt.admit(batchid).first
      end
      errs
    elsif ids.kind_of?(Integer)
      self.find(ids).admit(batchid)
    else
      false
    end
  end



  def self.discard(ids)
    if ids.kind_of?(Array)
      self.update_all({:status=>"discarded"},{:id=>ids})
    elsif ids.kind_of?(Integer)
      self.find(ids).update_attributes(:status=>"discarded")
    else
      false
    end
    [[t('selected_applicants_discarded_successfully')],1]
  end

  def mark_paid
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
      if @active_gateway.nil?
        transaction = create_finance_transaction_entry
        return transaction
      else
        transaction = create_finance_transaction_entry("Online Payment")
      end
    else
      transaction = create_finance_transaction_entry
    end
    transaction
  end

  def create_finance_transaction_entry(payment_mode=String.new)
    transaction = FinanceTransaction.new
    transaction.title = "Applicant Registration - #{self.reg_no} - #{self.full_name}"
    transaction.category_id = FinanceTransactionCategory.find_by_name('Applicant Registration').id
    transaction.amount = amount
    transaction.fine_included = false
    transaction.transaction_date = Date.today
    transaction.payee = self
    transaction.finance = self.registration_course
    transaction.save
    if registration_course.enable_approval_system == true
      self.update_attributes(:has_paid=>true,:is_financially_cleared => true)
    else
      self.update_attributes(:has_paid=>true)
    end
    transaction
  end



  def mark_academically_cleared
    self.update_attributes(:is_academically_cleared => true)
  end


  def addl_fields
    @addl_field || {}
  end

  def addl_fields=(vals)
    @addl_field = vals
    vals.each_with_index do |(k,v),i|
      v = v.join(",") if v.kind_of?(Array)
      opt = self.applicant_addl_values.find(:first,:conditions=>{:applicant_addl_field_id=>k})
      unless opt.blank?
        opt.update_attributes(:option=>v)
      else
        self.applicant_addl_values.build(:applicant_addl_field_id=>k,:option=>v)
      end
    end
  end

  def addl_field_hash
    hsh={}
    self.applicant_addl_values.each do |a|
      hsh["#{a.applicant_addl_field_id}"] = a.reverse_value
    end
    @addl_field = hsh
  end

  def check_mandatory_fields
    fields=[]
    man_fields = self.registration_course.applicant_addl_field_groups.active
    man_fields.map{|f| fields <<  f.applicant_addl_fields.mandatory}
    fields.flatten.each do |f|
      errors.add_to_base("#{f.field_name} #{t('is_invalid')}") if @addl_field and @addl_field["#{f.id}"].blank?
    end
    errors.blank?
  end

  def save_print_token
    token = rand.to_s[2..8]
    self.update_attributes(:print_token => token)
  end

  def finance_transaction
    FinanceTransaction.first(:conditions=>{:payee_id=>self.id,:payee_type=>'Applicant'})
  end

  def self.applicant_registration_data(params)
    search_by =""
    if params[:search].present?
      search_by=params[:search]
    end
    @sort_order=""
    if params[:sort_order].present?
      @sort_order=params[:sort_order]
    end
    @results=Applicant.search_by_order(params[:id], @sort_order, search_by)
    if @sort_order==""
      @results = @results.sort_by { |u1| [u1.status,u1.created_at.to_date] }.reverse if @results.present?
    end
    @applicants = @results
    @course = RegistrationCourse.find(params[:id]).course
    data = []
    data << ["#{t('course')}" + ":" + @course.course_name]
    data << ["#{t('applicants.reg_no')}","#{t('name')}","#{t('applicants_admins.da_te')}","#{t('status')}","#{t('applicants_admins.paid')}"]
    @applicants.each do |applicant|
      data << [applicant.reg_no,applicant.full_name,(format_date(applicant.created_at.to_date) unless applicant.created_at.nil?),applicant.status,(applicant.has_paid? ? t('applicants_admins.y_es') : t('applicants_admins.n_o'))]
    end
    return data
  end

  def self.search_by_registration_data(params)
    @registration_no = params[:reg_no]
    @results = Applicant.search(:reg_no_begins_with => @registration_no)
    @applicants = @results.all
    data = []
    data << [t('applicants.reg_no'),t('course_name'),t('name'),t('applicants_admins.registration_date'),t('status'),t('applicants_admins.has_paid_fees')]
    @applicants.each do |applicant|
      data << [applicant.reg_no,applicant.registration_course.try(:course).try(:full_name),applicant.full_name,(format_date(applicant.created_at.to_date) unless applicant.created_at.nil?),applicant.status,(applicant.has_paid? ? t('applicants_admins.y_es') : t('applicants_admins.n_o'))]
    end
    return data
  end
end

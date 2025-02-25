class RegistrationCourse < ActiveRecord::Base
  serialize :additional_field_ids
  belongs_to :course
  delegate :course_name,:code,:to=>:course,:prefix=>false,:allow_nil=>true

  validates_presence_of :course_id,:minimum_score
  validates_presence_of :min_electives,:max_electives, :if => :is_subject_based
  validates_uniqueness_of :course_id,:message=>:already_added

  validates_numericality_of :minimum_score
  validates_numericality_of :min_electives,:max_electives, :if => :is_subject_based
  validates_numericality_of :amount,:unless => :is_subject_based
  

  named_scope :active,{:conditions=>{:is_active=>true}}

  has_many :applicant_addl_field_groups

  def before_destroy
    if PinGroup.all.map(&:course_ids).flatten.uniq.include? "#{id}" or Applicant.all.map(&:registration_course_id).include? id
      errors.add_to_base :registration_course_is_in_use_and_cannot_be_deleted
      false
    else
      true
    end
  end


  def is_subject_based
    self.is_subject_based_registration.to_s == "true"
  end

  def asset_field_names
    hsh=ActiveSupport::OrderedHash.new(applicant_addl_fields.first. make_hash_default_name)
    related_options=[]
    applicant_addl_fields.each do |af|
      case af.field_type
      when 'belongs_to'
        hsh[af.field_name.downcase.gsub(' ','_')+"_id"]=af.attributes
        hsh[af.field_name.downcase.gsub(' ','_')+"_id"].merge!({"related"=>af.field_name.downcase.gsub(' ','_')})
        related_options=af.asset_field_options.map{|ae| [ae.default_field,ae.id]}
        hsh[af.field_name.downcase.gsub(' ','_')+"_id"].merge!({"related_options"=>related_options})
      when 'has_many'
        hsh[af.field_name.downcase.gsub(' ','_')+"_ids"]=af.attributes
        hsh[af.field_name.downcase.gsub(' ','_')+"_ids"].merge!({"related"=>af.field_name.downcase.gsub(' ','_')+"s"})
        related_options=af.asset_field_options.map{|ae| [ae.default_field,ae.id]}
        hsh[af.field_name.downcase.gsub(' ','_')+"_ids"].merge!({"related_options"=>related_options})
      else
        hsh[af.field_name.downcase.gsub(' ','_')]=af.attributes
      end
    end
    hsh
  end

  def manage_pin_system(status)
    @course_pin = CoursePin.find_by_course_id(course_id)
    if @course_pin.nil?
      @course_pin = CoursePin.create(:course_id => course_id,:is_pin_enabled => status)
    else
      @course_pin.update_attributes(:is_pin_enabled => status)
    end
  end
  def validate
    if self.is_subject_based_registration?
      unless self.course.nil?
        if self.course.batches.map(&:all_elective_subjects).flatten.compact.map(&:code).compact.flatten.uniq.blank?
          errors.add_to_base :no_elective_subjects
          return false
        elsif self.min_electives.to_i > self.max_electives.to_i
          errors.add_to_base :min_cannot_be_greater_than_max
        else
          return true
        end
      else
        return false
      end
    end
    
  end
end

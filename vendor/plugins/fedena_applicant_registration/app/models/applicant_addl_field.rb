class ApplicantAddlField < ActiveRecord::Base

  validates_presence_of :field_name, :field_type
  validates_uniqueness_of :field_name, :scope => :applicant_addl_field_group_id

  has_many :applicant_addl_field_values,:dependent => :destroy
  accepts_nested_attributes_for :applicant_addl_field_values, :allow_destroy => true

  belongs_to :applicant_addl_field_group

  named_scope :active,{:conditions=>{:is_active=>true}}
  named_scope :mandatory,{:conditions=>{:is_active=>true,:is_mandatory=>true}}

  before_update :check_if_already_in_use
  before_destroy :check_if_already_in_use

  acts_as_list :scope =>:applicant_addl_field_group_id

  default_scope :order=>:position

  def validate
    errors.add(:field_name,t('reserved_word')) if (RegistrationCourse.instance_methods+methods).include? :field_name
    errors.add(:field_name,t('id_ids')) if("#{field_name}".ends_with? t('i_d') or "#{field_name}".ends_with? t('i_ds'))
  end
  
  def make_hash_default_name
    case field_type
    when 'belongs_to'
      field_name.downcase.gsub(' ','_')+"_id"
    when 'has_many'
      field_name.downcase.gsub(' ','_')+"_ids"
    else
      field_name.downcase.gsub(' ','_')
    end
  end

  def get_field_type
    case field_type
    when 'belongs_to'
      "Select Box"
    when 'has_many'
      "Check Box"
    else
      "Text Box"
    end
  end

  def allow_edit
    if self.changes.count ==1
      !(self.changes.include?("is_active") or self.changes.include?("position"))
    else
      false
    end
  end

  def check_if_already_in_use
    if allow_edit
      #unless check_allowed_edit_params
        if ApplicantAddlValue.exists?(:applicant_addl_field_id=>self.id)
          errors.add_to_base:additional_field_is_already_in_use
          false
        else
          true
        end
      #end
    end
  end

  def move(order)
    self.move_higher if order =="up"
    self.move_lower if order =="down"
  end
  
end

class ApplicantAdditionalDetail < ActiveRecord::Base
  belongs_to :applicant
  belongs_to :additional_field,:class_name => "StudentAdditionalField"

  validates_presence_of :additional_field_id

  def validate
    unless self.additional_field.nil?
      if self.additional_field.is_mandatory == true
        unless self.additional_info.present?
          errors.add("additional_info","can't be blank")
        end
      end
    else
      errors.add('student_additional_field',"can't be blank")
    end
  end

  def before_save
    unless self.additional_info.present?
      return false
    end
  end
end

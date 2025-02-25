class ApplicantAddlValue < ActiveRecord::Base



  belongs_to :registration_course
  belongs_to :applicant_addl_field
  belongs_to :applicant

  def value
    if self.applicant_addl_field
      if self.applicant_addl_field.field_type == "has_many" or  self.applicant_addl_field.field_type == "belongs_to"
        ApplicantAddlFieldValue.find(:all,:conditions=>{:id=>option.split(",")}).map{|o| o.option}.join(",")
      else
        option
      end
    else
      ""
    end
  end

  def reverse_value
   if self.applicant_addl_field
    if self.applicant_addl_field.field_type == "has_many" or  self.applicant_addl_field.field_type == "belongs_to"
      s= option.split(",")
      if s.count>1
        s
      else
        option
      end
    else
      option
    end
   end
  end
 
end

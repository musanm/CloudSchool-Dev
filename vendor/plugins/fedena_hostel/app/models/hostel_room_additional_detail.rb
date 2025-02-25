class HostelRoomAdditionalDetail < ActiveRecord::Base
  belongs_to :linkable ,:polymorphic=>true
  belongs_to :hostel_room_additional_field
   
  def validate
    if self.hostel_room_additional_field.is_active == true
      unless self.hostel_room_additional_field.nil?
        if self.hostel_room_additional_field.is_mandatory == true
          if self.additional_info == "" or self.additional_info == [nil] or self.additional_info.nil?
            errors.add("additional_info","can't be blank")
          end
        end
      else
        errors.add('hostel_additional_field',"can't be blank")
      end
    end
  end
end

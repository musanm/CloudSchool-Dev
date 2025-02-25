class RouteVehicleAdditionalDetail < ActiveRecord::Base
  belongs_to :linkable ,:polymorphic=>true
  belongs_to :route_vehicle_additional_field
  
  def validate
    if self.route_vehicle_additional_field.is_active == true
      unless self.route_vehicle_additional_field.nil?
        if self.route_vehicle_additional_field.is_mandatory == true
          if self.additional_info == "" or self.additional_info == [nil] or self.additional_info.nil?
            errors.add("additional_info","can't be blank")
          end
        end
      else
        errors.add('book_additional_field',"can't be blank")
      end
    end
  end
end

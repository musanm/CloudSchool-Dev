class Vehicle < ActiveRecord::Base
  belongs_to :main_route, :class_name => "Route"
  has_many :transports
  has_many :route_vehicle_additional_details, :as=>:linkable,:dependent => :destroy
  accepts_nested_attributes_for :route_vehicle_additional_details,:allow_destroy=>true
  validates_presence_of :vehicle_no, :main_route, :no_of_seats
  validates_uniqueness_of :vehicle_no
  validates_format_of :vehicle_no, :with => /^[A-Za-z0-9 -]+$/
  validates_numericality_of :no_of_seats
  validates_format_of :status, :with => /^[A-Za-z]+$/, :allow_blank => true
  before_destroy :check_dependencies_for_destroy
  before_update :check_dependencies_for_save
  after_save :delete_nil_additional_details

  def delete_nil_additional_details
    self.route_vehicle_additional_details.each do |detail|
      detail.destroy if detail.additional_info.nil? or detail.additional_info.blank?
    end
  end


  def route_vehicle_additional_details_attributes=(attrs)
    unless self.new_record?
      attrs.each{|k,attr|
        (attrs[k]['_delete']=true if (attrs[k]['additional_info'].blank? and RouteVehicleAdditionalField.find_by_id(attr['route_vehicle_additional_field_id']).is_mandatory==false) if attrs[k]['additional_info'].is_a? String)
        (attrs[k]['additional_info'].each_with_index{|v,i| attrs[k]['additional_info'][i] = nil if v.blank?}
          attrs[k]['_delete']=true if (attr['additional_info'].compact.blank? and RouteVehicleAdditionalField.find_by_id(attr['route_vehicle_additional_field_id']).is_mandatory==false)
          attrs[k]['additional_info'] = attr['additional_info'].compact.join(',')) if attr['additional_info'].is_a? Array
      }
    else
      attrs.each{|k,attr|
        (attrs[k]['additional_info']=nil if attrs[k]['additional_info'].blank?) if attrs[k]['additional_info'].is_a? String
        (attrs[k]['additional_info'].each_with_index{|v,i| attrs[k]['additional_info'][i] = nil if v.blank?}
          attrs[k]['additional_info'] = attr['additional_info'].compact.join(',')) if attr['additional_info'].is_a? Array
      }
    end
    assign_nested_attributes_for_collection_association(:route_vehicle_additional_details, attrs)
  end

  def check_dependencies_for_destroy
    if Transport.exists? :vehicle_id=>(self.id)
      errors.add_to_base :travellers_exist_cannot_delete_vehicle
      return false
    end
  end

  def check_dependencies_for_save
    find = Vehicle.find_by_id(self.id)
    if Transport.exists? :vehicle_id=>(self.id) and find.main_route_id != self.main_route_id
      errors.add_to_base :travellers_exist_in_the_main_route
      self.main_route_id = find.main_route_id
      return false
    end
  end

  def available_seats
    no_of_seats.to_i - transports.count.to_i
  end
end

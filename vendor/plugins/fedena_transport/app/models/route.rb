class Route < ActiveRecord::Base
  has_many :routes
  has_many :transports
  has_many :vehicles,:foreign_key=>'main_route_id',:conditions=>"status='Active'"
  has_many :route_vehicle_additional_details, :as=>:linkable,:dependent => :destroy
  accepts_nested_attributes_for :route_vehicle_additional_details,:allow_destroy=>true
  validates_presence_of :destination, :cost
  #  validates_numericality_of :cost,:only_integer =>true, :greater_than_or_equal_to =>0, :allow_nil => true
  before_update :check_for_depenencies

  before_save :verify_precision
  after_save :delete_nil_additional_details

  def delete_nil_additional_details
    self.route_vehicle_additional_details.each do |detail|
      detail.destroy if detail.additional_info.nil? or detail.additional_info.blank?
    end
  end

  def verify_precision
    self.cost = FedenaPrecision.set_and_modify_precision self.cost
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



  def check_for_depenencies
    route = Route.find(self.id)
    if Transport.exists?(:route_id => self.id) and route.main_route_id != self.main_route_id
      errors.add_to_base :main_route_contains_travellers
      self.main_route_id = route.main_route_id
      return false
    end
  end

  def main_route
    if self.main_route_id.nil?
      return self
    else
      Route.find_by_id(self.main_route_id)
    end
  end

end

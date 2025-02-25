
class Transport < ActiveRecord::Base
  belongs_to :user
  belongs_to :route
  belongs_to :vehicle
  belongs_to :receiver, :polymorphic=>true

  validates_presence_of :route_id,:vehicle_id,:bus_fare
  
  HUMANIZED_ATTRIBUTES = {
    :route_id => "Destination", 
    :main_route => "Route"
  }

  before_save :verify_precision

  def verify_precision
    self.bus_fare = FedenaPrecision.set_and_modify_precision self.bus_fare
  end

  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def get_vehicles
    route = self.route
    if route.main_route.nil?
      return route.vehicles
    else
      return route.main_route.vehicles
    end
  end

  def self.single_vehicle_details(parameters)
    sort_order=parameters[:sort_order]
    vehicle_id=parameters[:vehicle_id]
    if sort_order.nil?
      receivers=Transport.all(:select=>"transports.*,students.first_name,students.middle_name,students.last_name,students.admission_no,employees.first_name as emp_first_name ,employees.middle_name as emp_middle_name,employees.last_name as emp_last_name,employees.employee_number,routes.destination ,IF(transports.receiver_type='Student',students.first_name,employees.first_name) as receiver_name",:joins=>"LEFT OUTER JOIN `routes` ON `routes`.id = `transports`.route_id LEFT OUTER JOIN students on students.id=transports.receiver_id LEFT OUTER JOIN employees on employees.id=transports.receiver_id",:conditions=>{:vehicle_id=>vehicle_id},:order=>'receiver_name ASC')
    else
      receivers=Transport.all(:select=>"transports.*,students.first_name,students.middle_name,students.last_name,students.admission_no,employees.first_name as emp_first_name ,employees.middle_name as emp_middle_name,employees.last_name as emp_last_name,employees.employee_number,routes.destination ,IF(transports.receiver_type='Student',students.first_name,employees.first_name) as receiver_name",:joins=>"LEFT OUTER JOIN `routes` ON `routes`.id = `transports`.route_id LEFT OUTER JOIN students on students.id=transports.receiver_id LEFT OUTER JOIN employees on employees.id=transports.receiver_id",:conditions=>{:vehicle_id=>vehicle_id},:order=>sort_order)
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('transport.passenger_type') }","#{t('route') }","#{t('fare')}"]
    data << col_heads
    receivers.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      if s.receiver_type=="Student"
        col<< "#{s.first_name} #{s.middle_name} #{s.last_name} ( #{s.admission_no} )"
      else
        col<< "#{s.emp_first_name} #{s.emp_middle_name} #{s.emp_last_name} ( #{s.employee_number} )"
      end
      col<< "#{s.receiver_type}"
      col<< "#{s.destination}"
      col<< "#{s.bus_fare}"
      col=col.flatten
      data<< col
    end
    return data
  end

end

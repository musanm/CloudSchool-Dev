ActionController::Routing::Routes.draw do |map|
  
  # transport
  map.resources :vehicles,:collection=>{:add_additional_details => [:get,:post,:put],:edit_additional_details => [:get,:post,:put]}
  map.resources :routes,:collection=>{:add_additional_details => [:get,:post,:put],:edit_additional_details => [:get,:post,:put]}

  map.namespace(:api) do |api|
    api.resources :vehicles, :collection => {:vehicle_details => :get, :route_vehicles => :get,:student_vehicle  => :get,:employee_vehicle => :get}
    api.resources :routes, :collection => {:students_route => :get,:employees_route => :get}
    api.resources :transports, :collection => {:students => :get,:vehicle_members => :get}
  end

end
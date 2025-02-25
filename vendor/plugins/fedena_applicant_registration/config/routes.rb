ActionController::Routing::Routes.draw do |map|
  map.resources :pin_groups,
    :member => {:deactivate_pin_group => [:get,:post],:deactivate_pin_number => [:get,:post]},
    :collection => {:search_ajax => [:get,:post]}
  map.resources :applicants,:collection=>{:show_form=>:get,:show_pin_entry_form => :get,:print_application => :get,:success => :get}
  
  map.resources :applicants_admins,:collection => {:view_applicant => :get,:courses=>:get,
    :allot=>:post,
    :search_by_registration => [:get,:post],
    :search_by_registration_pdf => :get},
    :members=>{
    :applicants=>:get,
    :applicants_pdf => :get}

  map.resource :applicants_admin
  
  map.resources :registration_courses,:member=>{:toggle=>:get} do |m|
    m.resources :applicant_additional_fields,:member=>{:change_order=>:post,:toggle=>:get, :view_addl_docs => :get}
  end

  map.connect "/register", :controller => 'applicants', :action => 'new'
  map.connect "/register.:lang", :controller => 'applicants', :action => 'new'
end

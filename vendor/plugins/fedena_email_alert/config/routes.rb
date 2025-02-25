ActionController::Routing::Routes.draw do |map|
  map.resources :email_alerts,:collection => { :show_students_list => [:get, :post],:email_alert_settings=>[:get,:post],:email_unsubscription_list=>[:get,:post] }
end
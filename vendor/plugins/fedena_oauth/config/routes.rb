ActionController::Routing::Routes.draw do |map|
  map.authenticate 'authenticate', :controller => 'oauth' ,:action=>'google_authenticate'

end
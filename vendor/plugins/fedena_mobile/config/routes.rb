ActionController::Routing::Routes.draw do |map|
  map.connect 'student/mobile_fee/', :controller=>:student, :action=>:mobile_fee
  map.connect 'attendances/mobile_attendace/', :controller=>:attendances, :action=>:mobile_attendance
  map.connect 'attendances/mobile_leave/', :controller=>:attendances, :action=>:mobile_leave
end
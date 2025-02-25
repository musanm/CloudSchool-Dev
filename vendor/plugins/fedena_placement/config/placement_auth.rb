authorization do

  role :placement_activities do
    has_permission_on [:placementevents] , :to =>[:archive,:create,:deactivate,:destroy,:edit,:index,:invite,:new,:report,:report_pdf,:show,:update,:update_invite_list,:update_students_list]
    has_permission_on [:placement_registrations] , :to =>[:apply,:approve_registration,:approve_placement,:approve_attendance,:index,:show]
  end

  role :student do
    has_permission_on [:placementevents] , :to =>[:index,:show]
    has_permission_on [:placement_registrations] , :to =>[:apply,:index,:show]
  end


  role :admin do
    includes :placement_activities
  end
end


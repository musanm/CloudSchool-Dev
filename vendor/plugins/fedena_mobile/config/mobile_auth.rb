authorization do
  role :student do
    has_permission_on [:timetable],
      :to => [:student_mobile_view,:update_student_mobile_view]
    has_permission_on [:student],
      :to => [:mobile_fee]
    has_permission_on [:attendance_reports],
      :to => [:student_attendance_view,:update_student_mobile_view]
    has_permission_on [:reminder],
      :to=>[:mobile_index,:mobile_view]
  end
  role :parent do
    has_permission_on [:timetable],
      :to => [:student_mobile_view,:update_student_mobile_view]
    has_permission_on [:student],
      :to => [:mobile_fee]
    has_permission_on [:attendance_reports],
      :to => [:student_attendance_view,:update_student_mobile_view]
    has_permission_on [:reminder],
      :to=>[:mobile_index,:mobile_view]
  end
  role :employee do
    has_permission_on [:employee_attendance],
      :to => [:mobile_leave,:apply_mobile_leave]
    has_permission_on [:timetable],
      :to => [:employee_mobile_view,:update_employee_mobile_view]
    has_permission_on [:attendances],
      :to=>[:mobile_attendance, :mobile_leave,:load_class_hours]
    has_permission_on [:reminder],
      :to=>[:mobile_index,:mobile_view]
  end
  role :student_attendance_register do
    has_permission_on [:attendances],
      :to=>[:mobile_attendance]
  end
  role :admin do
    has_permission_on [:attendances],
      :to=>[:mobile_attendance, :mobile_leave,:load_class_hours]
    has_permission_on [:reminder],
      :to=>[:mobile_index,:mobile_view]
  end
end
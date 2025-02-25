authorization do

  role :student_view do
    includes :gallery_student
  end

  role :gallery_student do
    has_permission_on [:galleries],
      :to=>[
      :category_show,:show_image,:download_image,:index ]
  end

  role :students_control do
    includes :gallery_student
  end

  role :manage_users do
    includes :gallery_student
  end

  role :photo_admin do
    has_permission_on [:galleries],
      :to=>[:index,:category_new,:category_create,:category_show,:category_delete,:category_edit,:category_update,:add_photo,:create_photo,:show_image,:download_image,:update_recipient_list1,:update_recipient_list,:select_student_course,:to_students,:to_employees,:select_users,:select_employee_department,:edit_photo,:photo_delete,:photo_add,:photo_create]
  end

  role :admin do
    includes :photo_admin
  end

  role :gallery do
    has_permission_on [:galleries],
      :to=>[:index,:category_new,:category_create,:category_show,:category_delete,:category_edit,:category_update,:add_photo,:create_photo,:show_image,:download_image,:update_recipient_list1,:update_recipient_list,:select_student_course,:to_students,:to_employees,:select_users,:select_employee_department,:edit_photo,:photo_delete,:photo_add,:photo_create]
  end

  role :employee do
    has_permission_on [:galleries],
      :to=>[
      :category_show,:show_image,:download_image,:index ]
  end

  role :student do
    includes :gallery_student
  end



end
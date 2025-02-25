authorization do

  role :applicant_registration do
    has_permission_on [:pin_groups],
      :to=> [
      :index,
      :new,
      :create,
      :edit,
      :update,
      :show,
      :deactivate_pin_number,
      :deactivate_pin_group,
      :search_ajax
    ]

    has_permission_on [:applicants_admin],:to => [:index]
    
    has_permission_on [:applicants_admins],:to=>[:applicants_pdf,
      :show,:applicants,:view_applicant,
      :allot,:mark_paid,:mark_academically_cleared,:search_by_registration,:search_by_registration_pdf,:admit_applicant,:allot_applicant
    ]
    has_permission_on [:applicant_additional_fields],:to=>[
      :index,:new,:create,:show,:edit,:update,:destroy,:toggle,:toggle_field,:change_order,:view_addl_docs,:download,:delete_doc]
    has_permission_on [:registration_courses],:to=>[
      :index,:show,:new,:edit,:create,:update,:destroy,:toggle,:amount_load,:settings_load,:populate_additional_field_list
    ]
  end

  role :addl_docs_view do
    has_permission_on [:applicant_additional_fields],:to=>[
      :view_addl_docs,
      :download
    ]
  end

  role :student_view do
    includes :addl_docs_view
  end

  role :manage_users do
    has_permission_on [:applicant_additional_fields],:to=>[
      :view_addl_docs,
      :download,
      :delete_doc
    ]
  end

  role :admission do
    has_permission_on [:applicant_additional_fields],:to=>[
      :view_addl_docs,
      :download,
      :delete_doc
    ]
  end
   
  role :students_control do
    has_permission_on [:applicant_additional_fields],:to=>[
      :view_addl_docs,
      :download,
      :delete_doc
    ]
  end

  role :employee do
    includes :addl_docs_view
  end

  role :parent do
    includes :addl_docs_view
  end

  role :admin do
    includes :applicant_registration
  end

  role :student do
    includes :addl_docs_view
  end

  role :guest do
    has_permission_on [:applicants],:to=>[:new,:create,:complete,:show_form,:print_application,:show_pin_entry_form]
  end

end
authorization do
  
  role :students_control do
    includes :fee_view
  end
  role :student_view do
    includes :fee_view
    includes :transport_view
  end
  #transport
  role :transport_admin do
    has_permission_on [:transport],
      :to=>[
      :index,
      :dash_board,
      :search_ajax,
      :transport_details,
      :ajax_transport_details,
      :add_transport,
      :update_vehicle,
      :load_fare,
      :seat_description,
      :delete_transport,
      :edit_transport,
      :student_transport_details,
      :employee_transport_details,
      :pdf_report,
      :vehicle_report,
      :vehicle_report_csv,
      :single_vehicle_details,
      :single_vehicle_details_csv
    ]
    has_permission_on [:report],
      :to=>[
      :csv_reports,
      :csv_report_download
    ]
    has_permission_on [:transport_fee],
      :to=>[
      :index,
      :transport_fee_collections,
      :transport_fee_collection_new,
      :transport_fee_collection_create,
      :transport_fee_collection_view,
      :transport_fee_collection_details,
      :transport_fee_collection_edit,
      :transport_fee_collection_date_edit,
      :transport_fee_collection_date_update,
      :transport_fee_collection_update,
      :transport_fee_collection_delete,
      :delete_fee_collection_date,
      :transport_fee_pay,
      :transport_fee_defaulters_view,
      :transport_fee_defaulters_details,
      :transport_defaulters_fee_pay,
      :tsearch_logic,
      :fees_student_dates,
      :fees_employee_dates,
      :update_fee_collection_dates,
      :fees_submission_student,
      :fees_submission_employee,
      :transport_fee_collection_pay,
      :transport_fee_collection_details,
      :defaulters_update_fee_collection_dates,
      :defaulters_update_fee_collection_details,
      :defaulters_transport_fee_collection_details,
      :employee_defaulters_transport_fee_collection,
      :employee_defaulters_transport_fee_collection_details,
      :transport_fee_search,
      :student_fee_receipt_pdf,
      :update_fine_ajax,
      :update_employee_fine_ajax,
      :update_student_fine_ajax,
      :update_employee_fine_ajax2,
      :update_defaulters_fine_ajax,
      :update_employee_defaulters_fine_ajax,
      :update_user_ajax,
      :update_batch_list_ajax,
      :fees_submission_defaulter_student,
      :transport_fee_receipt_pdf,
      :transport_fees_report,
      :batch_transport_fees_report,
      :employee_transport_fees_report,
      :select_payment_mode,
      :student_profile_fee_details,
      :delete_transport_transaction,
      :receiver_wise_collection_new,
      :search_student,
      :receiver_wise_fee_collection_creation,
      :allocate_or_deallocate_fee_collection,
      :list_students_by_batch,
      :list_fees_for_student,
      :list_students_for_collection,
      :list_fee_collections_for_employees,
      :list_employees_by_department,
      :list_fees_for_employee,
      :collection_creation_and_assign,
      :choose_collection_and_assign,
      :update_fees_collections,
      :render_collection_assign_form,
      :collection_assign_students,
      :show_employee_departments,
      :show_student_batches,
      :pay_transport_fees,
      :pay_batch_wise

    ]
    has_permission_on [:routes],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :show,
      :sort_by,
      :add_additional_details,
      :change_field_priority,
      :edit_additional_details,
      :delete_additional_details
    ]
    has_permission_on [:vehicles],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :show,
      :sort_by,
      :add_additional_details,
      :change_field_priority,
      :edit_additional_details,
      :delete_additional_details
    ]
  end

  role :fee_view do
    has_permission_on [:transport_fee],
      :to=>[
      :student_profile_fee_details,
    ]
  end
  role :transport_view do
    has_permission_on [:transport],
      :to=>[
      :student_transport_details
    ]
  end
  role :admin do
    includes :transport_admin
  end

  role :manage_users do
    has_permission_on [:transport],
      :to=>[
      :student_transport_details
    ]
  end

  role :students_control do
    has_permission_on [:transport],
      :to => [:student_transport_details]
  end
  
  role :student do
    has_permission_on [:transport],
      :to=>[
      :student_transport_details
    ]
    has_permission_on [:transport_fee],
      :to=>[
      :student_profile_fee_details,
      :transport_fee_receipt_pdf
    ]
  end

  role :parent do
    has_permission_on [:transport_fee],
      :to=>[
      :student_profile_fee_details,
      :transport_fee_receipt_pdf
    ]
  end

  role :employee do
    has_permission_on [:transport],
      :to=>[
      :employee_transport_details
    ]
  end

  role :finance_reports do
    has_permission_on [:transport_fee],
      :to => [:transport_fees_report,
      :batch_transport_fees_report
    ]
  end

end
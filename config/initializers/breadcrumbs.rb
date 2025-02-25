include DateFormater
Gretel::Crumbs.layout do

  crumb :root do
    link I18n.t('home'), {:controller=>"user",:action=>"dashboard"}
  end

  ########################################
  #Finance Module
  ########################################

  crumb :finance_index do
    link I18n.t('finance_text'), {:controller=>"finance",:action=>"index"}
  end

  crumb :finance_fees_index do
    link I18n.t('fees_text'), {:controller=>"finance",:action=>"fees_index"}
    parent :finance_index
  end

  crumb :finance_categories do
    link I18n.t('categories'), {:controller=>"finance",:action=>"categories"}
    parent :finance_index
  end

  crumb :finance_transactions do
    link I18n.t('transactions'), {:controller=>"finance",:action=>"transactions"}
    parent :finance_index
  end

  crumb :finance_automatic_transactions do
    link I18n.t('automatic_transactions'), {:controller=>"finance",:action=>"automatic_transactions"}
    parent :finance_index
  end

  crumb :finance_payslip_index do
    link I18n.t('payslip_text'), {:controller=>"finance",:action=>"payslip_index"}
    parent :finance_index
  end

  crumb :finance_finance_reports do
    link I18n.t('finance_reports'), {:controller=>"finance",:action=>"finance_reports"}
    parent :finance_index
  end

  crumb :finance_asset_liability do
    link I18n.t('asset_liability_management'), {:controller=>"finance",:action=>"asset_liability"}
    parent :finance_index
  end

  crumb :finance_master_fees do
    link I18n.t('create_fees'), {:controller=>"finance",:action=>"master_fees"}
    parent :finance_fees_index
  end

  crumb :finance_master_category_particulars do |finance_fee_category|
    link finance_fee_category.name, {:controller=>"finance",:action=>"master_category_particulars", :id => finance_fee_category.id, :batch_id => finance_fee_category.batch_id}
    parent :finance_master_fees
  end

  crumb :finance_fees_submission_index do
    link I18n.t('fees_text_index'), {:controller=>"finance",:action=>"fees_submission_index"}
    parent :finance_fees_index
  end

  crumb :finance_fee_collection do
    link I18n.t('fees_collection_text'), {:controller=>"finance",:action=>"fee_collection"}
    parent :finance_fees_index
  end

  crumb :finance_fees_student_structure_search do
    link I18n.t('fees_structure'), {:controller=>"finance",:action=>"fees_student_structure_search"}
    parent :finance_fees_index
  end

  crumb :finance_fees_defaulters do
    link I18n.t('fees_defaulters_text'), {:controller=>"finance",:action=>"fees_defaulters"}
    parent :finance_fees_index
  end

  crumb :finance_fees_refund do
    link I18n.t('fees_refund'), {:controller=>"finance",:action=>"fees_refund"}
    parent :finance_fees_index
  end

  crumb :finance_fees_particulars_new do
    link I18n.t('create_particulars'), {:controller=>"finance",:action=>"fees_particulars_new"}
    parent :finance_master_fees
  end

  crumb :finance_fees_particulars_create do
    link I18n.t('create_particulars'), {:controller=>"finance",:action=>"fees_particulars_new"}
    parent :finance_master_fees
  end

  crumb :finance_fee_discount_new do
    link I18n.t('create_discount_text'), {:controller=>"finance",:action=>"fee_discount_new"}
    parent :finance_master_fees
  end

  crumb :finance_fee_discounts do
    link I18n.t('fee_discounts'), {:controller=>"finance",:action=>"fee_discounts"}
    parent :finance_fee_discount_new
  end

  crumb :finance_generate_fine do
    link I18n.t('generate_fine'), {:controller=>"finance",:action=>"generate_fine"}
    parent :finance_master_fees
  end

  crumb :finance_fee_collection_new do
    link I18n.t('create_fee_collection'), {:controller=>"finance",:action=>"fee_collection_new"}
    parent :finance_fee_collection
  end

  crumb :fee_collection_schedule_jobs do
    link "#{I18n.t('scheduled_job_for')} #{I18n.t('fee_collection')}", {:controller=>"scheduled_jobs", :job_type=>"1", :action=>"index", :job_object=>"FinanceFeeCollection"}
    parent :finance_fee_collection_new
  end

  crumb :finance_fee_collection_view do
    link I18n.t('view'), {:controller=>"finance",:action=>"fee_collection_view"}
    parent :finance_fee_collection
  end

  crumb :finance_extensions_discount_particular_allocation do
    link "#{I18n.t('manage')} #{I18n.t('fee_collections')}", {:controller=>"finance_extensions",:action=>"discount_particular_allocation"}
    parent :finance_fee_collection
  end

  crumb :finance_collection_details_view do |fee_collection|
    link fee_collection.name, {:controller=>"finance",:action=>"collection_details_view", :id => fee_collection, :batch_id => fee_collection.batch_id}
    parent :finance_fee_collection_view
  end

  crumb :finance_fees_submission_batch do
    link I18n.t('fees_submission_by_batch'), {:controller=>"finance",:action=>"fees_submission_batch"}
    parent :finance_fees_submission_index
  end

  crumb :finance_fees_student_search do
    link I18n.t('fees_submit_for_student'), {:controller=>"finance",:action=>"fees_student_search",:target_action=>"student_wise_fee_payment"}
    parent :finance_fees_submission_index
  end

  crumb :finance_fees_student_search2 do
    link "#{I18n.t('pay_fees')} : #{I18n.t('particular')}-#{I18n.t('wise').capitalize}", {:controller=>"finance",:action=>"fees_student_search",:target_controller=>"finance_extensions",:target_action=>"pay_fees_in_particular_wise"}
    parent :finance_fees_submission_index
  end

  crumb :finance_pay_fees_in_particular_wise do|student|
    link student.full_name, {:controller=>"finance_extensions",:action=>"pay_fees_in_particular_wise",:id=>student.id,:target_action=>"pay_fees_in_particular_wise"}
    parent :finance_fees_student_search2
  end


  crumb :finance_view_refunds do
    link I18n.t('view_refunds'), {:controller=>"finance",:action=>"view_refunds"}
    parent :finance_fees_refund
  end

  crumb :finance_create_refund do
    link I18n.t('create_refund_rule'), {:controller=>"finance",:action=>"create_refund"}
    parent :finance_fees_refund
  end

  crumb :finance_view_refund_rules do
    link "#{I18n.t('view')} #{I18n.t('refund_rules')}", {:controller=>"finance",:action=>"view_refund_rules"}
    parent :finance_create_refund
  end

  crumb :finance_apply_refund do
    link I18n.t('apply_refund'), {:controller=>"finance",:action=>"apply_refund"}
    parent :finance_fees_refund
  end

  crumb :finance_income_create do
    link I18n.t('add_income'), {:controller=>"finance",:action=>"income_create"}
    parent :finance_transactions
  end

  crumb :finance_expense_create do
    link I18n.t('add_expense'), {:controller=>"finance",:action=>"expense_create"}
    parent :finance_transactions
  end

  crumb :finance_update_deleted_transactions do
    link I18n.t('deleted_transactions'), {:controller=>"finance",:action=>"update_deleted_transactions"}
    parent :finance_transactions
  end

  crumb :finance_expense_list do
    link I18n.t('expense'), {:controller=>"finance",:action=>"expense_list"}
    parent :finance_transactions
  end

  crumb :finance_expense_list_update do
    link I18n.t('expenses_list'), {:controller=>"finance",:action=>"expense_list_update"}
    parent :finance_expense_list
  end

  crumb :finance_expense_edit do|expense|
    link shorten_string(expense.title_was,20), {:controller=>"finance",:action=>"expense_edit",:id=>expense.id}
    parent :finance_expense_list
  end

  crumb :finance_income_list do
    link I18n.t('incomes'), {:controller=>"finance",:action=>"income_list"}
    parent :finance_transactions
  end

  crumb :finance_income_list_update do
    link I18n.t('income_list'), {:controller=>"finance",:action=>"income_list_update"}
    parent :finance_income_list
  end

  crumb :finance_income_edit do|expense|
    link shorten_string(expense.title_was,20), {:controller=>"finance",:action=>"income_edit",:id=>expense.id}
    parent :finance_income_list
  end

  crumb :finance_transactions_advanced_search do
    link I18n.t('advanced'), {:controller=>"finance",:action=>"transactions_advanced_search"}
    parent :finance_update_deleted_transactions
  end

  crumb :finance_donations do
    link I18n.t('donations'), {:controller=>"finance",:action=>"donations"}
    parent :finance_index
  end

  crumb :finance_donation do
    link I18n.t('donation'), {:controller=>"finance",:action=>"donation"}
    parent :finance_donations
  end

  crumb :finance_donation_edit do |donation|
    link I18n.t('edit')+" - "+donation.donor_was, {:controller=>"finance",:action=>"donation_edit",:id=>donation.id}
    parent :finance_donations
  end

  crumb :finance_donation_receipt do|donation|
    link donation.donor, {:controller=>"finance",:action=>"donation_receipt",:id=>donation.id}
    parent :finance_donations
  end

  crumb :finance_view_monthly_payslip do
    link I18n.t('view_payslip'), {:controller=>"finance",:action=>"view_monthly_payslip"}
    parent :finance_payslip_index
  end

  crumb :finance_approve_monthly_payslip do
    link I18n.t('one_click_aprove_payslip'), {:controller=>"finance",:action=>"approve_monthly_payslip"}
    parent :finance_payslip_index
  end

  crumb :finance_view_employee_payslip do|payslip|
    link payslip.first.active_or_archived_employee.full_name.to_s, {:controller=>"finance",:action=>"view_employee_payslip",:id=>payslip.id}
    parent :finance_view_monthly_payslip
  end

  crumb :finance_monthly_report do
    link I18n.t('report'), {:controller=>"finance",:action=>"monthly_report"}
    parent :finance_finance_reports
  end

  crumb :finance_update_monthly_report do |date_range|
    link I18n.t('finance_transactions_view'), {:controller=>"finance",:action=>"update_monthly_report",:start_date=>date_range.first.to_date,:end_date=>date_range.last.to_date}
    parent :finance_monthly_report
  end

  crumb :finance_salary_department do |date_range|
    link I18n.t('salary_account'), {:controller=>"finance",:action=>"salary_department",:start_date=>date_range.first.to_date,:end_date=>date_range.last.to_date}
    parent :finance_update_monthly_report,date_range
  end

  crumb :finance_donations_report do |date_range|
    link I18n.t('donations'), {:controller=>"finance",:action=>"donations_report",:start_date=>date_range.first.to_date,:end_date=>date_range.last.to_date}
    parent :finance_update_monthly_report,date_range
  end

  crumb :finance_fees_report do |date_range|
    link I18n.t('fees_report'), {:controller=>"finance",:action=>"fees_report",:start_date=>date_range.first.to_date,:end_date=>date_range.last.to_date}
    parent :finance_update_monthly_report,date_range
  end

  crumb :finance_income_details do|detail_object|
    link detail_object.first.name, {:controller=>"finance",:action=>"income_details",:id=>detail_object.first.id,:start_date=>detail_object.last.first.to_date,:end_date=>detail_object.last.last.to_date}
    parent :finance_update_monthly_report, detail_object.last
  end

  crumb :finance_salary_employee do|salary_object|
    link I18n.t('department')+" : "+ salary_object.first.name, {:controller=>"finance",:action=>"salary_employee",:id=>salary_object.first.id,:start_date=>salary_object.last.first.to_date,:end_date=>salary_object.last.last.to_date}
    parent :finance_salary_department,salary_object.last
  end

  crumb :finance_batch_fees_report do|batch_object|
    link batch_object.first.full_name, {:controller=>"finance",:action=>"batch_fees_report",:id=>batch_object.first.id}
    parent :finance_fees_report,batch_object.last
  end

  crumb :finance_compare_report do
    link I18n.t('compare_transactions'), {:controller=>"finance",:action=>"compare_report"}
    parent :finance_finance_reports
  end

  crumb :finance_report_compare do
    link I18n.t('transaction_comparision'), {:controller=>"finance",:action=>"report_compare"}
    parent :finance_compare_report
  end

  crumb :finance_asset do
    link I18n.t('asset'), {:controller=>"finance",:action=>"asset"}
    parent :finance_asset_liability
  end

  crumb :finance_view_asset do
    link I18n.t('view'), {:controller=>"finance",:action=>"view_asset"}
    parent :finance_asset
  end

  crumb :finance_each_asset_view do|asset|
    link shorten_string(asset.title,20), {:controller=>"finance",:action=>"each_asset_view",:id=>asset.id}
    parent :finance_view_asset
  end

  crumb :finance_liability do
    link I18n.t('liability'), {:controller=>"finance",:action=>"liability"}
    parent :finance_asset_liability
  end

  crumb :finance_view_liability do
    link I18n.t('view'), {:controller=>"finance",:action=>"view_liability"}
    parent :finance_liability
  end

  crumb :finance_each_liability_view do|liability|
    link shorten_string(liability.title,20), {:controller=>"finance",:action=>"each_liability_view",:id=>liability.id}
    parent :finance_view_liability
  end

  crumb :finance_student_wise_fee_payment do|student|
    link student.full_name, {:controller=>"finance",:action=>"student_wise_fee_payment",:id=>student.id}
    parent :finance_fees_student_search
  end

  crumb :finance_fees_student_dates do|student|
    link "#{I18n.t('fee_collection')} #{I18n.t('wise')} #{I18n.t('payment')}", {:controller=>"finance",:action=>"fees_student_dates",:id=>student.id}
    parent :finance_student_wise_fee_payment,student
  end

  crumb :finance_extensions_pay_all_fees do|student|
    link "#{I18n.t('pay_all_fees')}", {:controller=>"finance_extensions",:action=>"pay_all_fees",:id=>student.id}
    parent :finance_student_wise_fee_payment,student
  end


  crumb :finance_fees_structure_dates do|student|
    link student.full_name, {:controller=>"finance",:action=>"fees_structure_dates",:id=>student.id}
    parent :finance_fees_student_structure_search
  end

  crumb :finance_pay_fees_defaulters do|student|
    link student.full_name, {:controller=>"finance",:action=>"pay_fees_defaulters",:id=>student.id}
    parent :finance_fees_defaulters
  end

  crumb :finance_fees_refund_dates do|student|
    link student.full_name, {:controller=>"finance",:action=>"fees_refund_dates",:id=>student.id}
    parent :finance_apply_refund
  end

  crumb :finance_refund_student_view do|student|
    link I18n.t('view_refunds'), {:controller=>"finance",:action=>"refund_student_view",:id=>student.id}
    parent :student_fees,student
  end
  crumb :finance_add_additional_details_for_donation do
    link I18n.t('add_additional_details_for_donation'), {:controller => "finance", :action => "add_additional_details_for_donation"}
    parent :finance_donations
  end
  crumb :finance_edit_additional_details_for_donation do
    link I18n.t('edit_additional_details_donation'), {:controller => "finance", :action => "edit_additional_details_for_donation"}
    parent :finance_donations
  end

  ##################################################
  #HR Module
  ##################################################

  crumb :employee_hr do
    link I18n.t('hr'), {:controller=>"employee",:action=>"hr"}
  end

  crumb :employee_settings do
    link I18n.t('settings'), {:controller=>"employee",:action=>"settings"}
    parent :employee_hr
  end

  crumb :employee_employee_management do
    link I18n.t('employee_management_text'), {:controller=>"employee",:action=>"employee_management"}
    parent :employee_hr
  end

  crumb :employee_employee_attendance do
    link I18n.t('employee_leave_management'), {:controller=>"employee",:action=>"employee_attendance"}
    parent :employee_hr
  end

  crumb :employee_payslip do
    link I18n.t('create_payslip'), {:controller=>"employee",:action=>"payslip"}
    parent :employee_hr
  end

  crumb :employee_search do
    link I18n.t('employees'), {:controller=>"employee",:action=>"search"}
    parent :employee_hr
  end

  crumb :employee_department_payslip do
    link I18n.t('employee_payslip'), {:controller=>"employee",:action=>"department_payslip"}
    parent :employee_hr
  end

  crumb :employee_add_category do
    link I18n.t('employee_category'), {:controller=>"employee",:action=>"add_category"}
    parent :employee_settings
  end

  crumb :employee_add_position do
    link I18n.t('employee_position'), {:controller=>"employee",:action=>"add_position"}
    parent :employee_settings
  end

  crumb :employee_add_department do
    link I18n.t('employee_department'), {:controller=>"employee",:action=>"add_department"}
    parent :employee_settings
  end

  crumb :employee_add_grade do
    link I18n.t('employee_grade'), {:controller=>"employee",:action=>"add_grade"}
    parent :employee_settings
  end

  crumb :payroll_add_category do
    link I18n.t('payroll_category'), {:controller=>"payroll",:action=>"add_category"}
    parent :employee_settings
  end

  crumb :employee_add_bank_details do
    link I18n.t('bank_detail'), {:controller=>"employee",:action=>"add_bank_details"}
    parent :employee_settings
  end

  crumb :employee_add_additional_details do
    link I18n.t('additional_detail'), {:controller=>"employee",:action=>"add_additional_details"}
    parent :employee_settings
  end

  crumb :employee_subject_assignment do
    link I18n.t('employee_subject_association'), {:controller=>"employee",:action=>"subject_assignment"}
    parent :employee_employee_management
  end

  crumb :employee_attendance_add_leave_types do
    link I18n.t('add_type'), {:controller=>"employee_attendance",:action=>"add_leave_types"}
    parent :employee_employee_attendance
  end

  crumb :employee_attendances_index do
    link I18n.t('attendance_register'), {:controller=>"employee_attendances",:action=>"index"}
    parent :employee_employee_attendance
  end

  crumb :employee_attendance_report do
    link I18n.t('attendance_report'), {:controller=>"employee_attendance",:action=>"report"}
    parent :employee_employee_attendance
  end
  
   crumb :employee_attendance_filter_attendance_report do
    link I18n.t('filterd_reports_text'), {:controller=>"employee_attendance",:action=>"filter_attendance_report"}
    parent :employee_attendance_report
  end


  crumb :employee_attendance_leaves do |employee|
    link I18n.t('leave_management'), {:controller=>"employee_attendance",:action=>"leaves",:id=>employee.id}
    parent :employee_profile,employee
  end

  crumb :employee_attendance_leave_application do |leave|
    link I18n.t('approve_deny'), {:controller=>"employee_attendance",:action=>"leave_application",:id=>leave.id}
    parent :employee_attendance_leaves,leave.employee.reporting_manager.employee_record
  end

  crumb :employee_attendance_manual_reset do
    link I18n.t('reset_leave'), {:controller=>"employee_attendance",:action=>"manual_reset"}
    parent :employee_employee_attendance
  end

  crumb :employee_select_department_employee do
    link I18n.t('select_employee'), {:controller=>"employee",:action=>"select_department_employee"}
    parent :employee_payslip
  end

  crumb :employee_rejected_payslip do
    link I18n.t('rejected_employee'), {:controller=>"employee",:action=>"rejected_payslip"}
    parent :employee_payslip
  end

  crumb :employee_view_all do
    link I18n.t('view_all'), {:controller=>"employee",:action=>"view_all"}
    parent :employee_search
  end

  crumb :employee_advanced_search do
    link I18n.t('advanced'), {:controller=>"employee",:action=>"advanced_search"}
    parent :employee_search
  end

  crumb :employee_edit_category do|category|
    link I18n.t('edit')+" - "+category.name_was, {:controller=>"employee",:action=>"edit_category",:id=>category.id}
    parent :employee_add_category
  end

  crumb :employee_edit_position do|position|
    link I18n.t('edit')+" - "+position.name_was, {:controller=>"employee",:action=>"edit_position",:id=>position.id}
    parent :employee_add_position
  end

  crumb :employee_edit_department do|department|
    link I18n.t('edit')+" - "+department.name_was, {:controller=>"employee",:action=>"edit_department",:id=>department.id}
    parent :employee_add_department
  end

  crumb :employee_edit_grade do|grade|
    link I18n.t('edit')+" - "+grade.name_was, {:controller=>"employee",:action=>"edit_grade",:id=>grade.id}
    parent :employee_add_grade
  end

  crumb :payroll_edit_category do|category|
    link I18n.t('edit')+" - "+category.name_was, {:controller=>"payroll",:action=>"edit_category",:id=>category.id}
    parent :payroll_add_category
  end

  crumb :employee_edit_bank_details do|bank_detail|
    link I18n.t('edit')+" - "+bank_detail.name_was, {:controller=>"employee",:action=>"edit_bank_details",:id=>bank_detail.id}
    parent :employee_add_bank_details
  end

  crumb :employee_attendance_edit_leave_types do|leave_type|
    link I18n.t('edit')+" - "+leave_type.name_was, {:controller=>"employee_attendance",:action=>"edit_leave_types",:id=>leave_type.id}
    parent :employee_attendance_add_leave_types
  end

  crumb :employee_attendance_emp_attendance do|emp|
    link emp.first_name_was, {:controller=>"employee_attendance",:action=>"emp_attendance",:id=>emp.id}
    parent :employee_attendance_report
  end

  crumb :archived_employee_profile do|emp|
    link emp.first_name_was, {:controller=>"archived_employee",:action=>"profile",:id=>emp.id}
    parent :employee_advanced_search
  end

  crumb :employee_attendance_additional_leave_history do
    link I18n.t('additional_leaves'), {:controller=>"employee_attendance",:action=>"additional_leave_history"}
    parent :employee_attendance_report
  end

  crumb :employee_attendance_additional_leave_detailed do |employee|
    link I18n.t('additional_leave_details'), {:controller=>"employee_attendance",:action=>"additional_leave_detailed",:id=>employee.id}
    parent :employee_attendance_additional_leave_history
  end

  crumb :employee_attendance_leave_history do|employee|
    link I18n.t('leave_history'), {:controller=>"employee_attendance",:action=>"leave_history",:id=>employee.id}
    parent :employee_attendance_emp_attendance,employee
  end

  crumb :employee_attendance_leave_history_without_permission do|employee|
    link I18n.t('leave_history'), {:controller=>"employee_attendance",:action=>"leave_history",:id=>employee.id}
    parent :employee_attendance_leaves,employee
  end

  crumb :employee_attendance_own_leave_application do|employee|
    link I18n.t('leave_application'), {:controller=>"employee_attendance",:action=>"own_leave_application",:id=>employee.id}
    parent :employee_attendance_leaves,employee
  end

  crumb :employee_attendance_leave_reset_settings do
    link I18n.t('leave_reset_settings'), {:controller=>"employee_attendance",:action=>"leave_reset_settings"}
    parent :employee_attendance_manual_reset
  end

  crumb :employee_attendance_employee_leave_reset_all do
    link I18n.t('reset_all'), {:controller=>"employee_attendance",:action=>"employee_leave_reset_all"}
    parent :employee_attendance_manual_reset
  end

  crumb :employee_attendance_employee_leave_reset_by_department do
    link I18n.t('department_reset'), {:controller=>"employee_attendance",:action=>"employee_leave_reset_by_department"}
    parent :employee_attendance_manual_reset
  end

  crumb :employee_attendance_employee_leave_reset_by_employee do
    link I18n.t('individual_reset'), {:controller=>"employee_attendance",:action=>"employee_leave_reset_by_employee"}
    parent :employee_attendance_manual_reset
  end

  crumb :employee_attendance_employee_view_all do
    link I18n.t('view_all'), {:controller=>"employee_attendance",:action=>"employee_view_all"}
    parent :employee_attendance_employee_leave_reset_by_employee
  end

  crumb :employee_attendance_employee_leave_details do|emp|
    link emp.first_name, {:controller=>"employee_attendance",:action=>"edit_leave_types",:id=>emp.id}
    parent :employee_attendance_employee_leave_reset_by_employee
  end

  crumb :employee_create_monthly_payslip do|emp|
    link emp.first_name, {:controller=>"employee",:action=>"create_monthly_payslip",:id=>emp.id}
    parent :employee_select_department_employee
  end

  crumb :employee_view_rejected_payslip do|emp|
    link emp.first_name, {:controller=>"employee",:action=>"view_rejected_payslip",:id=>emp.id}
    parent :employee_rejected_payslip
  end

  crumb :employee_edit_rejected_payslip do|emp|
    link I18n.t('edit_text'), {:controller=>"employee",:action=>"edit_rejected_payslip",:id=>emp.id}
    parent :employee_view_rejected_payslip,emp
  end

  crumb :employee_view_employee_payslip do|emp|
    link emp.first.active_or_archived_employee.full_name, {:controller=>"employee",:action=>"view_employee_payslip",:id=>emp.id}
    parent :employee_department_payslip,emp
  end

  crumb :employee_profile do|emp|
    link emp.first_name_was, {:controller=>"employee",:action=>"profile",:id=>emp.id}
    parent :employee_search,emp
  end

  crumb :employee_change_reporting_manager do|emp|
    link I18n.t('change_reporting_manager'), {:controller=>"employee",:action=>"change_reporting_manager",:id=>emp.id}
    parent :employee_profile,emp
  end

  crumb :employee_edit1 do|emp|
    link I18n.t('general_details_edit'), {:controller=>"employee",:action=>"edit1",:id=>emp.id}
    parent :employee_profile,emp
  end

  crumb :employee_edit_personal do|emp|
    link I18n.t('personal_details_edit'), {:controller=>"employee",:action=>"edit_personal",:id=>emp.id}
    parent :employee_profile,emp
  end

  crumb :employee_edit2 do|emp|
    link I18n.t('address_edit'), {:controller=>"employee",:action=>"edit2",:id=>emp.id}
    parent :employee_profile,emp
  end

  crumb :employee_edit_contact do|emp|
    link I18n.t('contact_edit'), {:controller=>"employee",:action=>"edit_contact",:id=>emp.id}
    parent :employee_profile,emp
  end

  crumb :employee_edit3 do|emp|
    link I18n.t('bank_details_edit'), {:controller=>"employee",:action=>"edit3",:id=>emp.id}
    parent :employee_profile,emp
  end

  crumb :employee_admission3_1 do|emp|
    link I18n.t('additional_detail_edit'), {:controller=>"employee",:action=>"admission3_1",:id=>emp.id}
    parent :employee_profile,emp
  end

  crumb :employee_edit_payroll_details do|emp|
    link I18n.t('payroll_edit'), {:controller=>"employee",:action=>"edit_payroll_details",:id=>emp.id}
    parent :employee_profile,emp
  end

  crumb :employee_remove_subordinate_employee do|emp|
    link I18n.t('remove_subordinate_employee'), {:controller=>"employee",:action=>"remove_subordinate_employee",:id=>emp.id}
    parent :employee_profile,emp
  end

  crumb :employee_remove do|emp|
    link I18n.t('remove'), {:controller=>"employee",:action=>"remove",:id=>emp.id}
    parent :employee_profile,emp
  end

  crumb :employee_change_to_former do|emp|
    link I18n.t('archive'), {:controller=>"employee",:action=>"change_to_former",:id=>emp.id}
    parent :employee_remove,emp
  end

  crumb :payroll_manage_payroll do|emp|
    link I18n.t('add_payroll'), {:controller=>"employee",:action=>"manage_payroll",:id=>emp.id}
    parent :employee_profile,emp
  end


  crumb :employee_admission1 do
    link I18n.t('employee_admission'), {:controller=>"employee",:action=>"admission1"}
    parent :employee_employee_management
  end

  crumb :employee_admission2 do |emp|
    link I18n.t('address'), {:controller=>"employee",:action=>"admission2",:id=>emp.id}
    parent :employee_profile,emp
  end

  crumb :employee_admission3 do |emp|
    link I18n.t('bank_info'), {:controller=>"employee",:action=>"admission3",:id=>emp.id}
    parent :employee_profile,emp
  end

  crumb :employee_edit_privilege do |emp|
    link I18n.t('edit_privilege_text'), {:controller=>"employee",:action=>"edit_privilege",:id=>emp.id}
    parent :employee_profile,emp
  end

  crumb :employee_admission4 do |emp|
    link I18n.t('select_reporting_manager'), {:controller=>"employee",:action=>"admission4",:id=>emp.id}
    parent :employee_profile,emp
  end

  ########################################
  #User Search
  ########################################

  crumb :user_index do
    link I18n.t('find_user'), {:controller=>"user",:action=>"index"}
  end

  crumb :user_all_users do
    link I18n.t('view_all'), {:controller=>"user",:action=>"all"}
    parent :user_index
  end

  crumb :user_create do
    link I18n.t('add_user'), {:controller=>"user",:action=>"create"}
    parent :user_index
  end

  crumb :user_profile do|this_user|
    link this_user.username, {:controller=>"user",:action=>"profile",:id=>this_user.username}
    parent :user_index
  end

  crumb :user_user_change_password do|this_user|
    link I18n.t('change_password'), {:controller=>"user",:action=>"user_change_password",:id=>this_user.username}
    parent :user_profile,this_user
  end

  crumb :user_change_password do|this_user|
    link I18n.t('change_password'), {:controller=>"user",:action=>"change_password",:id=>this_user.username}
    parent :user_profile,this_user
  end

  crumb :user_edit_privilege do|this_user|
    link I18n.t('edit_privilege_text'), {:controller=>"user",:action=>"edit_privilege",:id=>this_user.username}
    parent :user_profile,this_user
  end

  ########################################
  #Student Search
  ########################################

  crumb :student_index do
    link I18n.t('students'), {:controller=>"student",:action=>"index"}
  end
  crumb :student_profile do|student|
    link student.full_name, {:controller=>"student",:action=>"profile",:id=>student.id}
    parent :student_index
  end
  crumb :student_reports do|student|
    link I18n.t('report_center'), {:controller=>"student",:action=>"reports",:id=>student.id}
    parent :student_profile, student
  end
  crumb :student_guardians do|student|
    link I18n.t('guardians_text'), {:controller=>"student",:action=>"guardians",:id=>student.id}
    parent :student_profile, student
  end
  crumb :student_transcript_st_view do|student|
    link "Transcript Report", {:controller=>"exam",:action=>"student_transcript",:transcript=>{:batch_id=>student.batch_id},:student_id=>student.id,:flag=>"1"}
    parent :student_reports, student
  end
  crumb :student_transcript_st_ar_view do|student|
    link "Transcript Report", {:controller=>"exam",:action=>"student_transcript",:transcript=>{:batch_id=>student.batch_id},:student_id=>student.id,:flag=>"1"}
    parent :archived_student_reports, student
  end
  crumb :student_view_all do
    link I18n.t('view_all'), {:controller=>"student",:action=>"view_all"}
    parent :student_index
  end

  crumb :student_advanced_search do
    link I18n.t('advanced_search_text'), {:controller=>"student",:action=>"advanced_search"}
    parent :student_index
  end

  crumb :student_edit do|stud|
    link I18n.t('general_details_edit'), {:controller=>"student",:action=>"edit",:id=>stud.id}
    parent :student_profile,stud
  end

  crumb :student_add_guardian do|stud|
    link I18n.t('add_guardian'), {:controller=>"student",:action=>"add_guardian",:id=>stud.id}
    parent :student_profile,stud
  end

  crumb :student_admission3_1 do|stud|
    link I18n.t('immediate_contact'), {:controller=>"student",:action=>"admission3_1",:id=>stud.id}
    parent :student_profile,stud
  end

  crumb :student_admission4 do|stud|
    link I18n.t('additional_details'), {:controller=>"student",:action=>"admission4",:id=>stud.id}
    parent :student_profile,stud
  end

  crumb :student_previous_data_from_profile do|stud|
    link I18n.t('previous_educational_details'), {:controller=>"student",:action=>"previous_data_from_profile",:id=>stud.id}
    parent :student_profile,stud
  end

  crumb :student_show_previous_details do|stud|
    link I18n.t('show_previous_details'), {:controller=>"student",:action=>"show_previous_details",:id=>stud.id}
    parent :student_profile,stud
  end

  crumb :student_previous_data_edit do|stud|
    link I18n.t('edit_previous_details'), {:controller=>"student",:action=>"previous_data_edit",:id=>stud.id}
    parent :student_profile,stud
  end

  crumb :student_attendance_student do|stud|
    link I18n.t('current_attendance_report'), {:controller=>"student_attendance",:action=>"student",:id=>stud.id}
    parent :student_reports,stud
  end

  crumb :student_admission1_2 do|stud|
    link I18n.t('sibling'), {:controller=>"student",:action=>"admission1_2",:id=>stud.id}
    parent :student_profile,stud
  end

  crumb :student_email do|stud|
    link I18n.t('send_email'), {:controller=>"student",:action=>"email",:id=>stud.id}
    parent :student_profile,stud
  end

  crumb :student_remove do|stud|
    link I18n.t('remove'), {:controller=>"student",:action=>"remove",:id=>stud.id}
    parent :student_profile,stud
  end

  crumb :student_change_to_former do|stud|
    link I18n.t('archive_student'), {:controller=>"student",:action=>"change_to_former",:id=>stud.id}
    parent :student_remove,stud
  end

  crumb :student_delete do|stud|
    link I18n.t('delete_student'), {:controller=>"student",:action=>"delete",:id=>stud.id}
    parent :student_remove,stud
  end

  crumb :student_fees do|stud|
    link I18n.t('student_fees'), {:controller=>"student",:action=>"fees",:id=>stud.id}
    parent :student_profile,stud
  end

  crumb :student_fee_details do|list|
    link list.last.name, {:controller=>"student",:action=>"fee_details",:id=>list.last.id}
    parent :student_fees,list.first
  end

  crumb :archived_student_profile do|stud|
    link stud.full_name, {:controller=>"archived_student",:action=>"profile",:id=>stud.id}
    parent :student_index
  end

  crumb :archived_student_reports do|stud|
    link I18n.t('report_center'), {:controller=>"archived_student",:action=>"reports",:id=>stud.id}
    parent :archived_student_profile,stud
  end

  crumb :archived_student_generated_report3 do|list|
    link list.last.name, {:controller=>"archived_student",:action=>"generated_report3",:id=>list.last.id}
    parent :archived_student_reports,list.first
  end

  crumb :archived_student_guardians do|stud|
    link I18n.t('guardians_text'), {:controller=>"archived_student",:action=>"guardians",:id=>stud.id}
    parent :archived_student_profile,stud
  end

  crumb :archived_student_student_report do|stud|
    link I18n.t('archived_attendance_report'), {:controller=>"archived_student",:action=>"student_report",:id=>stud.id}
    parent :archived_student_reports,stud
  end

  crumb :archived_student_generated_report do|list|
    link I18n.t('generated_report'), {:controller=>"archived_student",:action=>"generated_report",:exam_group=>list.last,:student=>list.first}
    parent :archived_student_reports,list.first
  end

  crumb :student_edit_guardian do|list|
    link I18n.t('edit_guardian')+ " - "+list.last.first_name_was, {:controller=>"student",:action=>"edit_guardian",:id=>list.last.id}
    parent :student_guardians,list.first
  end

  crumb :student_attendance_student_report do|list|
    link I18n.t('archived_attendance_report'), {:controller=>"student_attendance",:action=>"student_report",:id=>list.last.id}
    parent :student_reports,list.first
  end

  ########################################
  #Student Admission
  ########################################

  crumb :student_admission1 do
    link I18n.t('student_admission'), {:controller=>"student",:action=>"admission1"}
  end
  crumb :student_previous_data do|student|
    link I18n.t('previous_details'), {:controller=>"student",:action=>"previous_data",:id=>student.id}
    parent :student_profile,student
  end
  crumb :student_admission2 do|student|
    link I18n.t('parent_guardian_details'), {:controller=>"student",:action=>"admission2",:id=>student.id}
    parent :student_profile,student
  end
  crumb :student_admission3 do|student|
    link I18n.t('emergency_contact'), {:controller=>"student",:action=>"admission3",:id=>student.id}
    parent :student_profile,student
  end

  crumb :student_roll_number_index do
    link I18n.t('manage_student_roll_number'), {:controller=>"student_roll_number",:action=>"index"}
    parent :configuration_index
  end

  crumb :student_roll_number_view_batches do |course|
    link course.full_name, {:controller=>"student_roll_number",:action=>"view_batches", :id => course.id}
    parent :student_roll_number_index
  end

  crumb :student_roll_number_set_roll_numbers do |batch|
    link batch.full_name, {:controller=>"student_roll_number",:action=>"set_roll_numbers", :id => batch.id}
    parent :student_roll_number_view_batches, batch.course
  end

  ########################################
  #Settings Module
  ########################################

  crumb :configuration_index do
    link I18n.t('configuration_text'), {:controller=>"configuration",:action=>"index"}
  end
  crumb :configuration_settings do
    link I18n.t('settings'), {:controller => "configuration", :action => "settings"}
    parent :configuration_index
  end
  crumb :courses_index do
    link I18n.t('courses_text'), {:controller => "courses", :action => "index"}
    parent :configuration_index
  end
  crumb :courses_manage_course do
    link I18n.t('manage_course'), {:controller => "courses", :action => "manage_course"}
    parent :courses_index
  end
  crumb :courses_manage_batches do
    link I18n.t('manage_batch'), {:controller => "courses", :action => "manage_batches"}
    parent :courses_index
  end
  crumb :batch_transfers_index do
    link I18n.t('batch_transfer'), {:controller => "batch_transfers", :action => "index"}
    parent :courses_manage_batches
  end
  crumb :batch_transfers_show do |batch|
    link batch.full_name, {:controller => "batch_transfers", :action => "show", :id  => batch.id}
    parent :batch_transfers_index
  end
  crumb :batch_transfers_graduation do |batch|
    link batch.full_name, {:controller => "batch_transfers", :action => "graduation", :id  => batch.id}
    parent :batch_transfers_index
  end
  crumb :revert_batch_transfers_index do
    link I18n.t('revert_batch_transfer'), {:controller => "revert_batch_transfers", :action => "index"}
    parent :courses_manage_batches
  end
  crumb :revert_batch_transfers_revert_transfer do
    link I18n.t('revert_batch_transfer'), {:controller => "revert_batch_transfers", :action => "index"}
    parent :courses_manage_batches
  end
  crumb :courses_new do
    link I18n.t('new_text'), {:controller => "courses", :action => "new"}
    parent :courses_manage_course
  end
  crumb :courses_create do
    link I18n.t('new_text'), {:controller => "courses", :action => "new"}
    parent :courses_manage_course
  end
  crumb :courses_edit do |course|
    link I18n.t('edit_text'), {:controller => "courses", :action => "edit", :id => course.id}
    parent :courses_show, course
  end
  crumb :courses_show do |course|
    link course.full_name, {:controller => "courses", :action => "show", :id => course.id}
    parent :courses_manage_course
  end
  crumb :batches_new do |course|
    link I18n.t('new_batch'),{:controller => "batches", :action => "new"}
    parent :courses_show, course
  end
  crumb :batches_show do |batch|
    link "#{I18n.t('batch')} #{batch.name_was}",{:controller => "batches", :action => "show", :id => batch.id,:course_id => batch.course.id}
    parent :courses_show, batch.course
  end
  crumb :batches_batch_summary do |batch|
    link "#{I18n.t('batch_summary')}",{:controller => "batches", :action => "batch_summary"}
  end

  crumb :batches_edit do |batch|
    link I18n.t('edit_text'),{:controller => "batches", :action => "edit",:id => batch.id}
    parent :batches_show, batch, Authorization.current_user
  end
  crumb :batches_update do |batch|
    link I18n.t('edit_text'),{:controller => "batches", :action => "edit",:id => batch.id}
    parent :batches_show, batch, Authorization.current_user
  end
  crumb :batches_assign_tutor do |batch|
    link I18n.t('assign_tutor'),{:controller => "batches", :action => "assign_tutor"}
    parent :batches_show, batch, Authorization.current_user
  end
  crumb :batch_transfers_subject_transfer do |batch|
    link I18n.t('assign_subject'),{:controller => "batch_transfers", :action => "subject_transfer"}
    parent :batches_show, batch, Authorization.current_user
  end
  crumb :subjects_index do
    link I18n.t('subjects_text'), {:controller => "subjects", :action => "index"}
    parent :configuration_index
  end
  crumb :elective_groups_index do |batch|
    link I18n.t('elective_groups_text'),{:controller => "elective_groups", :action => "index",:batch_id => batch.id}
    parent :batches_show, batch, Authorization.current_user
  end
  crumb :elective_groups_show do |elective_group|
    link elective_group.name_was,{:controller => "elective_groups", :action => "show",:id => elective_group.id,:batch_id => elective_group.batch.id}
    parent :elective_groups_index, elective_group.batch
  end
  crumb :elective_groups_edit do |elective_group|
    link I18n.t('edit_text'),{:controller => "elective_groups", :action => "edit",:id => elective_group.id,:batch_id => elective_group.batch.id}
    parent :elective_groups_show, elective_group
  end
  crumb :elective_groups_new do |batch|
    link I18n.t('new_elective'),{:controller => "elective_groups", :action => "new",:batch_id => batch.id}
    parent :batches_show, batch, Authorization.current_user
  end

  crumb :student_assigned_elective_subjects do |batch|
    link I18n.t('assigned_electives'),{:controller => "student", :action => "assigned_elective_subjects",:id => batch.id}
    parent :subjects_index
  end

  crumb :student_my_subjects do |student|
    link I18n.t('my_subjects'),{:controller => "student", :action => "my_subjects", :id => student.id}
    parent :student_profile, student
  end

  crumb :student_activities do |student|
    link I18n.t('activities'),{:controller => "student", :action => "activities", :id => student.id}
    parent :student_profile, student
  end

  crumb :employee_activities do |employee|
    link I18n.t('activities'),{:controller => "employee", :action => "activities", :id => employee.id}
    parent :employee_profile, employee
  end

  crumb :student_electives do |elective_subject|
    link elective_subject.name,{:controller => "student", :action => "electives",:id => elective_subject.elective_group.batch.id,:id2 => elective_subject.id}
    parent :elective_groups_show, elective_subject.elective_group
  end
  crumb :courses_grouped_batches do |course|
    link I18n.t('grouped_batches'),{:controller => "courses", :action => "grouped_batches", :id => course.id}
    parent :courses_show, course
  end
  crumb :courses_assign_subject_amount do |course|
    link I18n.t('assign_subject_amount'),{:controller => "courses", :action => "assign_subject_amount", :id => course.id}
    parent :courses_show, course
  end
  crumb :courses_edit_subject_amount do |subject_amount|
    link subject_amount.code,{:controller => "courses", :action => "edit_subject_amount", :subject_amount_id => subject_amount.id}
    parent :courses_assign_subject_amount, subject_amount.course
  end
  crumb :student_categories do
    link I18n.t('student_categories'), {:controller => "student", :action => "categories"}
    parent :configuration_index
  end
  crumb :student_add_additional_details do
    link I18n.t('additional_detail'), {:controller => "student", :action => "add_additional_details"}
    parent :configuration_index
  end
  crumb :student_edit_additional_details do
    link I18n.t('additional_detail'), {:controller => "student", :action => "edit_additional_details"}
    parent :configuration_index
  end
  crumb :sms_index do
    link I18n.t('sms_text'), {:controller => "sms", :action => "index"}
    parent :configuration_index
  end
  crumb :sms_settings do
    link I18n.t('settings'), {:controller => "sms", :action => "settings"}
    parent :sms_index
  end
  crumb :sms_students do
    link I18n.t('student_text'), {:controller => "sms", :action => "students"}
    parent :sms_index
  end
  crumb :sms_batches do
    link I18n.t('batches_text'), {:controller => "sms", :action => "batches"}
    parent :sms_index
  end
  crumb :sms_employees do
    link I18n.t('employees'), {:controller => "sms", :action => "employees"}
    parent :sms_index
  end
  crumb :sms_departments do
    link I18n.t('departments'), {:controller => "sms", :action => "departments"}
    parent :sms_index
  end
  crumb :sms_show_sms_messages do
    link I18n.t('sms_messages'), {:controller => "sms", :action => "show_sms_messages"}
    parent :sms_index
  end
  crumb :sms_show_sms_logs do
    link I18n.t('sms_logs'), {:controller => "sms", :action => "show_sms_logs"}
    parent :sms_show_sms_messages
  end

  ########################################
  #News Module
  ########################################
  crumb :news_index do
    link I18n.t('news_text'), {:controller => "news", :action => "index"}
  end
  crumb :news_all do
    link I18n.t('view_all'), {:controller => "news", :action => "all"}
    parent :news_index
  end
  crumb :news_view do |news|
    link shorten_string(news.title_was,20), {:controller => "news", :action => "view",:id => news.id}
    parent :news_index
  end
  crumb :news_add do
    link I18n.t('add'), {:controller => "news", :action => "add"}
    parent :news_index
  end
  crumb :news_edit do |news|
    link I18n.t('edit_text'), {:controller => "news", :action => "edit"}
    parent :news_view, news
  end

  ########################################
  #Attendance Module
  ########################################
  crumb :student_attendance_index do
    link I18n.t('attendance'), {:controller => "student_attendance", :action => "index"}
  end
  crumb :attendances_index do
    link I18n.t('attendance_register'), {:controller => "attendance", :action => "index"}
    parent :student_attendance_index
  end
  crumb :attendance_reports_index do
    link I18n.t('attendance_report'), {:controller => "attendance_reports", :action => "index"}
    parent :student_attendance_index
  end
  crumb :attendance_reports_filter do
    link I18n.t('filtered_report'), {:controller => "attendance_reports", :action => "filter"}
    parent :attendance_reports_index
  end

  crumb :attendance_reports_student_details do |student|
    link student.full_name, {:controller => "attendance_reports", :action => "student_details", :id => student.id}
    parent :attendance_reports_index
  end

  crumb :attendance_reports_day_wise_report do
    link I18n.t('day_wise_report'), {:controller => "attendance_reports", :action => "day_wise_report"}
    parent :student_attendance_index
  end

  crumb :attendance_reports_daily_report_batch_wise do
    link "#{I18n.t('day_wise_report')} - #{I18n.t('batch')}", {:controller => "attendance_reports", :action => "daily_report_batch_wise"}
    parent :attendance_reports_day_wise_report
  end

  ########################################
  #Timetable Module
  ########################################

  crumb :timetable_index do
    link I18n.t('timetable_text'), {:controller => "timetable", :action => "index"}
  end
  crumb :timetable_student_view do
    link I18n.t('timetable_text'), {:controller => "timetable", :action => "student_view"}
  end
  crumb :weekday_index do
    link I18n.t('set_weekdays_and_class_timing_set'), {:controller => "weekday", :action => "index"}
    parent :timetable_index
  end
  crumb :class_timing_sets_new_batch_class_timing_set do
    link I18n.t('manage_class_timing_sets'), {:controller => "class_timing_sets", :action => "new_batch_class_timing_set"}
    parent :timetable_index
  end
  crumb :class_timing_sets_index do
    link I18n.t('class_timing_sets'), {:controller => "class_timing_sets", :action => "index"}
    parent :timetable_index
  end
  crumb :class_timing_sets_show do |class_timing_set|
    link class_timing_set.name_was, {:controller => "class_timing_sets", :action => "show", :id => class_timing_set.id}
    parent :class_timing_sets_index
  end
  crumb :class_timing_sets_new do
    link I18n.t('new_text'), {:controller => "class_timing_sets", :action => "new"}
    parent :class_timing_sets_index
  end
  crumb :class_timing_sets_create do
    link I18n.t('new_text'), {:controller => "class_timing_sets", :action => "new"}
    parent :class_timing_sets_index
  end
  crumb :class_timing_sets_edit do |class_timing_set|
    link I18n.t('edit_text'), {:controller => "class_timing_sets", :action => "edit", :id => class_timing_set.id}
    parent :class_timing_sets_show, class_timing_set
  end
  crumb :timetable_work_allotment do
    link I18n.t('work_allotment'), {:controller => "timetable", :action => "work_allotment"}
    parent :timetable_index
  end
  crumb :timetable_new_timetable do
    link I18n.t('new_timetable'), {:controller => "timetable", :action => "new_timetable"}
    parent :timetable_index
  end
  crumb :timetable_entries_new do |timetable|
    link I18n.t('edit_entries'), {:controller => "timetable_entries", :action => "new", :timetable_id => timetable.id }
    parent :timetable_update_timetable, timetable
  end

  crumb :manage_timetable_timetables do |timetable|
    link I18n.t('manage_timetable'), {:controller => "timetable", :action => "manage_timetable", :id => timetable.id }
    parent :timetable_update_timetable, timetable
  end

  crumb :timetable_edit_master do
    link I18n.t('timetable_periods'), {:controller => "timetable", :action => "edit_master"}
    parent :timetable_index
  end
  crumb :timetable_update_timetable do |timetable|
    link "#{format_date(timetable.start_date,:format=>:long)}  -  #{format_date(timetable.end_date,:format=>:long)}", {:controller => "timetable", :action => "update_timetable", :id => timetable.id }
    parent :timetable_edit_master
  end
  crumb :timetable_view do
    link I18n.t('view'), {:controller => "timetable", :action => "view"}
    parent :timetable_index
  end
  crumb :timetable_teachers_timetable do
    link I18n.t('teacher_timetable'), {:controller => "timetable", :action => "teachers_timetable"}
    parent :timetable_index
  end
  crumb :timetable_timetable do
    link I18n.t('institutional_timetable'), {:controller => "timetable", :action => "timetable"}
    parent :timetable_index
  end
  crumb :timetable_tracker_index do
    link I18n.t('timetable_tracker'), {:controller => "timetable_tracker", :action => "index"}
    parent :timetable_index
  end
  crumb :timetable_tracker_class_timetable_swap do
    link I18n.t('swap_details'), {:controller => "timetable_tracker", :action => "class_timetable_swap"}
    parent :timetable_tracker_index
  end
  crumb :timetable_tracker_swaped_timetable_report do
    link "#{I18n.t('swaped_timetable')} #{I18n.t('report')}", {:controller => "timetable_tracker", :action => "swaped_timetable_report"}
    parent :timetable_tracker_index
  end
  crumb :timetable_employee_timetable do |employee|
    link I18n.t('teacher_timetable'), {:controller => "timetable", :action => "employee_timetable", :id => employee.id}
    parent :employee_profile, employee
  end

  crumb :buildings_new do
    link I18n.t('new_text'), {:controller => "buildings", :action => "new"}
    parent :buildings_index
  end

  crumb :buildings_create do
    link I18n.t('new_text'), {:controller => "buildings", :action => "new"}
    parent :buildings_index
  end

  crumb :classrooms_create do
    link I18n.t('new_text'), {:controller => "classrooms", :action => "new"}
    parent :buildings_index
  end

  crumb :classroom_allocations_index do
    link I18n.t('classroom_allocation'), {:controller => "classroom_allocations", :action => "index"}
    parent :timetable_index
  end

  crumb :classroom_allocations_new do
    link I18n.t('new_text'), {:controller => "classroom_allocations", :action => "new"}
    parent :classroom_allocations_index
  end

  crumb :buildings_index do
    link I18n.t('buildings'), {:controller => "buildings", :action => "index"}
    parent :classroom_allocations_index
  end

  crumb :buildings_show do |building|
    link building.name, {:controller => "buildings", :action => "show", :id => building.id }
    parent :buildings_index
  end

  crumb :classrooms_new do
    link I18n.t('new_text'), {:controller => "classrooms", :action => "new"}
    parent :buildings_index
  end

  crumb :buildings_edit do |building|
    link I18n.t('edit_text'), {:controller => "buildings", :action => "edit", :id => building.id}
    parent :buildings_index
  end

  crumb :classrooms_show do |classroom|
    link classroom.name, {:controller => "classrooms", :action => "show", :id => classroom.id }
    parent :buildings_show, classroom.building
  end

  crumb :allocated_classrooms_new do
    link I18n.t('new_text'), {:controller => "allocated_classrooms", :action => "new"}
    parent :classroom_allocations_index
  end

  crumb :classrooms_edit do |classroom|
    link I18n.t('edit_text'), {:controller => "classrooms", :action => "edit", :id => classroom.id }
    parent :buildings_show, classroom.building
  end

  ########################################
  #Examination Module
  ########################################


  crumb :exam_index do
    link I18n.t('exam_text'), {:controller=>"exam",:action=>"index"}
  end
  crumb :exam_report_center do
    link I18n.t('report_center'), {:controller=>"exam",:action=>"report_center"}
    parent :exam_index
  end
  crumb :exam_exam_wise_report do
    link I18n.t('exam_wise_report'), {:controller=>"exam",:action=>"exam_wise_report"}
    parent :exam_report_center
  end
  crumb :exam_generated_report do
    link I18n.t('generated_report'), {:controller=>"exam",:action=>"generated_report"}
    parent :exam_exam_wise_report
  end
  crumb :exam_generated_report_st_view do|list|
    link list.last.name, {:controller=>"exam",:action=>"generated_report",:exam_group =>list.last.id, :student => list.first.id}
    parent :student_reports, list.first
  end
  crumb :exam_consolidated_exam_report do
    link I18n.t('consolidated_report'), {:controller=>"exam",:action=>"consolidated_exam_report"}
    parent :exam_exam_wise_report
  end
  crumb :exam_subject_wise_report do
    link I18n.t('subject_wise_report'), {:controller=>"exam",:action=>"subject_wise_report"}
    parent :exam_report_center
  end
  crumb :exam_generated_report2 do |subject|
    link subject.name, {:controller=>"exam",:action=>"generated_report2"}
    parent :exam_subject_wise_report
  end
  crumb :exam_grouped_exam_report do
    link I18n.t('grouped_exam_reports'), {:controller=>"exam",:action=>"grouped_exam_report"}
    parent :exam_report_center
  end
  crumb :exam_generated_report3 do |student|
    link I18n.t('subject_wise_report'), {:controller=>"exam",:action=>"generated_report3" ,:student => student.id}
    parent :student_reports,student
  end
  crumb :exam_generated_report4 do |batch|
    link batch.full_name, {:controller=>"exam",:action=>"generated_report4",:exam_report => {:batch_id =>batch.id}}
    parent :exam_grouped_exam_report
  end
  crumb :exam_generated_report4_st_view do |student|
    link I18n.t('grouped_exam_reports'), {:controller=>"exam",:action=>"generated_report4", :student => student.id}
    parent :student_reports,student
  end
  crumb :exam_reports_archived_exam_wise_report do
    link I18n.t('archived_grouped_exam_reports'), {:controller=>"exam_reports",:action=>"archived_exam_wise_report"}
    parent :exam_report_center
  end
  crumb :exam_reports_archived_batches_exam_report do |batch|
    link batch.full_name, {:controller=>"exam_reports",:action=>"archived_batches_exam_report", :exam_report=>{:batch_id=>batch.id, :course_id => batch.course.id}}
    parent :exam_reports_archived_exam_wise_report
  end
  crumb :exam_subject_rank do
    link I18n.t('student_ranking_per_subject'), {:controller=>"exam",:action=>"subject_rank"}
    parent :exam_report_center
  end
  crumb :exam_student_subject_rank do |subject|
    link subject.name, {:controller=>"exam",:action=>"student_subject_rank",:rank_report => {:batch_id =>subject.batch.id, :subject_id => subject.id}}
    parent :exam_subject_rank
  end
  crumb :exam_batch_rank do
    link I18n.t('student_ranking_per_batch'), {:controller=>"exam",:action=>"batch_rank"}
    parent :exam_report_center
  end
  crumb :exam_student_batch_rank do |batch|
    link batch.name, {:controller=>"exam",:action=>"student_batch_rank",:batch_rank => {:batch_id =>batch.id}}
    parent :exam_batch_rank
  end
  crumb :exam_course_rank do
    link I18n.t('student_ranking_per_course'), {:controller=>"exam",:action=>"course_rank"}
    parent :exam_report_center
  end
  crumb :exam_student_course_rank do |course|
    link course.full_name, {:controller=>"exam",:action=>"student_course_rank", :course_rank => {:course_id =>course.id}}
    parent :exam_course_rank
  end
  crumb :exam_attendance_rank do
    link I18n.t('student_ranking_per_attendance'), {:controller=>"exam",:action=>"attendance_rank"}
    parent :exam_report_center
  end
  crumb :exam_student_attendance_rank do |batch|
    link batch.full_name, {:controller=>"exam",:action=>"student_attendance_rank", :attendance_rank =>{:batch_id =>batch.id}}
    parent :exam_attendance_rank
  end
  crumb :exam_student_school_rank do
    link I18n.t('student_ranking_per_school'), {:controller=>"exam",:action=>"student_school_rank"}
    parent :exam_report_center
  end
  crumb :exam_ranking_level_report do
    link I18n.t('ranking_level_report'), {:controller=>"exam",:action=>"ranking_level_report"}
    parent :exam_report_center
  end
  crumb :exam_student_ranking_level_report_batch do |batch|
    link batch.name, {:controller=>"exam",:action=>"student_ranking_level_report"}
    parent :exam_ranking_level_report
  end
  crumb :exam_student_ranking_level_report_course do |course|
    link course.full_name, {:controller=>"exam",:action=>"student_ranking_level_report"}
    parent :exam_ranking_level_report
  end
  crumb :exam_transcript do
    link I18n.t('view_transcripts'), {:controller=>"exam",:action=>"transcript"}
    parent :exam_report_center
  end
  crumb :student_transcript do|batch|
    link batch.name, {:controller=>"exam",:action=>"student_transcript"}
    parent :exam_transcript
  end
  crumb :exam_combined_report do
    link I18n.t('combined_report'), {:controller=>"exam",:action=>"combined_report"}
    parent :exam_report_center
  end
  crumb :exam_student_combined_report do |batch|
    link batch.full_name, {:controller=>"exam",:action=>"student_combined_report"}
    parent :exam_combined_report
  end
  crumb :cce_reports_index do
    link I18n.t('cce_reports'), {:controller=>"cce_reports",:action=>"index"}
    parent :exam_report_center
  end
  crumb :cce_reports_create_reports do
    link I18n.t('generate_cce_report'), {:controller=>"cce_reports",:action=>"create_reports"}
    parent :cce_reports_index
  end
  crumb :cce_report_schedule_jobs do
    link "#{I18n.t('scheduled_job_for')} #{I18n.t('cce_reports')}", {:controller=>"scheduled_jobs", :job_type=>"3", :action=>"index", :job_object=>"Batch"}
    parent :cce_reports_create_reports
  end
  crumb :cce_reports_student_wise_report do
    link I18n.t('student_wise_report'), {:controller=>"cce_reports",:action=>"student_wise_report"}
    parent :cce_reports_index
  end
  crumb :cce_reports_assessment_wise_report do
    link I18n.t('assessment_wise_report'), {:controller=>"cce_reports",:action=>"assessment_wise_report"}
    parent :cce_reports_index
  end
  crumb :cce_reports_subject_wise_report do
    link I18n.t('subject_wise_report'), {:controller=>"cce_reports",:action=>"subject_wise_report"}
    parent :cce_reports_index
  end
  crumb :cce_reports_student_transcript do |student|
    link I18n.t('cce_transcript_report'), {:controller=>"cce_reports",:action=>"student_transcript", :id => student.id}
    parent :archived_student_reports,student
  end

  crumb :cce_reports_student_transcript1 do |student|
    link I18n.t('cce_transcript_report'), {:controller=>"cce_reports",:action=>"student_transcript", :id => student.id}
    parent :student_reports,student
  end

  crumb :icse_reports_student_transcript do |student|
    link "ICSE Transcript Report", {:controller=>"icse_reports",:action=>"student_transcript", :id => student.id}
    parent :student_reports,student
  end
  crumb :icse_reports_student_transcript1 do |student|
    link "ICSE Transcript Report", {:controller=>"icse_reports",:action=>"student_transcript", :id => student.id}
    parent :archived_student_reports,student
  end

  crumb :exam_settings do
    link I18n.t('settings'), {:controller => "exam", :action => "settings"}
    parent :exam_index
  end
  crumb :grading_levels_index do
    link I18n.t('grading_levels_text'), {:controller => "grading_levels", :action => "index"}
    parent :exam_settings
  end
  crumb :ranking_levels_index do
    link I18n.t('ranking_levels_text'), {:controller => "ranking_levels", :action => "index"}
    parent :exam_settings
  end
  crumb :class_designations_index do
    link I18n.t('class_designations_text'), {:controller => "class_designations", :action => "index"}
    parent :exam_settings
  end
  crumb :cce_settings_index do
    link I18n.t('cce_sttings'), {:controller => "cce_settings", :action => "index"}
    parent :exam_settings
  end
  crumb :cce_settings_basic do
    link I18n.t('basic_settings'), {:controller => "cce_settings", :action => "basic"}
    parent :cce_settings_index
  end
  crumb :cce_grade_sets_index do
    link I18n.t('grade_sets_text'), {:controller => "cce_grade_sets", :action => "index"}
    parent :cce_settings_basic
  end
  crumb :cce_grade_sets_show do |grade_set|
    link grade_set.name, {:controller => "cce_grade_sets", :action => "show", :id =>grade_set.id }
    parent :cce_grade_sets_index
  end
  crumb :cce_exam_categories_index do
    link I18n.t('cce_exam_categories_text'), {:controller => "cce_exam_categories", :action => "index"}
    parent :cce_settings_basic
  end
  crumb :cce_weightages_index do
    link I18n.t('cce_weightages'), {:controller => "cce_weightages", :action => "index"}
    parent :cce_settings_basic
  end
  crumb :cce_weightages_show do |weightage|
    link "#{weightage.weightage}(#{weightage.criteria_type})", {:controller => "cce_weightages", :action => "show", :id =>weightage.id}
    parent :cce_weightages_index
  end
  crumb :cce_weightages_assign_weightages do
    link I18n.t('assign_weightages'), {:controller => "cce_weightages", :action => "assign_weightages"}
    parent :cce_settings_basic
  end
  crumb :cce_settings_co_scholastic do
    link I18n.t('co_scholastic_settings'), {:controller => "cce_settings", :action => "co_scholastic"}
    parent :cce_settings_index
  end
  crumb :observation_groups_index do
    link I18n.t('observation_groups'), {:controller => "observation_groups", :action => "index"}
    parent :cce_settings_co_scholastic
  end
  crumb :observation_groups_show do |obs_group|
    link obs_group.name, {:controller => "observation_groups", :action => "show", :id => obs_group.id}
    parent :observation_groups_index
  end
  crumb :descriptive_indicators_index do |observation|
    link observation.name, {:controller => "descriptive_indicators", :action => "index", :observation_id=>observation.id}
    parent :observation_groups_show, observation.observation_group
  end
  crumb :descriptive_indicators_fa_index do |fa_criteria|
    link fa_criteria.fa_name, {:controller => "descriptive_indicators", :action => "index", :fa_criteria_id=>fa_criteria.id}
    parent :fa_groups_show, fa_criteria.fa_group
  end
  crumb :observation_groups_assign_courses do
    link I18n.t('assign_courses'), {:controller => "observation_groups", :action => "assign_courses"}
    parent :cce_settings_co_scholastic
  end
  crumb :cce_settings_scholastic do
    link I18n.t('scholastic_settings'), {:controller => "cce_settings", :action => "scholastic"}
    parent :cce_settings_index
  end
  crumb :fa_groups_index do
    link I18n.t('assessment_groups'), {:controller => "fa_groups", :action => "index"}
    parent :cce_settings_scholastic
  end
  crumb :fa_groups_show do |fa_group|
    link fa_group.name, {:controller => "fa_groups", :action => "show", :id => fa_group.id}
    parent :fa_groups_index
  end
  crumb :fa_groups_assign_fa_groups do
    link I18n.t('assign_subjects_descr'), {:controller => "fa_groups", :action => "assign_fa_groups"}
    parent :cce_settings_scholastic
  end
  crumb :fa_groups_edit_criteria_formula do |fa_group|
    link "Edit Criteria Formula", {:controller => "fa_groups", :action => "edit_criteria_formula", :id => fa_group.id}
    parent :fa_groups_show, fa_group
  end
  crumb :exam_create_exam do
    link I18n.t('exam_management'), {:controller => "exam", :action => "create_exam"}
    parent :exam_index
  end
  crumb :exam_course_wise_exams do
    link I18n.t('course_wise_exam'), {:controller => "exam", :action => "course_wise_exams"}
    parent :exam_create_exam
  end
  crumb :exam_groups_index do |batch|
    link "#{I18n.t('batch')} #{batch.full_name}", {:controller => "exam_groups", :action => "index", :batch_id =>batch.id }
    parent :exam_create_exam
  end
  crumb :exam_gpa_settings do
    link I18n.t('gpa_settings'), {:controller => "exam", :action => "gpa_settings"}
    parent :exam_settings
  end
  crumb :exam_previous_batch_exams do
    link "#{I18n.t('previous_batch_exam')}", {:controller => "exam", :action => "previous_batch_exams" }
    parent :exam_create_exam
  end
  crumb :exam_groups_new do |batch|
    link I18n.t('new_exam'), {:controller => "exam_groups", :action => "new", :batch_id =>batch.id }
    parent :exam_groups_index, batch
  end
  crumb :exam_grouping do |batch|
    link I18n.t('connect_exams'), {:controller => "exam", :action => "grouping", :id =>batch.id }
    parent :exam_groups_index, batch
  end
  crumb :exam_groups_show do |exam_group|
    link exam_group.name, {:controller => "exam_groups", :action => "show", :id =>exam_group.id,:batch_id =>exam_group.batch.id }
    parent :exam_groups_index, exam_group.batch, Authorization.current_user
  end
  crumb :exams_new do |exam_group|
    link I18n.t('new_text'), {:controller => "exams", :action => "new", :exam_group_id =>exam_group.id }
    parent :exam_groups_show, exam_group
  end
  crumb :exams_show do |exam|
    link exam.subject.name, {:controller => "exams", :action => "show", :id => exam.id, :exam_group_id =>exam.exam_group.id }
    parent :exam_groups_show, exam.exam_group, Authorization.current_user
  end
  crumb :exams_edit do |exam|
    link I18n.t('edit_text'), {:controller => "exams", :action => "edit", :id => exam.id, :exam_group_id =>exam.exam_group.id }
    parent :exams_show, exam, Authorization.current_user
  end
  crumb :assessment_scores_observation_groups do |batch|
    link I18n.t('select_a_criteria'), {:controller => "assessment_scores", :action => "observation_groups", :batch_id =>batch.id }
    parent :exam_groups_index, batch, Authorization.current_user
  end
  crumb :assessment_scores_observation_scores do |list|
    link list.last.name, {:controller => "assessment_scores", :action => "observation_scores", :batch_id =>list.first.id, :observation_group_id => list.last.id}
    parent :assessment_scores_observation_groups, list.first
  end
  crumb :assessment_scores_exam_fa_groups do |exam|
    link I18n.t('select_an_fa'), {:controller => "assessment_scores", :action => "exam_fa_groups", :id => exam.id, :exam_group_id =>exam.exam_group.id }
    parent :exams_show, exam, Authorization.current_user
  end
  crumb :assessment_scores_fa_scores do |list|
    link list.last.name, {:controller => "assessment_scores", :action => "fa_scores", :fa_group_id => list.first.id, :exam_id =>list.last.id }
    parent :assessment_scores_exam_fa_groups, list.first
  end
  crumb :exam_generate_reports do
    link I18n.t('generate_reports'), {:controller => "exam", :action => "generate_reports"}
    parent :exam_index
  end
  crumb :exam_generate_previous_reports do
    link I18n.t('generate_previous_reports'), {:controller => "exam", :action => "generate_previous_reports"}
    parent :exam_generate_reports
  end
  crumb :current_schedule_jobs do
    link "#{I18n.t('scheduled_job_for')} #{I18n.t('current_batch')}", {:controller=>"scheduled_jobs", :job_type=>"1", :action=>"index", :job_object=>"Batch"}
    parent :exam_generate_reports
  end
  crumb :previous_schedule_jobs do
    link "#{I18n.t('scheduled_job_for')} #{I18n.t('previous_batch')}", {:controller=>"scheduled_jobs", :job_type=>"2", :action=>"index", :job_object=>"Batch"}
    parent :exam_generate_previous_reports
  end

  crumb :current_schedule_jobs do
    link "#{I18n.t('scheduled_job_for')} #{I18n.t('current_batch')}", {:controller=>"scheduled_jobs", :job_type=>"1", :action=>"index", :job_object=>"Batch"}
    parent :exam_generate_reports
  end

  ########################################
  #Reminder
  ########################################
  crumb :reminder_index do
    link I18n.t('inbox'), {:controller=>"reminder", :action=>"index"}
  end
  crumb :reminder_view_reminder do |reminder|
    link "#{I18n.t('view')} #{I18n.t('message')}", {:controller=>"reminder",:id =>reminder.id ,:action=>"view_reminder"}
    parent :reminder_index
  end
  crumb :reminder_sent_reminder do
    link I18n.t('outbox'), {:controller=>"reminder", :action=>"sent_reminder"}
  end
  crumb :reminder_view_sent_reminder do |reminder|
    link "#{I18n.t('view')} #{I18n.t('sent_message')}", {:controller=>"reminder",:id =>reminder.id ,:action=>"view_sent_reminder"}
    parent :reminder_sent_reminder
  end
  crumb :reminder_create_reminder do
    link I18n.t('create_message'), {:controller => "reminder", :action => "create_reminder"}
  end
  ########################################
  #Event
  ########################################
  crumb :event_index do
    link I18n.t('event_text'), {:controller=>"event", :action=>"index"}
  end
  crumb :event_show do |event|
    link shorten_string(event.title_was,20), {:controller=>"event", :action=>"show", :id => event.id }
    parent :event_index
  end
  crumb :event_edit do |event|
    link "#{I18n.t('edit_text')} - #{shorten_string(event.title_was,20)}", {:controller=>"event", :action=>"edit", :id => event.id }
    parent :event_index
  end



  ###############################################
  #Report
  ################################################

  crumb :report_index do
    link I18n.t('reports_text'), {:controller=>"report", :action=>"index"}
  end

  crumb :report_course_batch_details do
    link I18n.t('all_courses'), {:controller=>"report", :action=>"course_batch_details"}
    parent :report_index
  end

  crumb :report_batch_details do |course|
    link course.course_name, {:controller=>"report", :action=>"batch_details",:id=>course.id}
    parent :report_course_batch_details
  end

  crumb :report_batch_students do |batch|
    link batch.name, {:controller=>"report", :action=>"batch_students",:id=>batch.id}
    parent :report_batch_details,batch.course
  end

  crumb :report_batch_details_all do
    link I18n.t('all_batches'), {:controller=>"report", :action=>"batch_details_all"}
    parent :report_index
  end

  crumb :report_students_all do
    link I18n.t('all_students'), {:controller=>"report", :action=>"students_all"}
    parent :report_index
  end

  crumb :report_employees do
    link I18n.t('all_employee'), {:controller=>"report", :action=>"employees"}
    parent :report_index
  end

  crumb :report_former_students do
    link I18n.t('former_student_details'), {:controller=>"report", :action=>"former_students"}
    parent :report_index
  end

  crumb :report_former_employees do
    link I18n.t('former_employee_details'), {:controller=>"report", :action=>"former_employees"}
    parent :report_index
  end

  crumb :report_subject_details do
    link I18n.t('subject_details'), {:controller=>"report", :action=>"subject_details"}
    parent :report_index
  end

  crumb :report_employee_subject_association do
    link I18n.t('employee_subject_association_details'), {:controller=>"report", :action=>"employee_subject_association"}
    parent :report_index
  end

  crumb :report_employee_payroll_details do
    link I18n.t('employee_payroll_details'), {:controller=>"report", :action=>"employee_payroll_details"}
    parent :report_index
  end

  crumb :report_exam_schedule_details do
    link I18n.t('exam_schedule_details'), {:controller=>"report", :action=>"exam_schedule_details"}
    parent :report_index
  end

  crumb :report_fee_collection_details do
    link I18n.t('fee_collection_details'), {:controller=>"report", :action=>"fee_collection_details"}
    parent :report_index
  end

  crumb :report_course_fee_defaulters do
    link I18n.t('course_text')+" "+I18n.t('fees_defaulters_text'), {:controller=>"report", :action=>"course_fee_defaulters"}
    parent :report_index
  end

  crumb :report_batch_fee_defaulters do |course|
    link I18n.t('batch')+" "+I18n.t('fees_defaulters_text'), {:controller=>"report", :action=>"batch_fee_defaulters",:id=>course.id}
    parent :report_course_fee_defaulters
  end

  crumb :report_batch_fee_collections do |batch|
    link I18n.t('batch')+" "+I18n.t('fee_collection'), {:controller=>"report", :action=>"batch_fee_collections",:id=>batch.id}
    parent :report_batch_fee_defaulters,batch.course
  end

  crumb :report_students_fee_defaulters do |batch|
    link I18n.t('student_wise_fee_defaulters'), {:controller=>"report", :action=>"students_fee_defaulters",:id=>batch.id}
    parent :report_batch_fee_collections,batch
  end

  crumb :report_student_wise_fee_defaulters do
    link I18n.t('student_wise_fee_defaulters'), {:controller=>"report", :action=>"student_wise_fee_defaulters"}
    parent :report_index
  end

  crumb :report_student_wise_fee_collections do |student|
    link student.full_name, {:controller=>"report", :action=>"student_wise_fee_collections",:id=>student.id}
    parent :report_student_wise_fee_defaulters
  end

  crumb :report_course_students do |course|
    link I18n.t('course_text')+" "+I18n.t('student_details'), {:controller=>"report", :action=>"course_students",:id=>course.id}
    parent :report_course_batch_details
  end


  ##########################################
  #Remarks Module
  ##########################################
  crumb :remarks_show_remarks do |student|
    link I18n.t('remarks'), {:controller=>"remarks", :action=>"custom_remark_list",:student_id=>student.id}
    parent :student_profile,student
  end

  crumb :remarks_index do
    link I18n.t('remarks'), {:controller=>"remarks", :action=>"index"}
  end

  crumb :remarks_add_employee_custom_remarks do |remark|
    link I18n.t('add_employee_custom_remarks'), {:controller=>"remarks", :action=>"add_employee_custom_remarks"}
    parent :remarks_index
  end

  crumb :remarks_employee_list_custom_remarks do
    link I18n.t('list_custom_remarks'), {:controller=>"remarks", :action=>"employee_list_custom_remarks"}
    parent :remarks_index
  end

  crumb :remarks_remarks_history do |student|
    link I18n.t('remark_history'), {:controller=>"remarks", :action=>"remarks_history",:id=>student.id}
    parent :remarks_show_remarks,student
  end

  crumb :archive_remarks_history do |student|
    link I18n.t('remark_history'), {:controller=>"remarks", :action=>"remarks_history",:id=>student.id}
    parent :archived_student_profile,student
  end

  crumb :report_fees_head_wise_report do
    link I18n.t('fees_head_wise_report'), {:controller=>"report", :action=>"fees_head_wise_report"}
    parent :report_index
  end

  crumb :report_batch_fees_headwise_report do
    link "#{I18n.t('batch')} #{I18n.t('wise')} #{I18n.t('report')}", {:controller=>"report", :action=>"batch_fees_headwise_report"}
    parent :report_fees_head_wise_report
  end

  crumb :report_fee_collection_head_wise_report do
    link "#{I18n.t('fee_collection')} #{I18n.t('wise')} #{I18n.t('report')}", {:controller=>"report", :action=>"fee_collection_head_wise_report"}
    parent :report_fees_head_wise_report
  end

  crumb :report_search_student do
    link "#{I18n.t('students')} #{I18n.t('wise')} #{I18n.t('report')}", {:controller=>"report", :action=>"search_student"}
    parent :report_fees_head_wise_report
  end

  crumb :report_student_fees_headwise_report do |student|
    link student.full_name, {:controller=>"report", :action=>"student_fees_headwise_report",:id=>student.id}
    parent :report_search_student
  end

  #  crumb :project do |project|
  #    link lambda { |project| "#{project.name} (#{project.id.to_s})" }, project_path(project)
  #    parent :projects
  #  end
  #
  #  crumb :project_issues do |project|
  #    link "Issues", project_issues_path(project)
  #    parent :project, project
  #  end
  #
  #  crumb :issue do |issue|
  #    link issue.name, issue_path(issue)
  #    parent :project_issues, issue.project
  #  end
  #
  crumb :icse_settings_index do
    link "ICSE Settings", {:controller=>"icse_settings", :action=>"index"}
    parent :exam_settings
  end

  crumb :icse_settings_icse_exam_categories do
    link "ICSE Exam Categories", {:controller=>"icse_settings", :action=>"icse_exam_categories"}
    parent :icse_settings_index
  end

  crumb :icse_settings_icse_weightages do
    link "ICSE Weightages", {:controller=>"icse_settings", :action=>"icse_weightages"}
    parent :icse_settings_index
  end

  crumb :icse_settings_assign_icse_weightages do
    link "Assign Weightages",{:controller=>"icse_settings", :action=>"assign_icse_weightages"}
    parent :icse_settings_index
  end
  crumb :icse_settings_internal_assessment_groups do
    link "IA Groups" ,{:controller=>"icse_settings", :action=>"internal_assessment_groups"}
    parent :icse_settings_index
  end
  crumb :icse_settings_new_ia_group do
    link "New IA Group" ,{:controller=>"icse_settings", :action=>"new_ia_group"}
    parent :icse_settings_internal_assessment_groups
  end

  crumb :icse_settings_create_ia_group do
    link "New IA Group" ,{:controller=>"icse_settings", :action=>"new_ia_group"}
    parent :icse_settings_internal_assessment_groups
  end
  crumb :icse_settings_edit_ia_group do |ia_group|
    link "Edit IA Group" ,{:controller=>"icse_settings", :action=>"new_ia_group",:id=>ia_group.id}
    parent :icse_settings_internal_assessment_groups
  end
  crumb :icse_settings_assign_ia_groups do
    link "Assign IA Groups" ,{:controller=>"icse_settings", :action=>"assign_ia_groups"}
    parent :icse_settings_index
  end
  crumb :ia_scores do |exam|
    link "IA Scores" , {:controller=>:ia_scores,:action=>:ia_scores,:exam_id=>exam.id}
    parent :exams_show,exam, Authorization.current_user
  end
  crumb :icse_reports_index do
    link "ICSE Reports", {:controller=>:icse_reports,:action=>:index}
    parent :exam_report_center
  end
  crumb :icse_reports_generate_reports do
    link "Generate ICSE report",{:controller=>:icse_reports,:action=>:generate_reports}
    parent :icse_reports_index
  end
  crumb :icse_reports_student_wise_report do
    link "Student-wise report",{:controller=>:icse_reports,:action=>:student_wise_report}
    parent :icse_reports_index
  end
  crumb :icse_reports_subject_wise_report do
    link "Subject-wise report",{:controller=>:icse_reports,:action=>:subject_wise_report}
    parent :icse_reports_index
  end
  crumb :icse_reports_consolidated_report do
    link "Consolidated report",{:controller=>:icse_reports,:action=>:consolidated_report}
    parent :icse_reports_index
  end
end

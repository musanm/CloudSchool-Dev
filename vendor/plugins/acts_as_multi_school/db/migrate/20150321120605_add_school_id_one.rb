class AddSchoolIdOne < ActiveRecord::Migration
  def self.up
      add_column :employee_positions, :school_id, :integer
      add_column :employee_leaves, :school_id, :integer
      add_column :apply_leaves, :school_id, :integer
      add_column :employee_leave_types, :school_id, :integer
      add_column :employee_bank_details, :school_id, :integer
      add_column :employees, :school_id, :integer
      add_column :employee_salary_structures, :school_id, :integer
      add_column :employee_departments, :school_id, :integer
      add_column :employee_categories, :school_id, :integer
      add_column :individual_payslip_categories, :school_id, :integer
      add_column :payroll_categories, :school_id, :integer
      add_column :monthly_payslips, :school_id, :integer
      add_column :employee_department_events, :school_id, :integer
      add_column :bank_fields, :school_id, :integer
      add_column :employees_subjects, :school_id, :integer
      add_column :employee_attendances, :school_id, :integer
      add_column :employee_additional_details, :school_id, :integer
      add_column :student_previous_subject_marks, :school_id, :integer
      add_column :exam_groups, :school_id, :integer
      add_column :archived_exam_scores, :school_id, :integer
      add_column :courses, :school_id, :integer
      add_column :archived_guardians, :school_id, :integer
      add_column :student_categories, :school_id, :integer
      add_column :news_comments, :school_id, :integer
      add_column :additional_fields, :school_id, :integer
      add_column :subjects, :school_id, :integer
      add_column :archived_employee_bank_details, :school_id, :integer
      add_column :grading_levels, :school_id, :integer
      add_column :batches, :school_id, :integer
      add_column :archived_employees, :school_id, :integer
      add_column :archived_students, :school_id, :integer
      add_column :student_additional_details, :school_id, :integer
      add_column :exams, :school_id, :integer
      add_column :weekdays, :school_id, :integer
      add_column :electives, :school_id, :integer
      add_column :archived_employee_salary_structures, :school_id, :integer
      add_column :configurations, :school_id, :integer
      add_column :grouped_exams, :school_id, :integer
      add_column :student_previous_datas, :school_id, :integer
      add_column :batch_events, :school_id, :integer
      add_column :period_entries, :school_id, :integer
      add_column :guardians, :school_id, :integer
      add_column :timetable_entries, :school_id, :integer
      add_column :student_additional_fields, :school_id, :integer
      add_column :events, :school_id, :integer
      add_column :archived_employee_additional_details, :school_id, :integer
      add_column :students, :school_id, :integer
      add_column :finance_transaction_triggers, :school_id, :integer
      add_column :finance_fee_categories, :school_id, :integer
      add_column :liabilities, :school_id, :integer
      add_column :news, :school_id, :integer
      add_column :finance_transactions, :school_id, :integer
      add_column :elective_groups, :school_id, :integer
      add_column :fee_discounts, :school_id, :integer
      add_column :finance_fee_collections, :school_id, :integer
      add_column :fee_collection_particulars, :school_id, :integer
      add_column :finance_fee_structure_elements, :school_id, :integer
      add_column :finance_donations, :school_id, :integer
      add_column :users, :school_id, :integer
      add_column :assets, :school_id, :integer
      add_column :user_events, :school_id, :integer
      add_column :finance_fee_particulars, :school_id, :integer
      add_column :sms_settings, :school_id, :integer
      add_column :class_timings, :school_id, :integer
      add_column :fee_collection_discounts, :school_id, :integer
      add_column :reminders, :school_id, :integer
      add_column :students_subjects, :school_id, :integer
      add_column :finance_transaction_categories, :school_id, :integer
      add_column :exam_scores, :school_id, :integer
      add_column :finance_fees, :school_id, :integer
      add_column :attendances, :school_id, :integer
      add_column :employee_grades, :school_id, :integer
      add_column :timetables, :school_id, :integer
      add_column :subject_leaves, :school_id, :integer
      add_column :sms_messages, :school_id, :integer
      add_column :sms_logs, :school_id, :integer
      add_column :batch_groups, :school_id, :integer
      add_column :class_designations, :school_id, :integer
      add_column :grouped_batches, :school_id, :integer
      add_column :grouped_exam_reports, :school_id, :integer
      add_column :previous_exam_scores, :school_id, :integer
      add_column :ranking_levels, :school_id, :integer
      add_column :assessment_scores, :school_id, :integer
      add_column :cce_exam_categories, :school_id, :integer
      add_column :cce_grades, :school_id, :integer
      add_column :cce_grade_sets, :school_id, :integer
      add_column :cce_reports, :school_id, :integer
      add_column :cce_weightages, :school_id, :integer
      add_column :descriptive_indicators, :school_id, :integer
      add_column :fa_criterias, :school_id, :integer
      add_column :fa_groups, :school_id, :integer
      add_column :observation_groups, :school_id, :integer
      add_column :observations, :school_id, :integer
      add_column :cancelled_finance_transactions, :school_id, :integer
      add_column :additional_field_options, :school_id, :integer
      add_column :batch_students, :school_id, :integer
      add_column :student_additional_field_options, :school_id, :integer
      add_column :subject_amounts, :school_id, :integer
      add_column :weekday_sets_weekdays, :school_id, :integer
      add_column :weekday_sets, :school_id, :integer
      add_column :time_table_weekdays, :school_id, :integer
      add_column :time_table_class_timings, :school_id, :integer
      add_column :class_timing_sets, :school_id, :integer
      add_column :biometric_informations, :school_id, :integer
      add_column :user_menu_links, :school_id, :integer
      add_column :timetable_swaps, :school_id, :integer
      add_column :fines, :school_id, :integer
      add_column :fine_rules, :school_id, :integer
      add_column :fee_refunds, :school_id, :integer
      add_column :refund_rules, :school_id, :integer
      add_column :collection_particulars, :school_id, :integer
      add_column :collection_discounts, :school_id, :integer
      add_column :fee_transactions, :school_id, :integer
      add_column :fee_collection_batches, :school_id, :integer
      add_column :category_batches, :school_id, :integer
      add_column :additional_report_csvs, :school_id, :integer
      add_column :redactor_uploads, :school_id, :integer
      add_column :allocated_classrooms, :school_id, :integer
      add_column :buildings, :school_id, :integer
      add_column :classrooms, :school_id, :integer
      add_column :classroom_allocations, :school_id, :integer
      add_column :ia_calculations, :school_id, :integer
      add_column :ia_groups, :school_id, :integer
      add_column :ia_indicators, :school_id, :integer
      add_column :ia_scores, :school_id, :integer
      add_column :icse_exam_categories, :school_id, :integer
      add_column :icse_reports, :school_id, :integer
      add_column :icse_weightages, :school_id, :integer
      add_column :remarks, :school_id, :integer
      add_column :remark_parameters, :school_id, :integer
      add_column :multi_fees_transactions, :school_id, :integer
      add_column :particular_payments, :school_id, :integer
      add_column :particular_discounts, :school_id, :integer
      add_column :attendance_weekday_sets, :school_id, :integer
      add_column :discount_particular_logs, :school_id, :integer
      add_column :batch_class_timing_sets, :school_id, :integer
      add_column :time_table_class_timing_sets, :school_id, :integer
  
      add_index :employee_positions, :school_id
      add_index :employee_leaves, :school_id
      add_index :apply_leaves, :school_id
      add_index :employee_leave_types, :school_id
      add_index :employee_bank_details, :school_id
      add_index :employees, :school_id
      add_index :employee_salary_structures, :school_id
      add_index :employee_departments, :school_id
      add_index :employee_categories, :school_id
      add_index :individual_payslip_categories, :school_id
      add_index :payroll_categories, :school_id
      add_index :monthly_payslips, :school_id
      add_index :employee_department_events, :school_id
      add_index :bank_fields, :school_id
      add_index :employees_subjects, :school_id
      add_index :employee_attendances, :school_id
      add_index :employee_additional_details, :school_id
      add_index :student_previous_subject_marks, :school_id
      add_index :exam_groups, :school_id
      add_index :archived_exam_scores, :school_id
      add_index :courses, :school_id
      add_index :archived_guardians, :school_id
      add_index :student_categories, :school_id
      add_index :news_comments, :school_id
      add_index :additional_fields, :school_id
      add_index :subjects, :school_id
      add_index :archived_employee_bank_details, :school_id
      add_index :grading_levels, :school_id
      add_index :batches, :school_id
      add_index :archived_employees, :school_id
      add_index :archived_students, :school_id
      add_index :student_additional_details, :school_id
      add_index :exams, :school_id
      add_index :weekdays, :school_id
      add_index :electives, :school_id
      add_index :archived_employee_salary_structures, :school_id
      add_index :configurations, :school_id
      add_index :grouped_exams, :school_id
      add_index :student_previous_datas, :school_id
      add_index :batch_events, :school_id
      add_index :period_entries, :school_id
      add_index :guardians, :school_id
      add_index :timetable_entries, :school_id
      add_index :student_additional_fields, :school_id
      add_index :events, :school_id
      add_index :archived_employee_additional_details, :school_id
      add_index :students, :school_id
      add_index :finance_transaction_triggers, :school_id
      add_index :finance_fee_categories, :school_id
      add_index :liabilities, :school_id
      add_index :news, :school_id
      add_index :finance_transactions, :school_id
      add_index :elective_groups, :school_id
      add_index :fee_discounts, :school_id
      add_index :finance_fee_collections, :school_id
      add_index :fee_collection_particulars, :school_id
      add_index :finance_fee_structure_elements, :school_id
      add_index :finance_donations, :school_id
      add_index :users, :school_id
      add_index :assets, :school_id
      add_index :user_events, :school_id
      add_index :finance_fee_particulars, :school_id
      add_index :sms_settings, :school_id
      add_index :class_timings, :school_id
      add_index :fee_collection_discounts, :school_id
      add_index :reminders, :school_id
      add_index :students_subjects, :school_id
      add_index :finance_transaction_categories, :school_id
      add_index :exam_scores, :school_id
      add_index :finance_fees, :school_id
      add_index :attendances, :school_id
      add_index :employee_grades, :school_id
      add_index :timetables, :school_id
      add_index :subject_leaves, :school_id
      add_index :sms_messages, :school_id
      add_index :sms_logs, :school_id
      add_index :batch_groups, :school_id
      add_index :class_designations, :school_id
      add_index :grouped_batches, :school_id
      add_index :grouped_exam_reports, :school_id
      add_index :previous_exam_scores, :school_id
      add_index :ranking_levels, :school_id
      add_index :assessment_scores, :school_id
      add_index :cce_exam_categories, :school_id
      add_index :cce_grades, :school_id
      add_index :cce_grade_sets, :school_id
      add_index :cce_reports, :school_id
      add_index :cce_weightages, :school_id
      add_index :descriptive_indicators, :school_id
      add_index :fa_criterias, :school_id
      add_index :fa_groups, :school_id
      add_index :observation_groups, :school_id
      add_index :observations, :school_id
      add_index :cancelled_finance_transactions, :school_id
      add_index :additional_field_options, :school_id
      add_index :batch_students, :school_id
      add_index :student_additional_field_options, :school_id
      add_index :subject_amounts, :school_id
      add_index :weekday_sets_weekdays, :school_id
      add_index :weekday_sets, :school_id
      add_index :time_table_weekdays, :school_id
      add_index :time_table_class_timings, :school_id
      add_index :class_timing_sets, :school_id
      add_index :biometric_informations, :school_id
      add_index :user_menu_links, :school_id
      add_index :timetable_swaps, :school_id
      add_index :fines, :school_id
      add_index :fine_rules, :school_id
      add_index :fee_refunds, :school_id
      add_index :refund_rules, :school_id
      add_index :collection_particulars, :school_id
      add_index :collection_discounts, :school_id
      add_index :fee_transactions, :school_id
      add_index :fee_collection_batches, :school_id
      add_index :category_batches, :school_id
      add_index :additional_report_csvs, :school_id
      add_index :redactor_uploads, :school_id
      add_index :allocated_classrooms, :school_id
      add_index :buildings, :school_id
      add_index :classrooms, :school_id
      add_index :classroom_allocations, :school_id
      add_index :ia_calculations, :school_id
      add_index :ia_groups, :school_id
      add_index :ia_indicators, :school_id
      add_index :ia_scores, :school_id
      add_index :icse_exam_categories, :school_id
      add_index :icse_reports, :school_id
      add_index :icse_weightages, :school_id
      add_index :remarks, :school_id
      add_index :remark_parameters, :school_id
      add_index :multi_fees_transactions, :school_id
      add_index :particular_payments, :school_id
      add_index :particular_discounts, :school_id
      add_index :attendance_weekday_sets, :school_id
      add_index :discount_particular_logs, :school_id
      add_index :batch_class_timing_sets, :school_id
      add_index :time_table_class_timing_sets, :school_id
    end

  def self.down
      remove_index :employee_positions, :school_id
      remove_index :employee_leaves, :school_id
      remove_index :apply_leaves, :school_id
      remove_index :employee_leave_types, :school_id
      remove_index :employee_bank_details, :school_id
      remove_index :employees, :school_id
      remove_index :employee_salary_structures, :school_id
      remove_index :employee_departments, :school_id
      remove_index :employee_categories, :school_id
      remove_index :individual_payslip_categories, :school_id
      remove_index :payroll_categories, :school_id
      remove_index :monthly_payslips, :school_id
      remove_index :employee_department_events, :school_id
      remove_index :bank_fields, :school_id
      remove_index :employees_subjects, :school_id
      remove_index :employee_attendances, :school_id
      remove_index :employee_additional_details, :school_id
      remove_index :student_previous_subject_marks, :school_id
      remove_index :exam_groups, :school_id
      remove_index :archived_exam_scores, :school_id
      remove_index :courses, :school_id
      remove_index :archived_guardians, :school_id
      remove_index :student_categories, :school_id
      remove_index :news_comments, :school_id
      remove_index :additional_fields, :school_id
      remove_index :subjects, :school_id
      remove_index :archived_employee_bank_details, :school_id
      remove_index :grading_levels, :school_id
      remove_index :batches, :school_id
      remove_index :archived_employees, :school_id
      remove_index :archived_students, :school_id
      remove_index :student_additional_details, :school_id
      remove_index :exams, :school_id
      remove_index :weekdays, :school_id
      remove_index :electives, :school_id
      remove_index :archived_employee_salary_structures, :school_id
      remove_index :configurations, :school_id
      remove_index :grouped_exams, :school_id
      remove_index :student_previous_datas, :school_id
      remove_index :batch_events, :school_id
      remove_index :period_entries, :school_id
      remove_index :guardians, :school_id
      remove_index :timetable_entries, :school_id
      remove_index :student_additional_fields, :school_id
      remove_index :events, :school_id
      remove_index :archived_employee_additional_details, :school_id
      remove_index :students, :school_id
      remove_index :finance_transaction_triggers, :school_id
      remove_index :finance_fee_categories, :school_id
      remove_index :liabilities, :school_id
      remove_index :news, :school_id
      remove_index :finance_transactions, :school_id
      remove_index :elective_groups, :school_id
      remove_index :fee_discounts, :school_id
      remove_index :finance_fee_collections, :school_id
      remove_index :fee_collection_particulars, :school_id
      remove_index :finance_fee_structure_elements, :school_id
      remove_index :finance_donations, :school_id
      remove_index :users, :school_id
      remove_index :assets, :school_id
      remove_index :user_events, :school_id
      remove_index :finance_fee_particulars, :school_id
      remove_index :sms_settings, :school_id
      remove_index :class_timings, :school_id
      remove_index :fee_collection_discounts, :school_id
      remove_index :reminders, :school_id
      remove_index :students_subjects, :school_id
      remove_index :finance_transaction_categories, :school_id
      remove_index :exam_scores, :school_id
      remove_index :finance_fees, :school_id
      remove_index :attendances, :school_id
      remove_index :employee_grades, :school_id
      remove_index :timetables, :school_id
      remove_index :subject_leaves, :school_id
      remove_index :sms_messages, :school_id
      remove_index :sms_logs, :school_id
      remove_index :batch_groups, :school_id
      remove_index :class_designations, :school_id
      remove_index :grouped_batches, :school_id
      remove_index :grouped_exam_reports, :school_id
      remove_index :previous_exam_scores, :school_id
      remove_index :ranking_levels, :school_id
      remove_index :assessment_scores, :school_id
      remove_index :cce_exam_categories, :school_id
      remove_index :cce_grades, :school_id
      remove_index :cce_grade_sets, :school_id
      remove_index :cce_reports, :school_id
      remove_index :cce_weightages, :school_id
      remove_index :descriptive_indicators, :school_id
      remove_index :fa_criterias, :school_id
      remove_index :fa_groups, :school_id
      remove_index :observation_groups, :school_id
      remove_index :observations, :school_id
      remove_index :cancelled_finance_transactions, :school_id
      remove_index :additional_field_options, :school_id
      remove_index :batch_students, :school_id
      remove_index :student_additional_field_options, :school_id
      remove_index :subject_amounts, :school_id
      remove_index :weekday_sets_weekdays, :school_id
      remove_index :weekday_sets, :school_id
      remove_index :time_table_weekdays, :school_id
      remove_index :time_table_class_timings, :school_id
      remove_index :class_timing_sets, :school_id
      remove_index :biometric_informations, :school_id
      remove_index :user_menu_links, :school_id
      remove_index :timetable_swaps, :school_id
      remove_index :fines, :school_id
      remove_index :fine_rules, :school_id
      remove_index :fee_refunds, :school_id
      remove_index :refund_rules, :school_id
      remove_index :collection_particulars, :school_id
      remove_index :collection_discounts, :school_id
      remove_index :fee_transactions, :school_id
      remove_index :fee_collection_batches, :school_id
      remove_index :category_batches, :school_id
      remove_index :additional_report_csvs, :school_id
      remove_index :redactor_uploads, :school_id
      remove_index :allocated_classrooms, :school_id
      remove_index :buildings, :school_id
      remove_index :classrooms, :school_id
      remove_index :classroom_allocations, :school_id
      remove_index :ia_calculations, :school_id
      remove_index :ia_groups, :school_id
      remove_index :ia_indicators, :school_id
      remove_index :ia_scores, :school_id
      remove_index :icse_exam_categories, :school_id
      remove_index :icse_reports, :school_id
      remove_index :icse_weightages, :school_id
      remove_index :remarks, :school_id
      remove_index :remark_parameters, :school_id
      remove_index :multi_fees_transactions, :school_id
      remove_index :particular_payments, :school_id
      remove_index :particular_discounts, :school_id
      remove_index :attendance_weekday_sets, :school_id
      remove_index :discount_particular_logs, :school_id
      remove_index :batch_class_timing_sets, :school_id
      remove_index :time_table_class_timing_sets, :school_id
      
      remove_column :employee_positions, :school_id
      remove_column :employee_leaves, :school_id
      remove_column :apply_leaves, :school_id
      remove_column :employee_leave_types, :school_id
      remove_column :employee_bank_details, :school_id
      remove_column :employees, :school_id
      remove_column :employee_salary_structures, :school_id
      remove_column :employee_departments, :school_id
      remove_column :employee_categories, :school_id
      remove_column :individual_payslip_categories, :school_id
      remove_column :payroll_categories, :school_id
      remove_column :monthly_payslips, :school_id
      remove_column :employee_department_events, :school_id
      remove_column :bank_fields, :school_id
      remove_column :employees_subjects, :school_id
      remove_column :employee_attendances, :school_id
      remove_column :employee_additional_details, :school_id
      remove_column :student_previous_subject_marks, :school_id
      remove_column :exam_groups, :school_id
      remove_column :archived_exam_scores, :school_id
      remove_column :courses, :school_id
      remove_column :archived_guardians, :school_id
      remove_column :student_categories, :school_id
      remove_column :news_comments, :school_id
      remove_column :additional_fields, :school_id
      remove_column :subjects, :school_id
      remove_column :archived_employee_bank_details, :school_id
      remove_column :grading_levels, :school_id
      remove_column :batches, :school_id
      remove_column :archived_employees, :school_id
      remove_column :archived_students, :school_id
      remove_column :student_additional_details, :school_id
      remove_column :exams, :school_id
      remove_column :weekdays, :school_id
      remove_column :electives, :school_id
      remove_column :archived_employee_salary_structures, :school_id
      remove_column :configurations, :school_id
      remove_column :grouped_exams, :school_id
      remove_column :student_previous_datas, :school_id
      remove_column :batch_events, :school_id
      remove_column :period_entries, :school_id
      remove_column :guardians, :school_id
      remove_column :timetable_entries, :school_id
      remove_column :student_additional_fields, :school_id
      remove_column :events, :school_id
      remove_column :archived_employee_additional_details, :school_id
      remove_column :students, :school_id
      remove_column :finance_transaction_triggers, :school_id
      remove_column :finance_fee_categories, :school_id
      remove_column :liabilities, :school_id
      remove_column :news, :school_id
      remove_column :finance_transactions, :school_id
      remove_column :elective_groups, :school_id
      remove_column :fee_discounts, :school_id
      remove_column :finance_fee_collections, :school_id
      remove_column :fee_collection_particulars, :school_id
      remove_column :finance_fee_structure_elements, :school_id
      remove_column :finance_donations, :school_id
      remove_column :users, :school_id
      remove_column :assets, :school_id
      remove_column :user_events, :school_id
      remove_column :finance_fee_particulars, :school_id
      remove_column :sms_settings, :school_id
      remove_column :class_timings, :school_id
      remove_column :fee_collection_discounts, :school_id
      remove_column :reminders, :school_id
      remove_column :students_subjects, :school_id
      remove_column :finance_transaction_categories, :school_id
      remove_column :exam_scores, :school_id
      remove_column :finance_fees, :school_id
      remove_column :attendances, :school_id
      remove_column :employee_grades, :school_id
      remove_column :timetables, :school_id
      remove_column :subject_leaves, :school_id
      remove_column :sms_messages, :school_id
      remove_column :sms_logs, :school_id
      remove_column :batch_groups, :school_id
      remove_column :class_designations, :school_id
      remove_column :grouped_batches, :school_id
      remove_column :grouped_exam_reports, :school_id
      remove_column :previous_exam_scores, :school_id
      remove_column :ranking_levels, :school_id
      remove_column :assessment_scores, :school_id
      remove_column :cce_exam_categories, :school_id
      remove_column :cce_grades, :school_id
      remove_column :cce_grade_sets, :school_id
      remove_column :cce_reports, :school_id
      remove_column :cce_weightages, :school_id
      remove_column :descriptive_indicators, :school_id
      remove_column :fa_criterias, :school_id
      remove_column :fa_groups, :school_id
      remove_column :observation_groups, :school_id
      remove_column :observations, :school_id
      remove_column :cancelled_finance_transactions, :school_id
      remove_column :additional_field_options, :school_id
      remove_column :batch_students, :school_id
      remove_column :student_additional_field_options, :school_id
      remove_column :subject_amounts, :school_id
      remove_column :weekday_sets_weekdays, :school_id
      remove_column :weekday_sets, :school_id
      remove_column :time_table_weekdays, :school_id
      remove_column :time_table_class_timings, :school_id
      remove_column :class_timing_sets, :school_id
      remove_column :biometric_informations, :school_id
      remove_column :user_menu_links, :school_id
      remove_column :timetable_swaps, :school_id
      remove_column :fines, :school_id
      remove_column :fine_rules, :school_id
      remove_column :fee_refunds, :school_id
      remove_column :refund_rules, :school_id
      remove_column :collection_particulars, :school_id
      remove_column :collection_discounts, :school_id
      remove_column :fee_transactions, :school_id
      remove_column :fee_collection_batches, :school_id
      remove_column :category_batches, :school_id
      remove_column :additional_report_csvs, :school_id
      remove_column :redactor_uploads, :school_id
      remove_column :allocated_classrooms, :school_id
      remove_column :buildings, :school_id
      remove_column :classrooms, :school_id
      remove_column :classroom_allocations, :school_id
      remove_column :ia_calculations, :school_id
      remove_column :ia_groups, :school_id
      remove_column :ia_indicators, :school_id
      remove_column :ia_scores, :school_id
      remove_column :icse_exam_categories, :school_id
      remove_column :icse_reports, :school_id
      remove_column :icse_weightages, :school_id
      remove_column :remarks, :school_id
      remove_column :remark_parameters, :school_id
      remove_column :multi_fees_transactions, :school_id
      remove_column :particular_payments, :school_id
      remove_column :particular_discounts, :school_id
      remove_column :attendance_weekday_sets, :school_id
      remove_column :discount_particular_logs, :school_id
      remove_column :batch_class_timing_sets, :school_id
      remove_column :time_table_class_timing_sets, :school_id
    end
end
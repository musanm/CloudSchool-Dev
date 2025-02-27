authorization do

  #open - privileges
  role :open do
    has_permission_on [:calendar],
      :to => [
      :index
    ]
    has_permission_on [:reminder],
      :to => [
      :index,
      :sent_reminder
    ]
  end

  #custom - privileges
  role :examination_control do
    includes :archived_exam_reports
    has_permission_on [:exam],
      :to => [
      :index,
      :previous_batch_exams,
      :course_wise_exams,
      :create_course_wise_exam_group,
      :update_exam_form_with_multibatch,
      :update_batch_in_course_wise_exams,
      :list_inactive_batches,
      :list_inactive_exam_groups,
      :previous_exam_marks,
      :edit_previous_marks,
      :update_previous_marks,
      :create_exam,
      :update_batch,
      :create_examtype,
      :create,:create_grading,
      :delete,
      :delete_examtype,
      :delete_grading,
      :edit,
      :edit_examtype,
      :edit_grading,
      :grading_form_edit,
      :rename_grading,
      :update_subjects_dropdown,
      :publish,
      :grouping,
      :update_exam_form,
      :exam_wise_report,
      :list_exam_types,
      :generated_report,
      :graph_for_generated_report,
      :generated_report_pdf,
      :consolidated_exam_report,
      :consolidated_exam_report_pdf,
      :subject_wise_report,
      :subject_rank,
      :course_rank,
      :batch_groups,
      :student_course_rank,
      :student_course_rank_pdf,
      :student_school_rank,
      :student_school_rank_pdf,
      :attendance_rank,
      :student_attendance_rank,
      :student_attendance_rank_pdf,
      :generate_reports,
      :generate_previous_reports,
      :select_inactive_batches,
      :settings,
      :report_center,
      :gpa_cwa_reports,
      :list_batch_groups,
      :ranking_level_report,
      :student_ranking_level_report,
      :student_ranking_level_report_pdf,
      :transcript,
      :student_transcript,
      :student_transcript_pdf,
      :combined_report,
      :load_levels,
      :student_combined_report,
      :student_combined_report_pdf,
      :load_batch_students,
      :select_mode,
      :select_batch_group,
      :select_type,
      :select_report_type,
      :batch_rank,
      :student_batch_rank,
      :student_batch_rank_pdf,
      :student_subject_rank,
      :student_subject_rank_pdf,
      :list_subjects,
      :list_batch_subjects,
      :generated_report2,
      :generated_report2_pdf,
      :grouped_exam_report,
      :final_report_type,
      :generated_report4,
      :generated_report4_pdf,
      :combined_grouped_exam_report_pdf,
      :student_wise_generated_report
    ]

    has_permission_on [:exam],
      :to => [
      :gpa_settings,
      :cgpa_average_example,
      :cgpa_credit_hours_example
    ]do
      if_attribute :gpa_enabled? => is {true}
    end

    has_permission_on [:scheduled_jobs],
      :to => [
      :index
    ]
    has_permission_on [:exam_groups],
      :to => [
      :index,
      :new,
      :create,
      :update,
      :destroy,
      :show,
      :edit,
      :set_exam_minimum_marks,
      :set_exam_maximum_marks,
      :set_exam_weightage,
      :set_exam_group_name,
      :set_exam_group_term_exam_id
    ]
    has_permission_on [:exams],
      :to => [
      :index,
      :show,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :save_scores,
      :query_data
    ]
    #    has_permission_on [:additional_exam],
    #      :to => [
    #      :index,
    #      :update_exam_form,
    #      :publish,
    #      :create_additional_exam,
    #      :update_batch
    #    ]

    #    has_permission_on [:additional_exam_groups],
    #      :to => [
    #      :index,
    #      :new,
    #      :create,
    #      :edit,
    #      :update,
    #      :destroy,
    #      :show,
    #      :initial_queries,
    #      :set_additional_exam_minimum_marks,
    #      :set_additional_exam_maximum_marks,
    #      :set_additional_exam_weightage,
    #      :set_additional_exam_group_name
    #    ]
    #    has_permission_on [:additional_exams],
    #      :to => [
    #      :index,
    #      :show,
    #      :new,
    #      :create,
    #      :edit,
    #      :update,
    #      :destroy,
    #      :save_additional_scores,
    #      :query_data
    #    ]
    has_permission_on [:grading_levels],
      :to => [
      :index,
      :show,
      :edit,
      :update,
      :new,
      :create,
      :destroy

    ]
    has_permission_on [:ranking_levels],
      :to => [
      :index,
      :load_ranking_levels,
      :create_ranking_level,
      :edit_ranking_level,
      :update_ranking_level,
      :delete_ranking_level,
      :ranking_level_cancel,
      :change_priority
    ]
    has_permission_on [:class_designations],
      :to => [
      :index,
      :load_class_designations,
      :create_class_designation,
      :edit_class_designation,
      :update_class_designation,
      :delete_class_designation
    ]
    has_permission_on [:descriptive_indicators],
      :to=>[
      :index,
      :show,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :reorder,
      :destroy_indicator,
      :show_in_report
    ]
    has_permission_on [:fa_criterias],
      :to=>[
      :index,
      :show
    ]
    has_permission_on [:fa_groups],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :show,
      :destroy,
      :assign_fa_groups,
      :select_subjects,
      :select_fa_groups,
      :update_subject_fa_groups,
      :new_fa_criteria,
      :create_fa_criteria,
      :edit_fa_criteria,
      :update_fa_criteria,
      :destroy_fa_criteria,
      :reorder,
      :edit_criteria_formula,
      :update_criteria_formula

    ]
    has_permission_on [:observation_groups],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :edit_observation,
      :update,
      :show,
      :destroy,
      :new_observation,
      :create_observation,
      :edit_osbervation,
      :update_observation,
      :destroy_observation,
      :assign_courses,
      :select_observation_groups,
      :update_course_obs_groups,
      :reorder,
      :reorder_ob_groups
    ]
    has_permission_on [:observations],
      :to=>[
      :show
    ]
    has_permission_on [:assessment_scores],
      :to=>[
      :exam_fa_groups,
      :fa_scores,
      :observation_groups,
      :observation_scores
    ]
    has_permission_on [:cce_exam_categories],
      :to=>[
      :index,
      :new,
      :create,
      :show,
      :edit,
      :update,
      :destroy
    ]
    has_permission_on [:cce_grade_sets],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :show,
      :index,
      :new_grade,
      :create_grade,
      :edit_grade,
      :update_grade,
      :destroy_grade
    ]
    has_permission_on [:cce_reports],
      :to=>[
      :index,
      :create_reports,
      :student_wise_report,
      :student_report_pdf,
      :student_transcript,
      :student_report,
      :assessment_wise_report,
      :list_batches,
      :generated_report,
      :generated_report_csv,
      :generated_report_pdf,
      :subject_wise_report,
      :subject_wise_batches,
      :list_subjects,
      :subject_wise_generated_report,
      :subject_wise_generated_report_csv,
      :subject_wise_generated_report_pdf
    ]
    has_permission_on [:cce_settings],
      :to=>[
      :index,
      :basic,
      :scholastic,
      :co_scholastic
    ]
    has_permission_on [:cce_weightages],
      :to=>[
      :index,
      :new,
      :create,
      :show,
      :edit,
      :update,
      :destroy,
      :assign_courses,
      :assign_weightages,
      :select_weightages,
      :update_course_weightages
    ]
    has_permission_on [:batches],:to=>[:batches_ajax]
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:report], :to => [:csv_reports,:csv_report_download]

    has_permission_on [:icse_settings],
      :to=>[
      :index,
      :icse_exam_categories,
      :new_icse_exam_category,
      :create_icse_exam_category,
      :edit_icse_exam_category,
      :update_icse_exam_category,
      :destroy_icse_exam_category,
      :icse_weightages,
      :new_icse_weightage,
      :create_icse_weightage,
      :edit_icse_weightage,
      :update_icse_weightage,
      :destroy_icse_weightage,
      :assign_icse_weightages,
      :select_subjects,
      :select_icse_weightages,
      :update_subject_weightages,
      :internal_assessment_groups,
      :new_ia_group,
      :create_ia_group,
      :edit_ia_group,
      :update_ia_group,
      :destroy_ia_group,
      :assign_ia_groups,
      :ia_group_subjects,
      :select_ia_groups,
      :update_subject_ia_groups
    ]do
      if_attribute :icse_enabled? => is {true}
    end
    has_permission_on [:ia_scores],
      :to=>[
      :ia_scores,
      :update_ia_score
    ]
    has_permission_on [:icse_reports],
      :to=> [
      :index,
      :generate_reports,
      :student_wise_report,
      :student_report,
      :student_report_pdf,
      :student_transcript,
      :subject_wise_report,
      :list_batches,
      :list_subjects,
      :list_exam_groups,
      :subject_wise_generated_report,
      :internal_and_external_mark_pdf,
      :detailed_internal_and_external_mark_pdf,
      :internal_and_external_mark_csv,
      :detailed_internal_and_external_mark_csv,
      :consolidated_report,
      :consolidated_generated_report,
      :consolidated_report_csv,
      :student_report_csv,
      :batches_ajax
    ]do
      if_attribute :icse_enabled? => is {true}
    end

  end

  role :enter_results  do
    includes :archived_exam_reports
    has_permission_on [:exam],
      :to => [
      :index,
      :previous_batch_exams,
      :list_inactive_batches,
      :list_inactive_exam_groups,
      :previous_exam_marks,
      :edit_previous_marks,
      :update_previous_marks,
      :create_exam,
      :update_batch,
      :exam_wise_report,
      :list_exam_types,
      :generated_report,
      :graph_for_generated_report,
      :generated_report_pdf,
      :consolidated_exam_report,
      :consolidated_exam_report_pdf,
      :subject_wise_report,
      :subject_rank,
      :course_rank,
      :batch_groups,
      :student_course_rank,
      :student_course_rank_pdf,
      :student_school_rank,
      :student_school_rank_pdf,
      :attendance_rank,
      :student_attendance_rank,
      :student_attendance_rank_pdf,
      :report_center,
      :gpa_cwa_reports,
      :list_batch_groups,
      :ranking_level_report,
      :student_ranking_level_report,
      :student_ranking_level_report_pdf,
      :transcript,
      :student_transcript,
      :student_transcript_pdf,
      :combined_report,
      :load_levels,
      :student_combined_report,
      :student_combined_report_pdf,
      :load_batch_students,
      :select_mode,
      :select_batch_group,
      :select_type,
      :select_report_type,
      :batch_rank,
      :student_batch_rank,
      :student_batch_rank_pdf,
      :student_subject_rank,
      :student_subject_rank_pdf,
      :list_subjects,
      :list_batch_subjects,
      :generated_report2,
      :generated_report2_pdf,
      :grouped_exam_report,
      :final_report_type,
      :generated_report4,
      :generated_report4_pdf,
      :combined_grouped_exam_report_pdf
    ]
    has_permission_on [:exam_groups],
      :to => [
      :index,
      :show,
      :set_exam_minimum_marks,
      :set_exam_maximum_marks,
      :set_exam_weightage,
      :set_exam_group_name,
      :set_exam_group_term_exam_id
    ]
    has_permission_on [:exams],
      :to => [
      :index,
      :show,
      :save_scores
    ]
    #    has_permission_on [:additional_exam],
    #      :to =>[
    #      :create_additional_exam,
    #      :update_batch,
    #      :publish
    #    ]
    #    has_permission_on [:additional_exam_groups],
    #      :to =>[
    #      :index,
    #      :show,
    #      :set_additional_exam_minimum_marks,
    #      :set_additional_exam_maximum_marks,
    #      :set_additional_exam_weightage,
    #      :set_additional_exam_group_name
    #    ]
    #    has_permission_on [:additional_exams],
    #      :to => [
    #      :index,
    #      :show,
    #      :save_additional_scores
    #    ]
    has_permission_on [:assessment_scores],
      :to=>[
      :exam_fa_groups,
      :fa_scores,
      :observation_groups,
      :observation_scores
    ]
    has_permission_on [:cce_reports],
      :to=>[
      :index,
      :student_wise_report,
      :student_report_pdf,
      :student_transcript,
      :student_report,
      :assessment_wise_report,
      :list_batches,
      :generated_report,
      :generated_report_csv,
      :generated_report_pdf,
      :subject_wise_report,
      :subject_wise_batches,
      :list_subjects,
      :subject_wise_generated_report,
      :subject_wise_generated_report_csv,
      :subject_wise_generated_report_pdf
    ]

    has_permission_on [:ia_scores],
      :to=>[
      :ia_scores,
      :update_ia_score
    ]
    has_permission_on [:icse_reports],
      :to=> [
      :index,
      :generate_reports,
      :student_wise_report,
      :student_report,
      :student_report_pdf,
      :student_transcript,
      :subject_wise_report,
      :list_batches,
      :list_subjects,
      :list_exam_groups,
      :subject_wise_generated_report,
      :internal_and_external_mark_pdf,
      :detailed_internal_and_external_mark_pdf,
      :internal_and_external_mark_csv,
      :detailed_internal_and_external_mark_csv,
      :consolidated_report,
      :consolidated_generated_report,
      :consolidated_report_csv,
      :student_report_csv,
      :batches_ajax
    ]do
      if_attribute :icse_enabled? => is {true}
    end
    has_permission_on [:scheduled_jobs],
      :to=>[
      :index
    ]

  end

  role :view_results  do
    includes :archived_exam_reports
    has_permission_on [:student], :to => [:reports]
    has_permission_on [:exam], :to => [:index,
      :exam_wise_report,
      :list_exam_types,
      :generated_report,
      :graph_for_generated_report,
      :generated_report_pdf,
      :consolidated_exam_report,
      :consolidated_exam_report_pdf,
      :subject_wise_report,
      :subject_rank,
      :course_rank,
      :batch_groups,
      :student_course_rank,
      :student_course_rank_pdf,
      :student_school_rank,
      :student_school_rank_pdf,
      :attendance_rank,
      :student_attendance_rank,
      :student_attendance_rank_pdf,
      :report_center,
      :gpa_cwa_reports,
      :list_batch_groups,
      :ranking_level_report,
      :student_ranking_level_report,
      :student_ranking_level_report_pdf,
      :transcript,
      :student_transcript,
      :student_transcript_pdf,
      :combined_report,
      :load_levels,
      :student_combined_report,
      :student_combined_report_pdf,
      :load_batch_students,
      :select_mode,
      :select_batch_group,
      :select_type,
      :select_report_type,
      :batch_rank,
      :student_batch_rank,
      :student_batch_rank_pdf,
      :student_subject_rank,
      :student_subject_rank_pdf,
      :list_subjects,
      :list_batch_subjects,
      :generated_report2,
      :generated_report2_pdf,
      :grouped_exam_report,
      :final_report_type,
      :generated_report4,
      :generated_report4_pdf,
      :combined_grouped_exam_report_pdf
    ]
    has_permission_on [:cce_reports],
      :to=>[
      :index,
      :student_wise_report,
      :student_report_pdf,
      :student_transcript,
      :student_report,
      :assessment_wise_report,
      :list_batches,
      :generated_report,
      :generated_report_csv,
      :generated_report_pdf,
      :subject_wise_report,
      :subject_wise_batches,
      :list_subjects,
      :subject_wise_generated_report,
      :subject_wise_generated_report_csv,
      :subject_wise_generated_report_pdf
    ]
    has_permission_on [:icse_reports],
      :to=> [
      :index,
      :student_wise_report,
      :student_report,
      :student_report_pdf,
      :student_transcript,
      :subject_wise_report,
      :list_batches,
      :list_subjects,
      :list_exam_groups,
      :subject_wise_generated_report,
      :internal_and_external_mark_pdf,
      :detailed_internal_and_external_mark_pdf,
      :internal_and_external_mark_csv,
      :detailed_internal_and_external_mark_csv,
      :consolidated_report,
      :consolidated_generated_report,
      :consolidated_report_csv,
      :student_report_csv,
    ]do
      if_attribute :icse_enabled? => is {true}
    end
  end

  role :admission do
    has_permission_on [:student],
      :to => [
      :profile,
      :admission1,
      :render_batch_list,
      :set_roll_number_prefix,
      :admission1_2,
      :search_ajax,
      :admission2,
      :admission3,
      :previous_data,
      :delete_previous_subject,
      :previous_data_from_profile,
      :previous_data_edit,
      :previous_subject,
      :save_previous_subject,
      :admission4,
      :profile,
      :add_guardian,
      :admission3_1,
      :edit,
      :fees,
      :edit_guardian,
      :guardians,
      :del_guardian,
      :list_students_by_course,
      :show,
      :view_all,
      :profile_pdf,
      :edit,
      :show_previous_details,
      :remove,
      :change_to_former,
      :delete,
      :generate_tc_pdf,
      :generate_new_tc_pdf,
      :edit_admission4,
      :fee_details,
      :destroy,
      :activities,
      :update_activities,
      :destroy_dependencies,
      :student_fees_preference
    ]

    has_permission_on [:scheduled_jobs],
      :to => [
      :index
    ]
    has_permission_on [:archived_student], :to=>[:edit_leaving_date]
    has_permission_on [:remarks], :to => [:custom_remark_list,:remarks_history,:list_custom_remarks]
  end

  role :students_control do
    has_permission_on [:student] ,
      :to => [
      :academic_reports_pdf,
      :academic_report,
      :academic_report_all,
      :profile,
      :guardians,
      :list_students_by_course,
      :show,
      :view_all,
      :index,
      :change_to_former,
      :delete,:destroy,
      :email,
      :exam_report,
      :update_student_result_for_examtype,
      :previous_years_marks_overview,
      :previous_years_marks_overview_pdf,
      :remove,:reports,
      :search_ajax,
      :subject_wise_report,
      :graph_for_previous_years_marks_overview,
      :graph_for_student_annual_overview,
      :graph_for_subject_wise_report_for_one_subject,
      :graph_for_exam_report,
      :graph_for_academic_report,
      :generate_tc_pdf,
      :generate_new_tc_pdf,
      :generate_all_tc_pdf,
      :advanced_search,
      :advanced_search_pdf,
      :edit,
      :previous_data_edit,
      :profile_pdf,
      :edit_guardian,
      :del_guardian,
      :add_guardian,
      :show_previous_details,
      :list_doa_year,
      :doa_equal_to_update,
      :doa_less_than_update,
      :doa_greater_than_update,
      :list_dob_year,
      :dob_equal_to_update,
      :dob_less_than_update,
      :dob_greater_than_update,
      :list_batches,
      :find_student,
      :fees,
      :fee_details,
      :admission3_1,
      :admission3_2,
      :immediate_contact2,
      :admission1_2,
      :my_subjects,
      :choose_elective,
      :remove_elective,
      :admission1,
      :render_batch_list,
      :set_roll_number_prefix,
      :admission2,
      :admission3,
      :previous_data,
      :previous_data_from_profile,
      :previous_subject,
      :save_previous_subject,
      :delete_previous_subject,
      :admission4,
      :edit_admission4,
      :activities,
      :update_activities,
      :destroy_dependencies,
      :student_fees_preference
    ]

    has_permission_on [:scheduled_jobs],
      :to => [
      :index
    ]
    has_permission_on [:finance], :to => [:refund_student_view,:refund_student_view_pdf]
    has_permission_on [:archived_student],
      :to => [
      :profile,
      :reports,
      :guardians,
      :delete,
      :destroy,
      :generate_tc_pdf,
      :generate_new_tc_pdf,
      :consolidated_exam_report,
      :consolidated_exam_report_pdf,
      :academic_report,
      :student_report,
      :generated_report,
      :generated_report_pdf,
      :generated_report3,
      :previous_years_marks_overview,
      :previous_years_marks_overview_pdf,
      :generated_report4,
      :generated_report4_pdf,
      :graph_for_generated_report,
      :graph_for_generated_report3,
      :graph_for_previous_years_marks_overview,
      :edit_leaving_date,
      :revert_archived_student
    ]
    has_permission_on [:exam],
      :to =>[
      :generated_report,
      :generated_report_pdf,
      :consolidated_exam_report,
      :consolidated_exam_report_pdf,
      :generated_report3,
      :generated_report3_pdf,
      :generated_report4,
      :generated_report4_pdf,
      :combined_grouped_exam_report_pdf,
      :graph_for_generated_report,
      :graph_for_generated_report3,
      :previous_years_marks_overview,
      :previous_years_marks_overview_pdf,
      :academic_report,
      :graph_for_previous_years_marks_overview,
      :student_wise_generated_report,
      :student_transcript,
      :student_transcript_pdf
    ]
    has_permission_on [:student_attendance],
      :to =>[
      :student,
      :month,
      :student_report
    ]
    has_permission_on [:cce_reports], :to => [:student_transcript,:student_report_pdf]
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:report], :to => [:csv_reports,:csv_report_download]
    has_permission_on [:remarks], :to => [:add_employee_custom_remarks,:list_batches,:list_student_with_remark_subject,:employee_custom_remark_update,:employee_list_custom_remarks,:list_specific_batches,:list_students,:list_student_custom_remarks,:add_custom_remarks,:create_custom_remarks,:edit_custom_remarks,:update_custom_remarks,:destroy_custom_remarks,:custom_remark_list,:remarks_history,:list_custom_remarks,:index]
    has_permission_on [:icse_reports],
      :to=> [
      :student_report_pdf,
      :student_transcript,
      :student_report_csv,
    ]do
      if_attribute :icse_enabled? => is {true}
    end
  end

  role :student_view do
    has_permission_on [:student] ,
      :to => [
      :academic_reports_pdf,
      :academic_report,
      :academic_report_all,
      :profile,
      :guardians,
      :list_students_by_course,
      :show,
      :view_all,
      :index,
      :email,
      :exam_report,
      :previous_years_marks_overview,
      :previous_years_marks_overview_pdf,
      :search_ajax,
      :subject_wise_report,
      :graph_for_previous_years_marks_overview,
      :graph_for_student_annual_overview,
      :graph_for_subject_wise_report_for_one_subject,
      :graph_for_exam_report,
      :graph_for_academic_report,
      :advanced_search,
      :advanced_search_pdf,
      :profile_pdf,
      :show_previous_details,
      :list_doa_year,
      :doa_equal_to_update,
      :doa_less_than_update,
      :doa_greater_than_update,
      :list_dob_year,
      :dob_equal_to_update,
      :dob_less_than_update,
      :dob_greater_than_update,
      :list_batches,
      :find_student,
      :fees,
      :fee_details,
      :admission3_2,
      :immediate_contact2,
      :generate_tc_pdf,
      :generate_new_tc_pdf,
      :generate_all_tc_pdf,
      :my_subjects,
      :reports,
      :activities,
      :update_activities,
      :student_fees_preference
    ]
    has_permission_on [:remarks], :to => [:custom_remark_list,:remarks_history,:list_custom_remarks]
    has_permission_on [:finance], :to => [:refund_student_view,:refund_student_view_pdf]
    has_permission_on [:archived_student],
      :to => [
      :profile,
      :reports,
      :guardians,
      :generate_tc_pdf,
      :generate_new_tc_pdf,
      :consolidated_exam_report,
      :consolidated_exam_report_pdf,
      :academic_report,
      :student_report,
      :generated_report,
      :generated_report_pdf,
      :generated_report3,
      :previous_years_marks_overview,
      :previous_years_marks_overview_pdf,
      :generated_report4,
      :generated_report4_pdf,
      :graph_for_generated_report,
      :graph_for_generated_report3,
      :graph_for_previous_years_marks_overview
    ]
    has_permission_on [:exam],
      :to =>[
      :generated_report,
      :generated_report_pdf,
      :consolidated_exam_report,
      :consolidated_exam_report_pdf,
      :generated_report3,
      :generated_report3_pdf,
      :generated_report4,
      :generated_report4_pdf,
      :combined_grouped_exam_report_pdf,
      :graph_for_generated_report,
      :graph_for_generated_report3,
      :previous_years_marks_overview,
      :previous_years_marks_overview_pdf,
      :academic_report,
      :graph_for_previous_years_marks_overview,
      :student_transcript,
      :student_transcript_pdf
    ]
    has_permission_on [:student_attendance],
      :to =>[
      :student,
      :month,
      :student_report
    ]
    has_permission_on [:cce_reports], :to => [:student_transcript,:student_report_pdf]
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:report], :to => [:csv_reports,:csv_report_download]
    has_permission_on [:icse_reports],
      :to=> [
      :student_report_pdf,
      :student_transcript,
      :student_report_csv,
    ]do
      if_attribute :icse_enabled? => is {true}
    end
  end

  role :manage_news do
    has_permission_on [:news],
      :to => [
      :index,
      :add,
      :add_comment,
      :all,
      :delete,
      :delete_comment,
      :comment_approved,
      :edit,
      :search_news_ajax,
      :view,
      :comment_view]
  end

  role :manage_timetable do
    includes :timetable_track
    includes :classroom_allocation
    has_permission_on [:class_timing_sets], :to => [
      :index,
      :new,
      :create,
      :edit,
      :update,
      :show,
      :destroy,
      :new_class_timings,
      :create_class_timings,
      :edit_class_timings,
      :update_class_timings,
      :delete_class_timings,
      :new_batch_class_timing_set,
      :list_batches,
      :add_batch,
      :remove_batch
    ]
    has_permission_on [:class_timings], :to => [:index, :edit, :destroy, :show, :new, :create, :update]
    has_permission_on [:weekday], :to => [:index, :week, :create,:get_class_timing_sets,:get_class_timing_set_for_edit,:list_batches]
    has_permission_on [:timetable],
      :to => [:index,
      :new_timetable,
      :update_timetable,
      :manage_timetable,
      :add_batch_timetable,
      :remove_batch_timetable,
      :view,
      :edit_master,
      :teachers_timetable,
      :update_teacher_tt,
      :update_timetable_view,
      :timetable_view_batches,
      :destroy,
      :employee_timetable,
      :update_employee_tt,
      :student_view,
      :update_student_tt,
      :weekdays,
      :timetable,
      :timetable_pdf,
      :work_allotment
    ]
    has_permission_on [:timetable_entries],
      :to => [
      :new,
      :select_batch,
      :new_entry,
      :update_employees,
      :delete_employee2,
      :update_multiple_timetable_entries2,
      :tt_entry_update2,
      :tt_entry_noupdate2
    ]
    #    has_permission_on [:timetable],
    #      :to => [
    #      :index,
    #      :edit,
    #      :delete_subject,
    #      :select_class,
    #      :tt_entry_update,
    #      :tt_entry_noupdate,
    #      :update_multiple_timetable_entries,
    #      :update_timetable_view,
    #      :generate,
    #      :extra_class,
    #      :extra_class_edit,
    #      :list_employee_by_subject,
    #      :save_extra_class,
    #      :timetable,
    #      :weekdays,
    #      :view,
    #      :select_class2,
    #      :edit2,
    #      :update_employees,
    #      :update_multiple_timetable_entries2,
    #      :delete_employee2,
    #      :tt_entry_update2,
    #      :tt_entry_noupdate2,
    #      :timetable_pdf
    #    ]
  end
  role :manage_roll_number do
    has_permission_on [:student_roll_number], :to => [
      :index,
      :edit_sort_order_warning,
      :edit_sort_order,
      :update_sort_order,
      :edit_course_prefix,
      :update_course_prefix,
      :set_course_prefix,
      :create_course_prefix,
      :view_batches,
      :set_roll_numbers,
      :create_roll_numbers,
      :update_roll_numbers,
      :edit_roll_numbers,
      :edit_batch_prefix,
      :update_batch_prefix,
      :reset_batch_to_course_prefix,
      :create_roll_numbers,
      :update_roll_numbers,
      :reset_all_roll_numbers,
      :regenerate_all_roll_numbers,
      :update_roll_numbers_to_null,
      :save_changes_warning] do
      if_attribute :roll_number_enabled? => is {true}
    end
  end

  role :manage_building_and_allocation do
    has_permission_on [:classroom_allocations], :to => [:index,
      :new,
      :view,
      :weekly_allocation,
      :date_specific_allocation,
      :render_classrooms,
      :delete_allocation,
      :find_allocations,
      :display_rooms,
      :update_allocation_entries,
      :override_allocations
    ]
    has_permission_on [:buildings], :to => [:index,
      :show,
      :update,
      :edit,
      :create,
      :new,
      :destroy
    ]
    has_permission_on [:classrooms], :to => [
      :index,
      :show,
      :update,
      :edit,
      :create,
      :new,
      :destroy,
      :list_weekly_activities,
      :list_date_specific_activities,
      :year
    ]

  end

  role :classroom_allocation do
    has_permission_on [:classroom_allocations], :to => [:index,
      :new,
      :view,
      :weekly_allocation,
      :date_specific_allocation,
      :render_classrooms,
      :delete_allocation,
      :find_allocations,
      :display_rooms,
      :update_allocation_entries,
      :override_allocations
    ]
  end

  role :manage_building do
    has_permission_on [:buildings], :to => [:index,
      :show,
      :update,
      :edit,
      :create,
      :new,
      :destroy
    ]
    has_permission_on [:classrooms], :to => [
      :index,
      :show,
      :update,
      :edit,
      :create,
      :new,
      :destroy,
      :list_weekly_activities,
      :list_date_specific_activities,
      :year
    ]
    has_permission_on [:classroom_allocations], :to => [:index]
  end

  role :timetable_view do
    has_permission_on [:timetable], :to => [:index,
      :update_timetable,
      :manage_timetable,
      :add_batch_timetable,
      :remove_batch_timetable,
      :view,
      :teachers_timetable,
      :update_teacher_tt,
      :update_timetable_view,
      :timetable_view_batches,
      :employee_timetable,
      :update_employee_tt,
      :student_view,
      :update_student_tt,
      :timetable,
      :timetable_pdf
    ]
    has_permission_on [:timetable_tracker], :to => [:index,
      :swaped_timetable_report,
      :swaped_timetable_report_csv,
      :employee_report_details
    ]
    #    has_permission_on [:timetable], :to => [:index,:select_class,:view, :update_timetable_view, :timetable_pdf, :timetable]
  end

  role :student_attendance_view do
    has_permission_on [:attendance], :to => [:index,:report,:student_report]
    has_permission_on [:attendance_reports], :to => [:index, :subject, :mode, :show, :year, :report, :filter, :student_details,:report_pdf,:filter_report_pdf]
    has_permission_on [:student_attendance], :to => [:index, :student]
    has_permission_on [:attendance_reports], :to => [:day_wise_report,:day_wise_report_filter_by_course,:in_out_attendance,:get_in_out_attendance_report, :get_in_out_attendance_pdf_report, :employee_in_out_attendance, :get_employee_in_out_attendance_report, :individual_employee_in_out_attendance, :individual_employee_in_out_attendance_pdf, :employee_in_out_attendance_pdf_report,:daily_report_batch_wise]do
      if_attribute :can_view_day_wise_report? => is {true}
    end
  end

  role :student_attendance_register do
    has_permission_on [:attendance], :to => [:index,:register,:register_attendance]
    has_permission_on [:attendances], :to => [:index, :list_subject, :show, :new, :create, :edit,:update, :destroy,:subject_wise_register,:daily_register,:quick_attendance]
    has_permission_on [:student_attendance], :to => [:index]
    has_permission_on [:attendance_reports], :to => [:index, :subject, :mode, :show, :year, :report, :filter, :student_details,:report_pdf,:filter_report_pdf] do
      if_attribute :has_required_controls? => is {true}
    end
  end

  role :manage_course_batch do
    has_permission_on [:configuration], :to => [:index]
    has_permission_on [:courses], :to => [:index,:manage_course, :manage_batches,:inactivate_batch,:activate_batch,:find_course, :new, :create,:destroy,:edit,:update, :show, :update_batch,:grouped_batches,:create_batch_group,:edit_batch_group,:update_batch_group,:delete_batch_group,:assign_subject_amount,:edit_subject_amount,:destroy_subject_amount]
    has_permission_on [:batches], :to => [:index, :new, :create,:destroy,:edit,:update, :show, :init_data,:assign_tutor,:update_employees,:assign_employee,:remove_employee,:batches_ajax,:batch_summary,:list_batches,:tab_menu_items,:get_tutors,:get_batch_span]
    has_permission_on [:subjects], :to => [:set_elective_group_name,:index, :new, :create,:destroy,:edit,:update, :show,:destroy_elective_group]
    has_permission_on [:elective_groups],  :to => [:index,:new,:create,:destroy,:edit, :update,:show,:new_elective_subject,:create_elective_subject, :edit_elective_subject, :update_elective_subject]
    has_permission_on [:student], :to => [:electives,:assigned_elective_subjects,:search_students,:assign_students,:unassign_students,:choose_elective, :remove_elective, :assign_all_students, :unassign_all_students, :profile, :guardians, :show_previous_details]
    has_permission_on [:batch_transfers],
      :to => [
      :index,
      :show,
      :transfer,
      :graduation,
      :subject_transfer,
      :get_previous_batch_subjects,
      :update_batch,
      :assign_previous_batch_subject,
      :assign_all_previous_batch_subjects,
      :new_subject,
      :create_subject
    ]
    has_permission_on [:revert_batch_transfers], :to => [:index,:list_students,:revert_transfer]
  end

  role :subject_master do
    has_permission_on [:configuration], :to => [:index]
    has_permission_on [:student], :to => [:electives,:assigned_elective_subjects,:search_students, :assign_students, :unassign_students, :assign_all_students, :unassign_all_students]
    has_permission_on [:subjects],        :to => [:set_elective_group_name,:index,:new,:create,:destroy,:edit, :update,:show,:destroy_elective_group]
    has_permission_on [:elective_groups],  :to => [:index,:new,:create,:destroy,:edit, :update,:show,:new_elective_subject,:create_elective_subject, :edit_elective_subject, :update_elective_subject]
  end

  role :academic_year do
    has_permission_on [:configuration], :to => [:index]
    has_permission_on [:academic_year],
      :to => [
      :index,
      :add_course,
      :migrate_classes,
      :migrate_students,
      :list_students,
      :update_courses,
      :upcoming_exams ]
  end
  role :sms_management do
    has_permission_on [:configuration], :to => [:index]
    has_permission_on [:sms], :to => [:index, :settings, :students, :batches, :employees, :departments,:all, :update_general_sms_settings, :list_students, :sms_all, :list_employees, :show_sms_messages, :show_sms_logs]
  end
  role :event_management do

    has_permission_on [:event], :to => [:index, :show, :confirm_event, :cancel_event, :select_course, :event_group, :course_event, :remove_batch, :select_employee_department, :department_event, :remove_department,:edit_event]
    has_permission_on [:calendar], :to => [:event_delete]
  end

  role :general_settings do
    has_permission_on [:configuration], :to => [:index,:settings,:permissions]
    has_permission_on [:single_access_tokens], :to => [:index,:new,:create,:destroy]
    has_permission_on [:student], :to => [:add_additional_details, :change_field_priority, :delete_additional_details, :edit_additional_details, :categories,:category_delete,:category_edit,:category_update ]
  end

  role :manage_fee do
    has_permission_on [:bank_details],
      :to => [
        :index
      ]
    has_permission_on [:finance],
      :to => [
      :index,
      :fees_index,
      :fee_collection,
      :fee_collection_create,
      :fee_collection_delete,
      :fee_collection_edit,
      :fee_collection_update,
      :fees_structure_dates,
      :fee_collection_view,
      :fee_collection_dates_batch,
      :show_master_categories_list,
      :master_fees,
      :fees_particulars,
      :fee_collection_batch_update,
      :fees_student_structure_search,
      :fees_student_structure_search_logic,
      :fee_structure_dates,
      :fees_structure_for_student,
      :master_category_create,
      :master_category_new,
      :fees_particulars_new,
      :fees_particulars_new2,
      :fees_particulars_create,
      :fees_particulars_create2,
      :fee_collection_new,
      :fee_collection_create,
      :fee_discounts,
      :fee_discount_new,
      :load_discount_create_form,
      :load_discount_batch,
      :load_batch_fee_category,
      :batch_wise_discount_create,
      :category_wise_fee_discount_create,
      :student_wise_fee_discount_create,
      :update_master_fee_category_list,
      :show_fee_discounts,
      :edit_fee_discount,
      :update_fee_discount,
      :delete_fee_discount,
      :collection_details_view,
      :master_category_edit,
      :master_category_update,
      :master_category_delete,
      :master_category_particulars,
      :master_category_particulars_edit,
      :master_category_particulars_update,
      :master_category_particulars_delete,
      :pdf_fee_structure,
      :generate_fine,
      :new_fine,
      :fine_list,
      :add_fine_slab,
      :fine_slabs_edit_or_create,
      :list_category_batch,
      :particular_discount_applicable_students,
      :particular_discount_applicable_students,
      :index

    ]


    has_permission_on [:scheduled_jobs],
      :to=>[
      :index
    ]
    has_permission_on [:finance_extensions],
      :to=>[
      :discount_particular_allocation,
      :show_discounts,
      :show_particulars,
      :batch_discounts,
      :fee_collections_for_batch,
      :particulars_with_tabs,
      :update_collection_discount,
      :update_collection_particular
    ]
  end

  role :fee_submission do
    has_permission_on [:finance],
      :to=>[
      :index,
      :fees_index,
      :search_logic,
      :fees_defaulters,
      :fees_submission_batch,
      :update_fees_collection_dates,
      :load_fees_submission_batch,
      :update_ajax,
      :update_batches,
      :update_fees_collection_dates_defaulters,
      :fees_defaulters_students,
      :fees_student_dates,
      :pay_fees_defaulters,
      :fees_submission_save,
      :fees_submission_student,
      :fee_particulars_update,
      :student_or_student_category,
      :update_fine_ajax,
      :student_fee_receipt_pdf,
      :new_student_fee_receipt_pdf,
      :student_fee_invoice_receipt_pdf,
      :new_batch_fee_receipt_pdf,
      :batch_fee_receipt_horizontal_pdf,
      :update_student_fine_ajax,
      :update_defaulters_fine_ajax,
      :fee_defaulters_pdf,
      :select_payment_mode,
      :student_wise_fee_payment,
      :fees_submission_index,
      :fees_student_search,
      :fees_received,
      :load_particular_fee_categories,
      :load_fee_category_particulars,
      :particular_wise_fee_discount_create,
      :particular_discount_applicable_students,
      :fee_collection_batch_update_for_fee_collection
    ]



    has_permission_on [:finance_extensions],:to=>[
      :pay_all_fees,
      :pay_all_fees_receipt_pdf,
      :pay_fees_in_particular_wise,
      :particular_wise_fee_payment,
      :particular_wise_fee_pay_pdf,
      :create_instant_particular,
      :new_instant_particular,
      :delete_student_particular,
      :new_instant_discount,
      :create_instant_discount,
      :delete_student_discount
    ]

  end

  role :approve_reject_payslip do
    has_permission_on [:finance],
      :to=>[
      :index,
      :approve_monthly_payslip,
      :one_click_approve_submit,
      :one_click_approve,
      :employee_payslip_approve,
      :employee_payslip_reject,
      :employee_payslip_accept_form,
      :employee_payslip_reject_form,
      :view_monthly_payslip,
      :view_monthly_payslip_pdf,
      :search_ajax,
      :view_employee_payslip,
      :payslip_index,
    ]
    has_permission_on [:employee], :to => [:employee_individual_payslip_pdf]
    has_permission_on [:csv_export], :to => [:generate_csv]

  end

  role :finance_reports do
    has_permission_on [:finance],
      :to=>[
      :index,
      :fees_index,
      :monthly_report,
      :update_monthly_report,
      :salary_department,
      :salary_employee,
      :employee_payslip_monthly_report,
      :donations_report,
      :fees_report,
      :batch_fees_report,
      :month_date,
      :compare_report,
      :fee_report,
      :finance_fee_report_pdf,
      :report_compare,
      :graph_for_compare_monthly_report,
      :transaction_pdf,
      :graph_for_update_monthly_report,
      :finance_reports,
      :income_details,
      :income_details_pdf
    ]


    has_permission_on [:report],
      :to=>[
      :index,
      :search_student,
      :search_ajax,
      :student_fees_headwise_report,
      :fees_head_wise_report,
      :batch_fees_headwise_report,
      :batch_head_wise_fees_csv,
      :fee_collection_head_wise_report,
      :update_fees_collections,
      :fee_collection_head_wise_report_csv,
      :csv_reports,
      :batch_list,
      :csv_report_download,
      :student_wise_fee_defaulters,
      :student_wise_fee_defaulters_csv,
      :course_fee_defaulters,
      :course_fee_defaulters_csv,
      :fee_collection_details,
      :fee_collection_details_csv,
      :batch_list,
      :batch_students,
      :batch_students_csv,
      :batch_fee_defaulters,
      :batch_fee_defaulters_csv,
      :batch_fee_collections,
      :batch_fee_collections_csv,
      :students_fee_defaulters,
      :students_fee_defaulters_csv,
      :batch_details,
      :student_wise_fee_collections,
      :student_wise_fee_collections_csv


    ]
  end

  role :revert_transaction do
    has_permission_on [:finance],
      :to=>[
      :index,
      :delete_transaction_for_student,
      :delete_transaction_by_batch,
      :transaction_deletion,
      :delete_transaction_fees_defaulters,
      :deleted_transactions,
      :update_deleted_transactions,
      :list_deleted_transactions,
      :search_fee_collection,
      :transaction_filter_by_date,
      :transactions_advanced_search,
      :delete_transaction,
      :delete_transaction_for_particular_wise_fee_pay,
      :transactions,
      :revert_fee_refund
    ]

    has_permission_on [:finance_extensions],
      :to=>[
      :delete_multi_fees_transaction
    ]
    includes :fee_submission
  end

  role :miscellaneous do
    has_permission_on [:finance],
      :to=>[
      :index,
      :categories,
      :donation,
      :donation_receipt,
      :expense_create,
      :income_create,
      :category_create,
      :category_delete,
      :category_edit,
      :category_update,
      :asset_liability,
      :liability,
      :create_liability,
      :view_liability,
      :each_liability_view,
      :asset,
      :create_asset,
      :view_asset,
      :each_asset_view,
      :edit_liability,
      :update_liability,
      :delete_liability,
      :edit_asset,
      :update_asset,
      :delete_asset,
      :categories_new,
      :categories_create,
      :donation_receipt_pdf,
      :donations,
      :donors_list,
      :donors_list_pdf,
      :expense_list,
      :expense_list_update,
      :income_list,
      :income_list_update,
      :donation_edit,
      :donation_delete,
      :income_list_pdf,
      :expense_list_pdf,
      :asset_pdf,
      :liability_pdf,
      :transactions,
      :asset_liability,
      :delete_transaction,
      :income_details,
      :income_details_pdf,
      :add_additional_details_for_donation,
      :edit_additional_details_for_donation,
      :delete_additional_details_for_donation,
      :change_field_priority_for_donation,
      :bank_details
    ]
    has_permission_on [:scheduled_jobs],
      :to=>[
      :index
    ]
    has_permission_on [:report],
      :to=>[
      :donation_list_csv
    ]

  end

  role :manage_refunds do
    has_permission_on [:finance],
      :to=>[
      :index,
      :fees_index,
      :fees_refund,
      :create_refund,
      :new_refund,
      :apply_refund,
      :refund_student_search,
      :fees_refund_dates,
      :fees_refund_student,
      :view_refunds,
      :refund_filter_by_date,
      :search_fee_refunds,
      :list_refunds,
      :fee_refund_student_pdf,
      :refund_search_pdf,
      :refund_student_view,
      :refund_student_view_pdf,
      :view_refund_rules,
      :list_refund_rules,
      :edit_refund_rules,
      :refund_rule_update,
      :refund_rule_delete,
      :revert_fee_refund
    ]
  end



  role :payroll_management do
    has_permission_on [:payroll],
      :to => [
      :index,
      :add_category,
      :edit_category,
      :delete_category,
      :activate_category,
      :inactivate_category,
      :manage_payroll,
      :update_dependent_fields,
      :update_dependent_payslip_fields,
      :edit_payroll_details
    ]
  end
  role :finance_control do

    includes :manage_fee
    includes :fee_submission
    includes :approve_reject_payslip
    includes :finance_reports
    includes :manage_refunds
    includes :payroll_management
    includes :miscellaneous
    includes :revert_transaction

    has_permission_on [:xml],
      :to => [
      :create_xml,
      :index,
      :settings,
      :download
    ]


  end

  role :hr_basics do
    has_permission_on [:archived_employee],
      :to => [
      :profile,
      :profile_general,
      :profile_personal,
      :profile_address,
      :profile_contact,
      :profile_bank_details,
      :profile_additional_details,
      :profile_payroll_details,
      :profile_pdf,
      :show
    ]
    has_permission_on [:employee],
      :to => [
      :index,
      :add_category,
      :edit_category,
      :delete_category,
      :add_position,
      :edit_position,
      :delete_position,
      :add_department,
      :edit_department,
      :delete_department,
      :add_grade,
      :edit_grade,
      :delete_grade,
      :remove,
      :remove_subordinate_employee,
      :change_to_former,
      :delete,
      :admission1,
      :update_positions,
      :edit1,
      :edit_personal,
      :admission2,
      :edit2,
      :edit_contact,
      :admission3,
      :edit3,
      :admission3_1,
      :admission3_2,
      :edit3_1,
      :admission4,
      :change_reporting_manager,
      :reporting_manager_search,
      :update_reporting_manager_name,
      :edit4,
      :search,
      :search_ajax,
      :select_reporting_manager,
      :profile,
      :profile_general,
      :profile_personal,
      :profile_address,
      :profile_contact,
      :profile_bank_details,
      :profile_payroll_details,
      :view_all,
      :show,
      :subject_assignment,
      :update_subjects,
      :select_department,
      :update_employees,
      :assign_employee,
      :remove_employee,
      :hr,
      :select_department_employee,
      :settings,
      :employee_management,
      :add_bank_details,
      :edit_bank_details,
      :add_additional_details,
      :change_field_priority,
      :edit_additional_details,
      :delete_bank_details,
      :delete_additional_details,
      :edit_privilege,
      :employees_list,
      :profile_pdf,
      :leave_management,
      :update_employees_select,
      :leave_list,
      :advanced_search,
      :advanced_search_pdf,
      :update_activities,
      :activities
    ]
    has_permission_on [:payroll] ,
      :to => [
      :add_category,
      :edit_category,
      :manage_payroll,
      :activate_category,
      :delete_category,
      :inactivate_category ]
    has_permission_on [:employee_attendance],
      :to => [
      :leave_app
    ]
    has_permission_on [:report],
      :to => [
      :csv_reports,
      :csv_report_download
    ]
  end

  role :employee_attendance do
    has_permission_on [:employee],
      :to => [
      :hr,
      :employee_attendance,
      :employee_leave_count_edit,
      :employee_leave_count_update,
      :view_attendance
    ]
    has_permission_on [:employee_attendances],
      :to => [
      :index,
      :show,
      :new,
      :create,
      :edit,
      :update,
      :destroy

    ]
    has_permission_on [:employee_attendance],
      :to => [
      :add_leave_types,
      :register,
      :report,
      :report_pdf,
      :leave_management,
      :edit_leave_types,
      :delete_leave_types,
      :update_attendance_form,
      :filter_attendance_report,
      :update_filterd_attendance_report,
      :filter_attendance_report,
      :update_filterd_attendance_report,
      :update_attendance_report,
      :individual_leave_application,
      :all_employee_new_leave_application,
      :all_employee_leave_application,
      :update_employees_select,
      :leave_list,
      :leave_app,
      :emp_attendance,
      :employee_attendance_pdf,
      :manual_reset,
      :employee_leave_reset_all,
      :update_employee_leave_reset_all,
      :leave_reset_settings,
      :employee_leave_reset_by_department,
      :list_department_leave_reset,
      :update_department_leave_reset,
      :employee_leave_reset_by_employee,
      :employee_search_ajax,
      :employee_view_all,
      :employees_list,
      :employee_leave_details,
      :employee_wise_leave_reset,
      :leave_history,
      :in_out_report,
      :update_leave_history,
      :additional_leave_history,
      :additional_leave_detailed,
      :additional_leave_report_pdf,
      :additional_leave_detailed_report_pdf
    ]
    has_permission_on [:report], :to => [:csv_reports,:csv_report_download]
    has_permission_on [:csv_export], :to => [:generate_csv]
  end

  role :payslip_powers do
    has_permission_on [:employee],
      :to => [
      :hr,
      :payslip,
      :select_department_employee,
      :rejected_payslip,
      :update_rejected_employee_list,
      :view_rejected_payslip,
      :edit_rejected_payslip,
      :update_rejected_payslip,
      :update_employee_select_list,
      :payslip_date_select,
      :one_click_payslip_generation,
      :payslip_revert_date_select,
      :one_click_payslip_revert,
      :ceate_monthly_select_list,
      :add_payslip_category,
      :create_payslip_category,
      :remove_new_paylist_category,
      :delete_payslip,
      :view_payslip,
      :update_monthly_payslip,
      :invidual_payslip_pdf,
      :create_monthly_payslip,
      :payslip_approve,
      :one_click_approve,
      :one_click_approve_submit,
      :department_payslip,
      :update_employee_payslip,
      :department_payslip_pdf,
      :employee_individual_payslip_pdf,
      :view_employee_payslip
    ]
    has_permission_on [:payroll],
      :to => [
      :manage_payroll,
      :profile_payroll_details,
      :edit_payroll_details,
      :view_payroll_details,
      :activate_category,
      :inactivate_category,
      :update_dependent_fields,
      :update_dependent_payslip_fields
    ]
  end

  role :employee_search do
    has_permission_on [:archived_employee],
      :to => [
      :profile,
      :profile_general,
      :profile_personal,
      :profile_address,
      :profile_contact,
      :profile_bank_details,
      :profile_additional_details,
      :profile_payroll_details,
      :profile_pdf,
      :show
    ]
    has_permission_on [:employee],
      :to => [
      :search,
      :view_all,
      :search_ajax,
      :profile,
      :view_all,
      :employees_list,
      :advanced_search,
      :advanced_search_pdf,
      :hr
    ]
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:report], :to => [:csv_reports,:csv_report_download]
  end

  role :employee_timetable_access do
    includes :timetable_track
    has_permission_on [:timetable], :to => [:employee_timetable,:update_employee_tt,:timetable_pdf]
    #    has_permission_on [:employee], :to => [:timetable,:timetable_pdf]
  end

  role :manage_users do
    has_permission_on [:user],
      :to =>[
      :index,
      :search_user_ajax,
      :all_users,
      :create,
      :profile,
      :list_user,
      :user_change_password,
      :delete,
      :edit_privilege,
      :login
    ]
    has_permission_on [:employee],
      :to => [
      :change_reporting_manager,
      :select_reporting_manager,
      :update_reporting_manager_name,
      :change_reporting_manager,
      :edit1,
      :delete,
      :change_to_former,
      :remove,
      :edit_personal,
      :edit2,
      :edit_contact,
      :edit3,
      :admission3_1
    ]
    has_permission_on [:student],
      :to => [
      :profile,
      :edit,
      :profile_pdf,
      :add_guardian,
      :admission3_1,
      :guardians,
      :email,
      :admission4,
      :previous_data,
      :previous_data_from_profile,
      :previous_subject,
      :save_previous_subject,
      :delete_previous_subject,
      :show_previous_details,
      :previous_data_edit,
      :edit_admission4,
      :edit_guardian,
      :del_guardian,
      :admission1_2,
      :render_batch_list,
      :set_roll_number_prefix,
      :search_ajax,
      :reports,
      :fees,
      :fee_details,
      :my_subjects,
      :choose_elective,
      :remove_elective,
      :change_to_former,
      :delete,
      :destroy,
      :remove,
      :generate_tc_pdf,
      :generate_new_tc_pdf,
      :exam_report,
      :activities,
      :update_activities,
      :destroy_dependencies,
      :student_fees_preference
    ]
    has_permission_on [:scheduled_jobs],
      :to => [
      :index
    ]
    has_permission_on [:exam],
      :to => [
      :student_wise_generated_report,
      :generated_report,
      :generated_report4_pdf,
      :graph_for_generated_report,
      :academic_report,
      :previous_years_marks_overview,
      :previous_years_marks_overview_pdf,
      :graph_for_previous_years_marks_overview,
      :generated_report3,
      :graph_for_generated_report3 ,
      :generated_report4,
      :student_transcript,
      :student_transcript_pdf,
      :combined_grouped_exam_report_pdf,
      :consolidated_exam_report,
      :generated_report_pdf,
      :consolidated_exam_report_pdf,
    ]
    has_permission_on [:report], :to => [:csv_reports]
    has_permission_on [:student_attendance], :to => [:student, :month, :student_report]
    has_permission_on [:finance], :to => [:refund_student_view,:refund_student_view_pdf]
    has_permission_on [:cce_reports], :to => [:student_transcript,:student_report_pdf]
    has_permission_on [:csv_export], :to => [:generate_csv]
    has_permission_on [:report], :to => [:csv_reports,:csv_report_download]
    has_permission_on [:remarks], :to => [:custom_remark_list,:remarks_history,:list_custom_remarks]
    has_permission_on [:icse_reports],
      :to=> [
      :student_report_pdf,
      :student_transcript,
      :student_report_csv,
    ]do
      if_attribute :icse_enabled? => is {true}
    end
  end

  # admin privileges
  role :admin do
    includes :archived_exam_reports
    includes :open
    includes :reports_view
    includes :timetable_track
    includes :manage_building
    includes :finance_control
    includes :manage_roll_number
    includes :manage_bank_details

    has_permission_on [:bank_details],
    :to=>[
      :index,
      :create,
      :edit,
      :new
    ]

    has_permission_on [:reminder],:to=>[
      :reminder,
      :sent_reminder,
      :view_sent_reminder,
      :delete_reminder_by_sender,
      :delete_reminder_by_recipient,
      :view_reminder,
      :mark_unread,
      :pull_reminder_form,
      :send_reminder,
      :reminder_actions,
      :sent_reminder_delete,
      :create_reminder,
      :to_employees,
      :to_students,
      :to_parents,
      :update_recipient_list,
      :update_recipient_list1,
      :update_recipient_list2

    ]
    has_permission_on [:user],  :to => [:edit_privilege,:index,:edit,:create,:user_change_password,:delete,:list_user,:profile,:all_users,:dashboard,:login,:logout,:show_quick_links,:manage_quick_links,:login]
    has_permission_on [:weekday], :to => [:index, :week,:list_batches,:get_class_timing_sets,:get_class_timing_set_for_edit, :create]
    has_permission_on [:class_timing_sets], :to => [
      :index,
      :new,
      :create,
      :edit,
      :update,
      :show,
      :destroy,
      :new_class_timings,
      :create_class_timings,
      :edit_class_timings,
      :update_class_timings,
      :delete_class_timings,
      :new_batch_class_timing_set,
      :list_batches,
      :add_batch,
      :remove_batch
    ]
    has_permission_on [:event],
      :to => [
      :index,
      :event_group,
      :select_course,
      :course_event,
      :remove_batch,
      :select_employee_department,
      :department_event,
      :remove_department,
      :show,
      :confirm_event,
      :cancel_event,
      :edit_event
    ]
    has_permission_on [:academic_year],
      :to => [
      :index,
      :add_course,
      :migrate_classes,
      :migrate_students,
      :list_students,
      :update_courses,
      :upcoming_exams ]
    has_permission_on [:attendances],
      :to => [
      :index,
      :show,
      :new,
      :create,
      :edit,
      :destroy,
      :list_subject,
      :update,
      :subject_wise_register,
      :daily_register,
      :quick_attendance
    ]
    has_permission_on [:sms],  :to => [:index, :settings, :update_general_sms_settings, :students, :list_students, :batches, :sms_all, :employees, :list_employees, :departments, :all, :show_sms_messages, :show_sms_logs]
    has_permission_on [:sms_settings],  :to => [:index, :update_general_sms_settings]
    has_permission_on [:class_timings],  :to => [:index, :edit, :destroy, :show, :new, :create, :update]
    has_permission_on [:attendance_reports], :to => [:index, :subject, :mode, :show, :year, :report, :filter, :student_details,:report_pdf,:filter_report_pdf]
    has_permission_on [:student_attendance], :to => [:index, :student, :month, :student_report]
    has_permission_on [:configuration], :to => [:index,:settings,:permissions, :add_weekly_holidays, :delete]
    has_permission_on [:single_access_tokens], :to => [:index,:new,:create,:destroy]
    has_permission_on [:subjects], :to => [:set_elective_group_name,:index, :new, :create,:destroy,:edit,:update, :show,:destroy_elective_group]
    has_permission_on [:elective_groups],  :to => [:index,:new,:create,:destroy,:edit, :update,:show,:new_elective_subject,:create_elective_subject, :edit_elective_subject, :update_elective_subject]
    has_permission_on [:revert_batch_transfers], :to => [:index,:list_students,:revert_transfer]
    has_permission_on [:courses],
      :to => [
      :index,
      :manage_course,
      :manage_batches,
      :new,
      :create,
      :update_batch,
      :edit,
      :update,
      :destroy,
      :show,
      :find_course,
      :grouped_batches,
      :create_batch_group,
      :edit_batch_group,
      :update_batch_group,
      :delete_batch_group,
      :assign_subject_amount,
      :edit_subject_amount,
      :destroy_subject_amount,
      :inactivate_batch,
      :activate_batch
    ]
    has_permission_on [:batches],
      :to => [
      :index,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :show,
      :init_data,
      :assign_tutor,
      :update_employees,
      :assign_employee,
      :remove_employee,
      :batches_ajax,
      :batch_summary,
      :list_batches,
      :tab_menu_items,
      :get_tutors,
      :get_batch_span
    ]
    has_permission_on [:batch_transfers],
      :to => [
      :index,
      :show,
      :transfer,
      :graduation,
      :subject_transfer,
      :get_previous_batch_subjects,
      :update_batch,
      :assign_previous_batch_subject,
      :assign_all_previous_batch_subjects,
      :new_subject,
      :create_subject
    ]
    has_permission_on [:employee_attendance],
      :to => [
      :index,
      :add_leave_types,
      :edit_leave_types,
      :delete_leave_types,
      :register,
      :update_attendance_form,
      :report,
      :report_pdf,
      :filter_attendance_report,
      :update_filterd_attendance_report,
      :update_attendance_report,
      :emp_attendance,
      :leaves,
      :leave_application,
      :leave_app,
      :approve_remarks,
      :deny_remarks,
      :approve_leave,
      :deny_leave,
      :cancel,
      :new_leave_applications,
      :all_employee_new_leave_applications,
      :all_leave_applications,
      :individual_leave_applications,
      :own_leave_application,
      :cancel_application,
      :employee_attendance_pdf,
      :update_all_application_view,
      :manual_reset,
      :employee_leave_reset_all,
      :leave_reset_settings,
      :update_employee_leave_reset_all,
      :employee_leave_reset_by_department,
      :list_department_leave_reset,
      :update_department_leave_reset,
      :employee_leave_reset_by_employee,
      :employee_search_ajax,
      :employee_view_all,
      :employees_list,
      :employee_leave_details,
      :employee_wise_leave_reset,
      :leave_history,
      :in_out_report,
      :update_leave_history,
      :additional_leave_history,
      :additional_leave_detailed,
      :additional_leave_report_pdf,
      :additional_leave_detailed_report_pdf

    ]
    has_permission_on [:employee_attendances],
      :to => [
      :index,
      :show,
      :new,
      :create,
      :edit,
      :update,
      :destroy
    ]
    has_permission_on [:grading_levels],
      :to => [
      :index,
      :show,
      :edit,
      :update,
      :new,
      :create,
      :destroy

    ]
    has_permission_on [:ranking_levels],
      :to => [
      :index,
      :load_ranking_levels,
      :create_ranking_level,
      :edit_ranking_level,
      :update_ranking_level,
      :delete_ranking_level,
      :ranking_level_cancel,
      :change_priority
    ]
    has_permission_on [:class_designations],
      :to => [
      :index,
      :load_class_designations,
      :create_class_designation,
      :edit_class_designation,
      :update_class_designation,
      :delete_class_designation
    ]
    has_permission_on [:exam],
      :to => [
      :index,
      :update_exam_form,
      :publish,
      :grouping,
      :exam_wise_report,
      :list_exam_types,
      :generated_report,
      :generated_report_pdf,
      :consolidated_exam_report,
      :consolidated_exam_report_pdf,
      :subject_wise_report,
      :subject_rank,
      :course_rank,
      :batch_groups,
      :student_course_rank,
      :student_course_rank_pdf,
      :student_school_rank,
      :student_school_rank_pdf,
      :attendance_rank,
      :student_attendance_rank,
      :student_attendance_rank_pdf,
      :generate_reports,
      :generate_previous_reports,
      :select_inactive_batches,
      :settings,
      :report_center,
      :gpa_cwa_reports,
      :list_batch_groups,
      :ranking_level_report,
      :student_ranking_level_report,
      :student_ranking_level_report_pdf,
      :transcript,
      :student_transcript,
      :student_transcript_pdf,
      :combined_report,
      :load_levels,
      :student_combined_report,
      :student_combined_report_pdf,
      :load_batch_students,
      :select_mode,
      :select_batch_group,
      :select_type,
      :select_report_type,
      :batch_rank,
      :student_batch_rank,
      :student_batch_rank_pdf,
      :student_subject_rank,
      :student_subject_rank_pdf,
      :list_subjects,
      :list_batch_subjects,
      :generated_report2,
      :generated_report2_pdf,
      :generated_report3,
      :final_report_type,
      :generated_report4,
      :generated_report4_pdf,
      :combined_grouped_exam_report_pdf,
      :previous_years_marks_overview,
      :previous_years_marks_overview_pdf,
      :academic_report,
      :previous_batch_exams,
      :course_wise_exams,
      :create_course_wise_exam_group,
      :update_exam_form_with_multibatch,
      :update_batch_in_course_wise_exams,
      :list_inactive_batches,
      :list_inactive_exam_groups,
      :previous_exam_marks,
      :edit_previous_marks,
      :update_previous_marks,
      :create_exam,
      :update_batch_ex_result,
      :update_batch,
      :graph_for_generated_report,
      :graph_for_generated_report3,
      :graph_for_previous_years_marks_overview,
      :grouped_exam_report,
      :student_wise_generated_report,
      :student_wise_generated_report_new,
      :term_wise_generated_report_new,
      :consolidated_term_exam_report_pdf,
      :combined_terms_report,
      :combined_terms_report_pdf,
      :student_term_report_pdf,
      :student_exam_report_pdf,
      :consolidated_term_report,
      :consolidated_term_report_pdf
    ]

    has_permission_on [:exam],
      :to => [
      :gpa_settings,
      :cgpa_average_example,
      :cgpa_credit_hours_example
    ]do
      if_attribute :gpa_enabled? => is {true}
    end

    has_permission_on [:remarks],
      :to => [
      :index,
      :add_remarks,
      :create_remarks,
      :edit_remarks,
      :edit_common_remarks,
      :show_remarks,
      :update_remarks,
      :update_common_remarks,
      :destroy_common_remarks,
      :show_common_remarks,
      :add_custom_remarks,
      :create_custom_remarks,
      :custom_remark_list,
      :list_custom_remarks,
      :edit_custom_remarks,
      :update_custom_remarks,
      :destroy_custom_remarks,
      :remarks_history,
      :add_employee_custom_remarks,
      :list_student_with_remark_subject,
      :employee_custom_remark_update,
      :employee_list_custom_remarks,
      :list_students,
      :destroy,
      :list_batches,
      :list_specific_batches
    ]
    has_permission_on [:scheduled_jobs],
      :to => [
      :index
    ]
    has_permission_on [:exam_groups],
      :to => [
      :index,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :show,
      :initial_queries,
      :set_exam_minimum_marks,
      :set_exam_maximum_marks,
      :set_exam_weightage,
      :set_exam_group_name,
      :set_exam_group_term_exam_id
    ]
    has_permission_on [:exams],
      :to => [
      :index,
      :show,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :save_scores,
      :query_data
    ]

    #    has_permission_on [:additional_exam],
    #      :to => [
    #      :index,
    #      :update_exam_form,
    #      :publish,
    #      :create_additional_exam,
    #      :update_batch
    #    ]

    #    has_permission_on [:additional_exam_groups],
    #      :to => [
    #      :index,
    #      :new,
    #      :create,
    #      :edit,
    #      :update,
    #      :destroy,
    #      :show,
    #      :initial_queries,
    #      :set_additional_exam_minimum_marks,
    #      :set_additional_exam_maximum_marks,
    #      :set_additional_exam_weightage,
    #      :set_additional_exam_group_name
    #    ]
    #    has_permission_on [:additional_exams],
    #      :to => [
    #      :index,
    #      :show,
    #      :new,
    #      :create,
    #      :edit,
    #      :update,
    #      :destroy,
    #      :save_additional_scores,
    #      :query_data
    #    ]


    #     has_permission_on [:finance],
    #       :to => [
    #       :index,
    #       :automatic_transactions,
    #       :categories,
    #       :donation,
    #       :donation_receipt,
    #       :expense_create,
    #       :expense_edit,
    #       :fee_collection,
    #       :fee_submission,
    #       :fees_received,
    #       :fee_structure,
    #       :fees_student_specific,
    #       :income_create,
    #       :transactions,
    #       :category_create,
    #       :category_delete,
    #       :category_edit,
    #       :category_update,
    #       :get_child_fee_element_form,
    #       :get_new_fee_element_form,
    #       :create_child_fee_element,
    #       :create_new_fee_element,
    #       :reset_fee_element,
    #       :fee_collection_create,
    #       :fee_collection_delete,
    #       :fee_collection_edit,
    #       :fee_collection_update,
    #       :fee_structure_create,
    #       :fee_structure_delete,
    #       :fee_structure_edit,
    #       :fee_structure_update,
    #       :transaction_trigger_create,
    #       :transaction_trigger_edit,
    #       :transaction_trigger_update,
    #       :transaction_trigger_delete,
    #       :fees_student_search,
    #       :search_logic,
    #       :fees_received,
    #       :fees_defaulters,
    #       :fees_submission_index,
    #       :fees_submission_batch,
    #       :update_fees_collection_dates,
    #       :load_fees_submission_batch,
    #       :update_ajax,
    #       :update_batches,
    #       :update_fees_collection_dates_defaulters,
    #       :fees_defaulters_students,
    #       :monthly_report,
    #       :update_monthly_report,
    #       :year_report,
    #       :update_year_report,
    #       :approve_monthly_payslip,
    #       :one_click_approve_submit,
    #       :one_click_approve,
    #       :employee_payslip_approve,
    #       :employee_payslip_reject,
    #       :employee_payslip_accept_form,
    #       :employee_payslip_reject_form,
    #       :payslip_index,
    #       :view_monthly_payslip,
    #       :view_monthly_payslip_search,
    #       :view_monthly_payslip_pdf,
    #       :update_monthly_payslip,:search_ajax,
    #       :view_payslip_dept,
    #       :update_dates,
    #       :update_monthly_payslip_all,
    #       :fee_structure_select_batch,
    #       :fees_student_dates,
    #       :fee_structure_batch,
    #       :fees_structure_student_search,
    #       :search_fees_structure,
    #       :fees_structure_dates,
    #       :fees_structure_result,
    #       :salary_department,
    #       :salary_employee,
    #       :employee_payslip_monthly_report,
    #       :direct_expenses,
    #       :direct_income,
    #       :donations_report,
    #       :fees_report,
    #       :batch_fees_report,
    #       :salary_department_year,
    #       :salary_employee_year,
    #       :direct_expenses_year,
    #       :direct_income_year,
    #       :donations_report_year,
    #       :fees_report_year,
    #       :asset_liability,
    #       :liability,
    #       :create_liability,
    #       :view_liability,
    #       :each_liability_view,
    #       :asset,
    #       :create_asset,
    #       :view_asset,
    #       :each_asset_view,
    #       :edit_liability,
    #       :update_liability,
    #       :delete_liability,
    #       :edit_asset,
    #       :update_asset,
    #       :delete_asset,
    #       :fee_collection_view,
    #       :fee_collection_dates_batch,
    #       :pay_fees_defaulters,
    #       :fee_structure_fee_collection_date,
    #       :fees_student_specific_dates,
    #       :update_fees_specific,
    #       :fees_index,
    #       #new_fee-----------
    #       :master_fees,
    #       :show_master_categories_list,
    #       #      :show_additional_fees_list,
    #       :fees_particulars,
    #       #      :additional_fees,
    #       #      :additional_fees_create_form,
    #       #      :additional_fees_create,
    #       #      :additional_fees_view,
    #       :add_particulars,
    #       :fee_collection_batch_update,
    #       :fees_submission_student,
    #       :fees_submission_save,
    #       :fee_particulars_update,
    #       :student_or_student_category,
    #       :fees_student_structure_search,
    #       :fees_student_structure_search_logic,
    #       :fee_structure_dates,
    #       :fees_structure_for_student,
    #       :master_fees_index,
    #       :master_category_create,
    #       :master_category_new,
    #       :fees_particulars_new,
    #       :fees_particulars_new2,
    #       :fees_particulars_create,
    #       :fees_particulars_create2,
    #       :add_particulars_new,
    #       :add_particulars_create,
    #       :fee_discounts,
    #       :fee_discount_new,
    #       :load_discount_create_form,
    #       :load_discount_batch,
    #       :load_batch_fee_category,
    #       :batch_wise_discount_create,
    #       :category_wise_fee_discount_create,
    #       :student_wise_fee_discount_create,
    #       :update_master_fee_category_list,
    #       :show_fee_discounts,
    #       :edit_fee_discount,
    #       :update_fee_discount,
    #       :delete_fee_discount,
    #       :fee_collection_new,
    #       :collection_details_view,
    #       :fee_collection_create,
    #       :categories_new,
    #       :categories_create,
    #       :master_category_edit,
    #       :master_category_update,
    #       :master_category_delete,
    #       :master_category_particulars,
    #       :master_category_particulars_edit,
    #       :master_category_particulars_update,
    #       :master_category_particulars_delete,
    #       #      :additional_fees_list,
    #       :additional_particulars,
    #       :add_particulars_edit,
    #       :add_particulars_update,
    #       :add_particulars_delete,
    #       #      :additional_fees_edit,
    #       #      :additional_fees_update,
    #       #      :additional_fees_delete,
    #       :month_date,
    #       :compare_report,
    #       :report_compare,
    #       :graph_for_compare_monthly_report,
    #       :update_fine_ajax,
    #       :student_fee_receipt_pdf,
    #       :update_student_fine_ajax,
    #       :transaction_pdf,
    #       :update_defaulters_fine_ajax,
    #       :fee_defaulters_pdf,
    #       :donation_receipt_pdf,
    #       :donors,
    #       :expense_list,
    #       :expense_list_update,
    #       :income_list,
    #       :income_list_update,
    # #      :income_details,
    # #      :income_details_pdf,
    #       :partial_payment,
    #       :donation_edit,
    #       :donation_delete,
    #       #pdf-------------
    #       :pdf_fee_structure,
    #
    #       #graph-------------
    #       :graph_for_update_monthly_report,
    #
    #       :view_employee_payslip,
    #       :income_list_pdf,
    #       :expense_list_pdf,
    #       :asset_pdf,
    #       :liability_pdf,
    #       :income_edit,
    #       :delete_transaction,
    #       :select_payment_mode,
    #       :delete_transaction_by_batch,
    #       :delete_transaction_for_student,
    #       :transaction_deletion,
    #       :delete_transaction_fees_defaulters,
    #       :deleted_transactions,
    #       :update_deleted_transactions,
    #       :list_deleted_transactions,
    #       :search_fee_collection,
    #       :transaction_filter_by_date,
    #       :transactions_advanced_search,
    #       :list_category_batch,
    #       :fees_refund,
    #       :create_refund,
    #       :new_refund,
    #       :apply_refund,
    #       :refund_student_search,
    #       :fees_refund_dates,
    #       :fees_refund_student,
    #       :view_refunds,
    #       :refund_filter_by_date,
    #       :search_fee_refunds,
    #       :list_refunds,
    #       :fee_refund_student_pdf,
    #       :refund_search_pdf,
    #       :generate_fine,
    #       :new_fine,
    #       :fine_list,
    #       :add_fine_slab,
    #       :fine_slabs_edit_or_create,
    #       :finance_reports,
    #       :fee_category_particulars,
    #       :particular_batches,
    #       :student_category_particulars,
    #       :category_particulars,
    #       :student_particulars,
    #       :refund_student_view,
    #       :refund_student_view_pdf,
    #       :delete_transaction_for_particular_wise_fee_pay,
    #       :student_wise_fee_payment,
    #     ]
    #     has_permission_on [:finance_extensions],:to=>[
    #       :pay_all_fees,
    #       :delete_multi_fees_transaction,
    #       :pay_all_fees_receipt_pdf,
    #       :pay_fees_in_particular_wise,
    #       :particular_wise_fee_payment,
    #       :particular_wise_fee_pay_pdf
    #     ]

    has_permission_on [:xml], :to =>
      [
      :create_xml,
      :index,
      :settings,
      :download
    ]

    has_permission_on [:holiday], :to => [:index,:edit,:delete]
    has_permission_on [:news],
      :to => [
      :index,
      :add,
      :add_comment,
      :all,
      :delete,
      :delete_comment,
      :comment_approved,
      :edit,
      :search_news_ajax,
      :view,
      :comment_view]
    has_permission_on [:payroll],
      :to => [
      :index,
      :add_category,
      :edit_category,
      :delete_category,
      :activate_category,
      :inactivate_category,
      :manage_payroll,
      :update_dependent_fields,
      :update_dependent_payslip_fields,
      :edit_payroll_details ]
    has_permission_on [:student],
      :to => [
      :academic_pdf,
      :profile,
      :admission1,
      :render_batch_list,
      :set_roll_number_prefix,
      :admission1_2,
      :admission2,
      :admission3,
      :add_guardian,
      :edit,
      :edit_guardian,
      :guardians,
      :del_guardian,
      :list_students_by_course,
      :show,
      :view_all,
      :index,
      :academic_report,
      :academic_report_all,
      :change_to_former,
      :delete,
      :destroy,
      :email,
      :exam_report,
      :update_student_result_for_examtype,
      :previous_years_marks_overview,
      :previous_years_marks_overview_pdf,
      :remove,
      :reports,
      :search_ajax,
      :student_annual_overview,
      :subject_wise_report,
      :graph_for_previous_years_marks_overview,
      :graph_for_academic_report,
      :graph_for_annual_academic_report,
      :graph_for_student_annual_overview,
      :graph_for_subject_wise_report_for_one_subject,
      :graph_for_exam_report,
      :category_update,
      :category_edit,
      :category_delete,
      :categories,
      :add_additional_details,
      :change_field_priority,
      :edit_additional_details,
      :delete_additional_details,
      :admission4,
      :advanced_search,
      :list_batches,
      :electives,
      :assigned_elective_subjects,
      :search_students,
      :assign_students,
      :unassign_students,
      :list_doa_year,
      :doa_equal_to_update,
      :doa_less_than_update,
      :doa_greater_than_update,
      :list_dob_year,:dob_equal_to_update,:dob_less_than_update,:dob_greater_than_update,
      :advanced_search_pdf,
      :previous_data,
      :previous_data_from_profile,
      :previous_subject,
      :previous_data_edit,
      :save_previous_subject,
      :delete_previous_subject,
      :profile_pdf,
      :generate_tc_pdf,
      :generate_new_tc_pdf,
      :generate_all_tc_pdf,
      :assign_all_students,
      :unassign_all_students,
      :edit_admission4,
      :admission3_1,
      :admission3_2,
      :show_previous_details,
      :fees,
      :fee_details,
      :my_subjects,
      :choose_elective,
      :remove_elective,
      :activities,
      :update_activities,
      :destroy_dependencies,
      :pay_all_fees,
      :view_all_fees,
      :delete_multi_fees_transaction,
      :delete_transaction_for_particular_wise_fee_pay,
      :pay_all_fees_receipt_pdf,
      :student_fees_preference
    ]
    has_permission_on [:finance_extensions],:to=>[
      :pay_all_fees,
      :delete_multi_fees_transaction,
      :pay_all_fees_receipt_pdf,
      :pay_fees_in_particular_wise,
      :particular_wise_fee_payment,
      :particular_wise_fee_pay_pdf
    ]
    has_permission_on [:archived_student],
      :to => [
      :profile,
      :reports,
      :guardians,
      :delete,
      :destroy,
      :generate_tc_pdf,
      :generate_new_tc_pdf,
      :consolidated_exam_report,
      :consolidated_exam_report_pdf,
      :academic_report,
      :student_report,
      :generated_report,
      :generated_report_pdf,
      :generated_report3,
      :previous_years_marks_overview,
      :previous_years_marks_overview_pdf,
      :generated_report4,
      :generated_report4_pdf,
      :graph_for_generated_report,
      :graph_for_generated_report3,
      :graph_for_previous_years_marks_overview,
      :edit_leaving_date,
      :revert_archived_student
    ]
    has_permission_on [:subject],
      :to => [
      :index,
      :create,
      :delete,
      :edit,
      :list_subjects ]
    has_permission_on [:timetable],
      :to => [:index,
      :new_timetable,
      :update_timetable,
      :manage_timetable,
      :add_batch_timetable,
      :remove_batch_timetable,
      :view,
      :edit_master,
      :teachers_timetable,
      :update_teacher_tt,
      :update_timetable_view,
      :timetable_view_batches,
      :destroy,
      :employee_timetable,
      :update_employee_tt,
      :student_view,
      :update_student_tt,
      :weekdays,
      :timetable,
      :timetable_pdf,
      :work_allotment,
      :csv_reports,
      :csv_report_download
    ]
    has_permission_on [:timetable_entries],
      :to => [
      :new,
      :select_batch,
      :new_entry,
      :update_employees,
      :delete_employee2,
      :update_multiple_timetable_entries2,
      :tt_entry_update2,
      :tt_entry_noupdate2
    ]
    has_permission_on [:weekdays],
      :to => [
      :index,
      :new
    ]
    has_permission_on [:archived_employee],
      :to => [
      :profile,
      :profile_general,
      :profile_personal,
      :profile_address,
      :profile_contact,
      :profile_bank_details,
      :profile_additional_details,
      :profile_payroll_details,
      :profile_pdf,
      :show
    ]
    has_permission_on [:employee],
      :to => [
      :index,
      :add_category,
      :edit_category,
      :delete_category,
      :add_position,
      :edit_position,
      :delete_position,
      :add_department,
      :edit_department,
      :delete_department,
      :add_grade,
      :edit_grade,
      :delete_grade,
      :admission1,
      :update_positions,
      :edit1,
      :edit_personal,
      :admission2,
      :edit2,
      :edit_contact,
      :admission3,
      :edit3,
      :admission4,
      :change_reporting_manager,
      :reporting_manager_search,
      :update_reporting_manager_name,
      :edit4,
      :search,
      :search_ajax,
      :select_reporting_manager,
      :profile,
      :profile_general,
      :profile_personal,
      :profile_address,
      :profile_contact,
      :profile_bank_details,
      :profile_payroll_details,
      :view_all,
      :show,
      :add_payslip_category,
      :create_payslip_category,
      :remove_new_paylist_category,
      :create_monthly_payslip,
      :view_payslip,
      :update_monthly_payslip,
      :delete_payslip,
      :view_attendance,
      :subject_assignment,
      :update_subjects,
      :select_department,
      :update_employees,
      :assign_employee,
      :remove_employee,
      :hr,
      :payslip,
      :select_department_employee,
      :rejected_payslip,
      :update_rejected_employee_list,
      :view_rejected_payslip,
      :edit_rejected_payslip,
      :update_rejected_payslip,
      :update_employee_select_list,
      :payslip_date_select,
      :one_click_payslip_generation,
      :payslip_revert_date_select,
      :one_click_payslip_revert,
      :leave_management,
      :all_employee_leave_applications,
      :update_employees_select,
      :leave_list,
      :individual_payslip_pdf,
      :settings,
      :employee_management,
      :employee_attendance,
      :employees_list,
      :add_bank_details,
      :edit_bank_details,
      :delete_bank_details,
      :admission3,
      :admission3_1,
      :admission3_2,
      :add_additional_details,
      :change_field_priority,
      :edit_additional_details,
      :delete_additional_details,
      :profile_additional_details,
      :edit3_1,
      :advanced_search,
      :list_doj_year,
      :doj_equal_to_update,
      :doj_less_than_update,
      :doj_greater_than_update,
      :list_dob_year,:dob_equal_to_update,:dob_less_than_update,:dob_greater_than_update,
      :remove,:change_to_former,:delete,:remove_subordinate_employee,
      :edit_privilege,
      :advanced_search_pdf,
      :profile_pdf,
      :department_payslip,
      :update_employee_payslip,
      :department_payslip_pdf,
      :view_rep_manager,
      :payslip_approve,
      :one_click_approve,
      :one_click_approve_submit,
      :employee_individual_payslip_pdf,
      :employee_leave_count_edit,
      :employee_leave_count_update,
      :view_employee_payslip,
      :activities,
      :update_activities

    ]
    has_permission_on [:calendar], :to => [:event_delete]

    has_permission_on [:descriptive_indicators],
      :to=>[
      :index,
      :new,
      :create,
      :show,
      :edit,
      :update,
      :destroy,
      :reorder,
      :destroy_indicator,
      :show_in_report
    ]
    has_permission_on [:fa_criterias],
      :to=>[
      :index,
      :show
    ]
    has_permission_on [:fa_groups],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :show,
      :assign_fa_groups,
      :select_subjects,
      :select_fa_groups,
      :update_subject_fa_groups,
      :new_fa_criteria,
      :create_fa_criteria,
      :edit_fa_criteria,
      :update_fa_criteria,
      :destroy_fa_criteria,
      :reorder,
      :edit_criteria_formula,
      :update_criteria_formula

    ]
    has_permission_on [:observation_groups],
      :to=>[
      :index,
      :new,
      :show,
      :create,
      :edit,
      :update,
      :destroy,
      :new_observation,
      :edit_observation,
      :create_observation,
      :edit_osbervation,
      :update_observation,
      :destroy_observation,
      :assign_courses,
      :select_observation_groups,
      :update_course_obs_groups,
      :reorder,
      :reorder_ob_groups
    ]
    has_permission_on [:observations],
      :to=>[
      :show
    ]
    has_permission_on [:assessment_scores],
      :to=>[
      :exam_fa_groups,
      :fa_scores,
      :observation_groups,
      :observation_scores
    ]
    has_permission_on [:cce_exam_categories],
      :to=>[
      :index,
      :new,
      :show,
      :create,
      :edit,
      :update,
      :destroy
    ]
    has_permission_on [:cce_grade_sets],
      :to=>[
      :index,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :show,
      :index,
      :new_grade,
      :create_grade,
      :edit_grade,
      :update_grade,
      :destroy_grade
    ]
    has_permission_on [:cce_reports],
      :to=>[
      :index,
      :create_reports,
      :student_wise_report,
      :student_report_pdf,
      :student_transcript,
      :student_report,
      :assessment_wise_report,
      :list_batches,
      :generated_report,
      :generated_report_csv,
      :generated_report_pdf,
      :subject_wise_report,
      :subject_wise_batches,
      :list_subjects,
      :subject_wise_generated_report,
      :subject_wise_generated_report_csv,
      :subject_wise_generated_report_pdf
    ]
    has_permission_on [:cce_settings],
      :to=>[
      :index,
      :basic,
      :scholastic,
      :co_scholastic
    ]
    has_permission_on [:cce_weightages],
      :to=>[
      :index,
      :new,
      :create,
      :show,
      :edit,
      :update,
      :destroy,
      :assign_courses,
      :assign_weightages,
      :select_weightages,
      :update_course_weightages
    ]
    has_permission_on [:classroom_allocations],
      :to=> [
      :index,
      :new,
      :view,
      :weekly_allocation,
      :date_specific_allocation,
      :render_classrooms,
      :display_rooms,
      :update_allocation_entries,
      :override_allocations,
      :delete_allocation,
      :find_allocations
    ]
    has_permission_on [:buildings],
      :to => [
      :index,
      :new,
      :update,
      :edit,
      :show
    ]
    has_permission_on [:classrooms],
      :to => [
      :show
    ]
    has_permission_on [:icse_settings],
      :to=>[
      :index,
      :icse_exam_categories,
      :new_icse_exam_category,
      :create_icse_exam_category,
      :edit_icse_exam_category,
      :update_icse_exam_category,
      :destroy_icse_exam_category,
      :icse_weightages,
      :new_icse_weightage,
      :create_icse_weightage,
      :edit_icse_weightage,
      :update_icse_weightage,
      :destroy_icse_weightage,
      :assign_icse_weightages,
      :select_subjects,
      :select_icse_weightages,
      :update_subject_weightages,
      :internal_assessment_groups,
      :new_ia_group,
      :create_ia_group,
      :edit_ia_group,
      :update_ia_group,
      :destroy_ia_group,
      :assign_ia_groups,
      :ia_group_subjects,
      :select_ia_groups,
      :update_subject_ia_groups
    ]do
      if_attribute :icse_enabled? => is {true}
    end
    has_permission_on [:ia_scores],
      :to=>[
      :ia_scores,
      :update_ia_score
    ]
    has_permission_on [:icse_reports],
      :to=> [
      :index,
      :generate_reports,
      :student_wise_report,
      :student_report,
      :student_report_pdf,
      :student_transcript,
      :subject_wise_report,
      :list_batches,
      :list_subjects,
      :list_exam_groups,
      :subject_wise_generated_report,
      :internal_and_external_mark_pdf,
      :detailed_internal_and_external_mark_pdf,
      :internal_and_external_mark_csv,
      :detailed_internal_and_external_mark_csv,
      :consolidated_report,
      :consolidated_generated_report,
      :consolidated_report_csv,
      :student_report_csv,
      :batches_ajax
    ]do
      if_attribute :icse_enabled? => is {true}
    end
    has_permission_on [:attendance_reports], :to => [:day_wise_report,:day_wise_report_filter_by_course,:in_out_attendance,:get_in_out_attendance_report, :get_in_out_attendance_pdf_report, :employee_in_out_attendance, :get_employee_in_out_attendance_report, :individual_employee_in_out_attendance, :individual_employee_in_out_attendance_pdf, :employee_in_out_attendance_pdf_report,:daily_report_batch_wise]do
      if_attribute :can_view_day_wise_report? => is {true}
    end
  end

  # student- privileges
  role :student do
    includes :open
    has_permission_on [:user], :to => [:profile,:user_change_password,:my_subjects,:choose_elective, :remove_elective,:dashboard,:logout,:login] do
      if_attribute :id => is {user.id}
    end
    has_permission_on [:reminder],:to=>[
      :reminder,
      :sent_reminder,
      :view_sent_reminder,
      :delete_reminder_by_sender,
      :delete_reminder_by_recipient,
      :view_reminder,
      :mark_unread,
      :pull_reminder_form,
      :send_reminder,
      :reminder_actions,
      :sent_reminder_delete,
      :create_reminder,
      :to_employees,
      :to_students,
      :to_parents,
      :update_recipient_list,
      :update_recipient_list1,
      :update_recipient_list2

    ]
    has_permission_on [:course], :to => [:view]
    has_permission_on [:exam], :to => [:student_wise_generated_report,:generated_report, :generated_report4_pdf, :graph_for_generated_report, :academic_report, :previous_years_marks_overview,:previous_years_marks_overview_pdf, :graph_for_previous_years_marks_overview, :generated_report3, :graph_for_generated_report3 ,:generated_report4,:student_transcript,:student_transcript_pdf]
    has_permission_on [:student],
      :to => [
      :exam_report,
      :show,
      :academic_pdf,
      :profile,
      :guardians,
      :list_students_by_course,
      :academic_report,
      :previous_years_marks_overview,
      :previous_years_marks_overview_pdf,
      :reports,
      :student_annual_overview,
      :subject_wise_report,
      :graph_for_previous_years_marks_overview,
      :graph_for_student_annual_overview,
      :graph_for_subject_wise_report_for_one_subject,
      :graph_for_exam_report,
      :graph_for_academic_report,
      :show_previous_details,
      :fees,
      :my_subjects,
      :choose_elective,
      :remove_elective,
      :fee_details,
      :activities,
      :update_activities
    ]
    has_permission_on [:news],
      :to => [
      :index,
      :all,
      :search_news_ajax,
      :view,
      :comment_view,
      :add_comment,
      :delete_comment]
    has_permission_on [:subject], :to => [:index,:list_subjects]
    has_permission_on [:timetable], :to => [:student_view, :update_student_tt]
    has_permission_on [:attendance], :to => [:student_report]
    has_permission_on [:student_attendance], :to => [:student, :month, :student_report]
    has_permission_on [:finance], :to => [:student_fees_structure,:refund_student_view,:refund_student_view_pdf]
    has_permission_on [:cce_reports], :to => [:student_transcript,:student_report_pdf]
    has_permission_on [:icse_reports],
      :to=> [
      :student_report_pdf,
      :student_transcript,
      :student_report_csv
    ]do
      if_attribute :icse_enabled? => is {true}
    end
    has_permission_on [:remarks], :to =>[:custom_remark_list,:remarks_history,:list_custom_remarks,:show_common_remarks]
  end

  role :parent do
    includes :open
    has_permission_on [:user], :to => [:profile,:user_change_password, :my_subjects, :choose_elective, :remove_elective,:dashboard,:logout,:login] do
      if_attribute :id => is {user.id}
    end
    has_permission_on [:reminder],:to =>[
      :reminder,
      :sent_reminder,
      :view_sent_reminder,
      :delete_reminder_by_sender,
      :delete_reminder_by_recipient,
      :view_reminder,
      :mark_unread,
      :pull_reminder_form,
      :send_reminder,
      :reminder_actions,
      :sent_reminder_delete,
      :create_reminder,
      :to_employees,
      :to_students,
      :to_parents,
      :update_recipient_list,
      :update_recipient_list1,
      :update_recipient_list2

    ]
    has_permission_on [:course], :to => [:view]
    has_permission_on [:exam], :to => [:student_wise_generated_report,:generated_report, :generated_report4_pdf , :graph_for_generated_report, :academic_report, :previous_years_marks_overview,:previous_years_marks_overview_pdf, :graph_for_previous_years_marks_overview, :generated_report3, :graph_for_generated_report3 ,:generated_report4,:student_transcript,:student_transcript_pdf]
    has_permission_on [:timetable], :to => [:student_view, :update_student_tt]
    has_permission_on [:student],
      :to => [
      :exam_report,
      :show,
      :academic_pdf,
      :profile,
      :guardians,
      :list_students_by_course,
      :academic_report,
      :previous_years_marks_overview,
      :previous_years_marks_overview_pdf,
      :reports,
      :student_annual_overview,
      :subject_wise_report,
      :graph_for_previous_years_marks_overview,
      :graph_for_student_annual_overview,
      :graph_for_subject_wise_report_for_one_subject,
      :graph_for_exam_report,
      :graph_for_academic_report,
      :show_previous_details,
      :fees,
      :fee_details,
      :activities,
      :update_activities
    ]
    has_permission_on [:news],
      :to => [
      :index,
      :all,
      :search_news_ajax,
      :view,
      :comment_view,
      :add_comment,
      :delete_comment]
    has_permission_on [:subject], :to => [:index,:list_subjects]
    has_permission_on [:timetable], :to => [:student_view,:update_timetable_view,:timetable_view_batches]
    has_permission_on [:attendance], :to => [:student_report]
    has_permission_on [:student_attendance], :to => [:student, :month, :student_report]
    has_permission_on [:finance], :to => [:student_fees_structure,:refund_student_view,:refund_student_view_pdf]
    has_permission_on [:cce_reports], :to => [:student_transcript,:student_report_pdf]
    has_permission_on [:icse_reports],
      :to=> [
      :student_report_pdf,
      :student_transcript,
      :student_report_csv
    ]do
      if_attribute :icse_enabled? => is {true}
    end
    has_permission_on [:remarks], :to =>[:custom_remark_list,:remarks_history,:show_common_remarks,:list_custom_remarks]
  end

  # employee -privileges
  role :employee do
    includes :open
    has_permission_on [:user], :to => [:profile,:user_change_password,:dashboard,:logout,:manage_quick_links,:login] do
      if_attribute :id => is {user.id}
    end
    has_permission_on [:batches],:to=>[:show,:batches_ajax,:batch_summary,:list_batches,:tab_menu_items,:get_tutors,:get_batch_span] do
      if_attribute :can_view_results? => is {true}
    end
    has_permission_on [:student],:to=>[:profile] do
      if_attribute :can_view_results? => is {true}
    end
    has_permission_on [:employee],
      :to => [
      :profile,
      :profile_general,
      :profile_personal,
      :profile_address,
      :profile_contact,
      :profile_bank_details,
      :profile_payroll_details,
      :profile_additional_details,
      :view_payslip,
      :view_attendance,
      :update_monthly_payslip,
      :select_employee_department,
      :select_student_course,
      :all_employee_leave_applications,
      :individual_payslip_pdf,
      :show,
      :profile_pdf,
      :activities,
      :update_activities
    ]
    has_permission_on [:timetable],:to => [:employee_timetable,:update_employee_tt]
    has_permission_on [:news],
      :to => [
      :index,
      :all,
      :search_news_ajax,
      :view,
      :comment_view,
      :add_comment,
      :delete_comment]
    has_permission_on [:employee_attendance],
      :to => [
      :index,
      :leaves,
      :leave_application,
      :own_leave_application,
      :cancel_application,
      :individual_leave_applications,
      :all_leave_applications,
      :update_all_application_view,
      :new_leave_applications,
      :approve_remarks,
      :approve_leave,
      :deny_remarks,
      :cancel,
      :all_employee_new_leave_applications,
      :employee_attendance_pdf,
      :deny_leave,
      :leave_history,
      :in_out_report,
      :update_leave_history
    ]
    has_permission_on [:reminder],
      :to => [
      :reminder,
      :sent_reminder,
      :view_sent_reminder,
      :delete_reminder_by_sender,
      :delete_reminder_by_recipient,
      :view_reminder,
      :mark_unread,
      :pull_reminder_form,
      :send_reminder,
      :reminder_actions,
      :sent_reminder_delete,
      :create_reminder,
      :to_employees,
      :to_students,
      :to_parents,
      :update_recipient_list,
      :update_recipient_list1,
      :update_recipient_list2
    ]
    has_permission_on [:assessment_scores],
      :to=>[
      :exam_fa_groups,
      :fa_scores,
      :observation_scores
    ]
    has_permission_on :assessment_scores, :to => [:observation_groups,:observation_scores] do
      if_attribute :teaches_in_this_batch? => is {true}
    end
    has_permission_on :student_attendance, :to => [:index] do
      if_attribute :is_allowed_to_mark_attendance? => is {true}
    end
    has_permission_on [:attendances], :to => [:index, :list_subject, :show, :new, :create, :edit,:update, :destroy,:subject_wise_register,:quick_attendance] do
      if_attribute :is_allowed_to_mark_attendance? => is {true}
    end
    has_permission_on [:attendance_reports], :to => [:index, :subject, :mode, :show, :year, :report, :filter, :student_details,:report_pdf,:filter_report_pdf] do
      if_attribute :is_allowed_to_mark_attendance? => is {true}
    end
    has_permission_on [:attendance_reports], :to => [:day_wise_report,:day_wise_report_filter_by_course,:in_out_attendance,:get_in_out_attendance_report, :get_in_out_attendance_pdf_report, :employee_in_out_attendance, :get_employee_in_out_attendance_report, :individual_employee_in_out_attendance, :individual_employee_in_out_attendance_pdf, :employee_in_out_attendance_pdf_report,:daily_report_batch_wise] do
      if_attribute :can_view_day_wise_report? => is {true}
    end
    has_permission_on [:exam],
      :to => [
      :index,
      :exam_wise_report,
      :list_exam_types,
      :generated_report,
      :graph_for_generated_report,
      :generated_report_pdf,
      :student_wise_generated_report,
      :consolidated_exam_report,
      :consolidated_exam_report_pdf,
      :subject_wise_report,
      :subject_rank,
      :course_rank,
      :batch_groups,
      :student_course_rank,
      :student_course_rank_pdf,
      :student_school_rank,
      :student_school_rank_pdf,
      :attendance_rank,
      :student_attendance_rank,
      :student_attendance_rank_pdf,
      :report_center,
      :gpa_cwa_reports,
      :list_batch_groups,
      :ranking_level_report,
      :student_ranking_level_report,
      :student_ranking_level_report_pdf,
      :transcript,
      :student_transcript,
      :student_transcript_pdf,
      :combined_report,
      :load_levels,
      :student_combined_report,
      :student_combined_report_pdf,
      :load_batch_students,
      :select_mode,
      :select_batch_group,
      :select_type,
      :select_report_type,
      :batch_rank,
      :student_batch_rank,
      :student_batch_rank_pdf,
      :student_subject_rank,
      :student_subject_rank_pdf,
      :list_subjects,
      :list_batch_subjects,
      :generated_report2,
      :generated_report2_pdf,
      :grouped_exam_report,
      :final_report_type,
      :generated_report4,
      :generated_report4_pdf,
      :combined_grouped_exam_report_pdf,
      :term_wise_generated_report_new,
      :consolidated_term_exam_report_pdf,
      :combined_terms_report,
      :combined_terms_report_pdf,
      :student_term_report_pdf,
      :consolidated_term_report,
      :consolidated_term_report_pdf
    ] do
      if_attribute :has_required_control? => is {true}
    end
    has_permission_on [:exam],
      :to => [
      :create_exam,
      :update_batch
    ] do
      if_attribute :has_assigned_subjects? => is {true}
    end
    has_permission_on [:exam_groups],
      :to => [
      :index,
      :show,
      :set_exam_maximum_marks,
      :set_exam_minimum_marks
    ] do
      if_attribute :has_assigned_subjects? => is {true}
    end
    has_permission_on [:exams],
      :to => [
      :show,
      :save_scores
    ] do
      if_attribute :has_assigned_subjects? => is {true}
    end
    has_permission_on [:exam_reports],
      :to => [
      :archived_exam_wise_report,
      :list_inactivated_batches,
      :final_archived_report_type,
      :consolidated_exam_report,
      :consolidated_exam_report_pdf,
      :archived_batches_exam_report,
      :archived_batches_exam_report_pdf,
      :graph_for_archived_batches_exam_report
    ] do
      # if_attribute :can_view_results? => is {true}
      if_attribute :has_required_control? => is {true}
    end
    #    has_permission_on [:student], :to => [:reports] do
    #      if_attribute :can_view_results? => is {true}
    #    end
    #    has_permission_on [:exam], :to => [:index,
    #      :exam_wise_report,
    #      :list_exam_types,
    #      :generated_report,
    #      :graph_for_generated_report,
    #      :generated_report_pdf,
    #      :consolidated_exam_report,
    #      :consolidated_exam_report_pdf,
    #      :subject_wise_report,
    #      :subject_rank,
    #      :course_rank,
    #      :batch_groups,
    #      :student_course_rank,
    #      :student_course_rank_pdf,
    #      :student_school_rank,
    #      :student_school_rank_pdf,
    #      :attendance_rank,
    #      :student_attendance_rank,
    #      :student_attendance_rank_pdf,
    #      :report_center,
    #      :gpa_cwa_reports,
    #      :list_batch_groups,
    #      :ranking_level_report,
    #      :student_ranking_level_report,
    #      :student_ranking_level_report_pdf,
    #      :transcript,
    #      :student_transcript,
    #      :student_transcript_pdf,
    #      :combined_report,
    #      :load_levels,
    #      :student_combined_report,
    #      :student_combined_report_pdf,
    #      :load_batch_students,
    #      :select_mode,
    #      :select_batch_group,
    #      :select_type,
    #      :select_report_type,
    #      :batch_rank,
    #      :student_batch_rank,
    #      :student_batch_rank_pdf,
    #      :student_subject_rank,
    #      :student_subject_rank_pdf,
    #      :list_subjects,
    #      :list_batch_subjects,
    #      :generated_report2,
    #      :generated_report2_pdf,
    #      :grouped_exam_report,
    #      :final_report_type,
    #      :generated_report4,
    #      :generated_report4_pdf,
    #      :combined_grouped_exam_report_pdf
    #    ] do
    #      if_attribute :can_view_results? => is {true}
    #    end
    has_permission_on [:cce_reports],
      :to=>[
      :index,
      #      :student_transcript,
      #      :student_report,
      :list_batches,
      :subject_wise_report,
      :subject_wise_batches,
      :list_subjects,
      :subject_wise_generated_report,
      :subject_wise_generated_report_csv,
      :subject_wise_generated_report_pdf,
      :assessment_wise_report,
      :generated_report,
      :generated_report_pdf,
      :generated_report_csv,
      :student_wise_report,
      :student_report_pdf,
      :student_report
    ] do
      if_attribute :has_cce_subjects? => is {true}
    end

    has_permission_on [:attendances], :to => [:daily_register]
    has_permission_on [:attendance_reports], :to => [:student]
    has_permission_on [:ia_scores],
      :to=>[
      :ia_scores,
      :update_ia_score
    ] do
      if_attribute :subject_user_ids? => contains {user.id}
    end
    has_permission_on [:icse_reports],
      :to=> [
      :index,
      :student_wise_report,
      :student_report,
      :student_report_pdf,
      :student_transcript,
      :subject_wise_report,
      :list_batches,
      :list_subjects,
      :list_exam_groups,
      :subject_wise_generated_report,
      :internal_and_external_mark_pdf,
      :detailed_internal_and_external_mark_pdf,
      :internal_and_external_mark_csv,
      :detailed_internal_and_external_mark_csv,
      :consolidated_report,
      :consolidated_generated_report,
      :consolidated_report_csv,
      :student_report_csv,
    ],:join_by=> :and do
      if_attribute :icse_enabled? => is {true}
      if_attribute :can_view_results? => is {true}
    end

    has_permission_on [:remarks],
      :to =>[
      :edit_remarks,
      :update_remarks,
      :add_remarks,
      :create_remarks,
      :destroy,
      :edit_common_remarks,
      :update_common_remarks,
      :destroy_common_remarks,
      :show_common_remarks
    ] do
      if_attribute :has_employee_privilege => is {true}
    end
    has_permission_on [:remarks],
      :to =>[
      :index,
      :add_employee_custom_remarks,
      :employee_list_custom_remarks,
      :list_students,
      :list_custom_remarks,
      :list_student_with_remark_subject,
      :employee_custom_remark_update,
      :edit_custom_remarks,
      :destroy_custom_remarks,
      :update_custom_remarks,
      :list_batches,
      :list_specific_batches
    ] do
      if_attribute :can_view_results? => is {true}
    end
    has_permission_on [:report], :to => [:csv_reports,:csv_report_download]
    has_permission_on [:csv_export], :to => [:generate_csv]
  end

  role :subject_attendance do
    has_permission_on [:attendances], :to => [:index, :list_subject, :show, :new, :create, :edit,:update, :destroy,:subject_wise_register,:quick_attendance]
    has_permission_on [:attendance_reports], :to => [:index, :subject, :mode, :show, :year, :report, :filter, :student_details,:report_pdf,:filter_report_pdf]

  end

  role :subject_exam do
    has_permission_on [:exam],
      :to => [
      :index,
      :create_exam,
      :update_batch,
      :exam_wise_report,
      :list_exam_types,
      :generated_report,
      :graph_for_generated_report,
      :generated_report_pdf,
      :student_wise_generated_report,
      :consolidated_exam_report,
      :consolidated_exam_report_pdf,
      :subject_wise_report,
      :subject_rank,
      :course_rank,
      :batch_groups,
      :student_course_rank,
      :student_course_rank_pdf,
      :student_school_rank,
      :student_school_rank_pdf,
      :attendance_rank,
      :student_attendance_rank,
      :student_attendance_rank_pdf,
      :report_center,
      :gpa_cwa_reports,
      :list_batch_groups,
      :ranking_level_report,
      :student_ranking_level_report,
      :student_ranking_level_report_pdf,
      :transcript,
      :student_transcript,
      :student_transcript_pdf,
      :combined_report,
      :load_levels,
      :student_combined_report,
      :student_combined_report_pdf,
      :load_batch_students,
      :select_mode,
      :select_batch_group,
      :select_type,
      :select_report_type,
      :batch_rank,
      :student_batch_rank,
      :student_batch_rank_pdf,
      :student_subject_rank,
      :student_subject_rank_pdf,
      :list_subjects,
      :list_batch_subjects,
      :generated_report2,
      :generated_report2_pdf,
      :grouped_exam_report,
      :final_report_type,
      :generated_report4,
      :generated_report4_pdf,
      :combined_grouped_exam_report_pdf
    ]
    has_permission_on [:exam_groups],
      :to => [
      :index,
      :show,
      :set_exam_maximum_marks,
      :set_exam_minimum_marks
    ]
    has_permission_on [:exams],
      :to => [
      :show,
      :save_scores
    ]
    #    has_permission_on [:additional_exam],
    #      :to =>[
    #      :create_additional_exam,
    #      :update_batch
    #    ]
    #    has_permission_on [:additional_exam_groups],
    #      :to =>[
    #      :index,
    #      :show,
    #      :set_additional_exam_minimum_marks,
    #      :set_additional_exam_maximum_marks,
    #      :set_additional_exam_weightage,
    #      :set_additional_exam_group_name
    #    ]
    #    has_permission_on [:additional_exams],
    #      :to => [
    #      :index,
    #      :show,
    #      :save_additional_scores
    #    ]
  end

  role :archived_exam_reports do
    has_permission_on [:exam_reports],
      :to => [
      :archived_exam_wise_report,
      :list_inactivated_batches,
      :final_archived_report_type,
      :consolidated_exam_report,
      :consolidated_exam_report_pdf,
      :archived_batches_exam_report,
      :archived_batches_exam_report_pdf,
      :graph_for_archived_batches_exam_report
    ]
  end
  role :reports_view do
    has_permission_on [:report],
      :to=>[
      :index,
      :course_batch_details,
      :course_batch_details_csv,
      :batch_details,
      :batch_details_csv,
      :batch_students,
      :batch_students_csv,
      :course_students,
      :course_students_csv,
      :students_all,
      :students_all_csv,
      :employees,
      :employees_csv,
      :former_students,
      :former_students_csv,
      :former_employees,
      :former_employees_csv,
      :subject_details,
      :list_batches,
      :subject_details_csv,
      :employee_subject_association,
      :employee_subject_association_csv,
      :employee_payroll_details,
      :employee_payroll_details_csv,
      :exam_schedule_details,
      :batch_list,
      :exam_schedule_details_csv,
      :fee_collection_details,
      :fee_collection_details_csv,
      :batch_details_all,
      :batch_details_all_csv,
      :course_fee_defaulters,
      :course_fee_defaulters_csv,
      :batch_fee_defaulters,
      :batch_fee_defaulters_csv,
      :students_fee_defaulters,
      :students_fee_defaulters_csv,
      :batch_fee_collections,
      :batch_fee_collections_csv,
      :student_wise_fee_defaulters,
      :student_wise_fee_defaulters_csv,
      :student_wise_fee_collections,
      :student_wise_fee_collections_csv,
      :csv_reports,
      :csv_report_download,
      :search_student,
      :search_ajax,
      :student_fees_headwise_report,
      :fees_head_wise_report,
      :batch_fees_headwise_report,
      :batch_head_wise_fees_csv,
      :fee_collection_head_wise_report,
      :update_fees_collections,
      :fee_collection_head_wise_report_csv
    ]
  end
  role :timetable_track do
    has_permission_on [:timetable_tracker],
      :to=>[
      :index,
      :class_timetable_swap,
      :batch_timetable,
      :list_employees,
      :timetable_swap,
      :timetable_swap_from,
      :timetable_swap_delete,
      :swaped_timetable_report,
      :employee_report_details,
      :swaped_timetable_report_csv,
    ]
  end
end

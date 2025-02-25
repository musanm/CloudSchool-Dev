ActionController::Routing::Routes.draw do |map|


  map.resources :attendance_messsages
  map.resources :bank_details
  map.resources :reporting_times

  map.resources :attach_signatures
 
  map.resources :term_exams


  map.resources :student_roll_number, :member => {:view_batches => [:get,:post], :create_roll_numbers => [:get,:post],  :update_roll_numbers => [:get,:post],  :edit_roll_numbers => [:get,:post]}
  map.resources :grading_levels
  map.resources :ranking_levels, :collection => {:create_ranking_level=>[:get,:post], :edit_ranking_level=>[:get,:post], :update_ranking_level=>[:get,:post], :delete_ranking_level=>[:get,:post], :ranking_level_cancel=>[:get,:post], :change_priority=>[:get,:post]}
  map.resources :class_designations
  map.resources :class_timings, :except => [:index, :show]
  map.resources :class_timing_sets,
    :member => {:new_class_timings => [:post],:create_class_timings => [:post],:edit_class_timings => [:post],:update_class_timings => [:post],:delete_class_timings => [:post,:delete]},
    :collection => {:change_default_class_timing_set=>[:get,:post],:new_batch_class_timing_set => [:get],:list_batches => [:post],:add_batch => [:post]}
  map.resources :subjects
  map.resources :attendances, :collection=>{:daily_register=>:get,:subject_wise_register=>:get,:quick_attendance=>:get}
  map.resources :employee_attendances
  map.resources :attendance_reports,:collection=>{:report_pdf=>[:get],:send_sms_to_all_students=>[:get],:in_out_attendance=>[:get], :employee_in_out_attendance=>[:get], :get_employee_z_report=>[:get], :employee_in_out_attendance_pdf_report => [:get], :individual_employee_in_out_attendance => [:get], :get_in_out_attendance_report=>[:get], :get_in_out_attendance_pdf_report=>[:get],:filter_report_pdf=>[:get],:day_wise_report => [:get,:post],:day_wise_report_filter_by_course => [:get,:post],:daily_report_batch_wise => [:get,:post]}
  map.resources :cce_exam_categories
  map.resources :assessment_scores,:collection=>{:exam_fa_groups=>[:get],:observation_groups=>[:get]}
  map.resources :cce_settings,:collection=>{:basic=>[:get],:scholastic=>[:get],:co_scholastic=>[:get]}
  map.resources :scheduled_jobs,:except => [:show]
  map.resources :fa_groups,:collection=>{:assign_fa_groups=>[:get,:post],:new_fa_criteria=>[:get,:post],:create_fa_criteria=>[:get,:post],:edit_fa_criteria=>[:get,:post],:update_fa_criteria=>[:get,:post],:destroy_fa_criteria=>[:post],:reorder=>[:get,:post]},
    :member=>{:edit_criteria_formula=>[:get,:post,:put]}

  map.resources :fa_criterias do |fa|
    fa.resources :descriptive_indicators
  end
  map.resources :observations do |obs|
    obs.resources :descriptive_indicators
  end
  map.resources :observation_groups,:member=>{:new_observation=>[:get,:post],:create_observation=>[:get,:post],:edit_observation=>[:get,:post],:update_observation=>[:get,:post],:destroy_observation=>[:post],:reorder=>[:get,:post]},:collection=>{:assign_courses=>[:get,:post],:set_observation_group=>[:get,:post]}
  map.resources :cce_weightages,:member=>{:assign_courses=>[:get,:post]},:collection=>{:assign_weightages=>[:get,:post]}
  map.resources :cce_grade_sets, :member=>{:new_grade=>[:get,:post],:edit_grade=>[:get,:post],:update_grade=>[:get,:post],:destroy_grade=>[:post]}

  map.feed 'courses/manage_course', :controller => 'courses' ,:action=>'manage_course'
  map.feed 'courses/manage_batches', :controller => 'courses' ,:action=>'manage_batches'
  map.resources :courses, :collection => {:grouped_batches=>[:get,:post],:create_batch_group=>[:get,:post],:edit_batch_group=>[:get,:post],:update_batch_group=>[:get,:post],:delete_batch_group=>[:get,:post],:assign_subject_amount => [:get,:post],:edit_subject_amount => [:get,:post],:destroy_subject_amount => [:get,:post]} do |course|
    course.resources :batches
  end

  map.resources :batches,:only => [], :member=>{:batch_summary=>[:get,:post]},:collection=>{:batches_ajax=>[:get]} do |batch|
    batch.resources :exam_groups
    batch.resources :elective_groups, :as => :electives, :member => {:new_elective_subject => [:get, :post], :create_elective_subject => [:get,:post], :edit_elective_subject => [:get, :post, :put], :update_elective_subject => [:get, :post, :put]}
  end

  map.resources :exam_groups do |exam_group|
    exam_group.resources :exams, :member => { :save_scores => :post }
  end

  map.resources :buildings do |building|
    building.resources :classrooms, :except => [:index]
  end
  map.resources :classrooms
  map.resources :classroom_allocations, :collection=>{:weekly_allocation=>:get, :render_classrooms => :get, :display_rooms => :get, :date_specific_allocation => :get, :update_allocation_entries => :get, :override_allocations => :get,:delete_allocation => :get, :find_allocations => :get}

  map.resources :icse_settings,:collection=>{:new_icse_exam_category=>:get,:create_icse_exam_category=>:post,:icse_exam_categories=>:get,:edit_icse_exam_category=>:get,:update_icse_exam_category=>:post,:destroy_icse_exam_category=>[:get,:post],:icse_weightages=>:get,:new_icse_weightage=>:get,:create_icse_weightage=>:post,:edit_icse_weightage=>:get,:update_icse_weightage=>:post,:destroy_icse_weightage=>[:get,:post],:assign_icse_weightages=>:get,:select_subjects=>:get,:select_icse_weightages=>:get,:update_subject_weightages=>:post,:internal_assessment_groups=>:get,:new_ia_group=>:get,:create_ia_group=>:post,:update_ia_group=>:post,:destroy_ia_group=>:get,:assign_ia_groups=>:get,:ia_group_subjects=>:get,:select_ia_groups=>:get,:update_subject_ia_groups=>:post},:member=>{:edit_ia_group=>:get}
  map.resources :ia_scores,:collection=>{:update_ia_score=>:post}
  map.resources :icse_reports,:collection=>{:index=>:get,:generate_reports=>[:get,:post],:student_wise_report=>[:get,:post],:student_report=>:post,:student_report_pdf=>:get,:student_transcript=>[:get,:post],:subject_wise_report=>[:get,:post],:list_batches=>:get,:list_subjects=>:get,:list_exam_groups=>:get,:subject_wise_generated_report=>[:get,:post],:internal_and_external_mark_pdf=>:get,:detailed_internal_and_external_mark_pdf=>:get,:internal_and_external_mark_csv=>:get,:detailed_internal_and_external_mark_csv=>:get,:consolidated_report=>:get,:consolidated_generated_report=>[:get,:post],:consolidated_report_csv=>[:get,:post],:student_report_csv=>:get,:batches_ajax=>:get}
  map.root :controller => 'user', :action => 'login'

  map.fa_scores 'assessment_scores/exam/:exam_id/fa_group/:fa_group_id', :controller=>'assessment_scores',:action=>'fa_scores'
  map.observation_scores 'assessment_scores/batch/:batch_id/observation_group/:observation_group_id', :controller=>'assessment_scores',:action=>'observation_scores'
  map.scheduled_task 'scheduled_jobs/:job_object/:job_type',:controller => "scheduled_jobs",:action => "index"
  map.scheduled_task_object 'scheduled_jobs/:job_object',:controller => "scheduled_jobs",:action => "index"

  map.ia_scores 'ia_scores/exam/:exam_id/ia_scores', :controller=>'ia_scores',:action=>'ia_scores'

  map.namespace(:api) do |api|
    api.resources :attendances
    api.resources :employee_attendances
    api.resources :courses
    api.resources :batches
    api.resources :schools
    api.resources :students,:member => {:fee_dues => :get,:upload_photo => [:post]},:collection => {:fee_dues_profile => :get,:attendance_profile => :get,:exam_report_profile => :get,:student_structure => :get}
    api.resources :employees,:member => {:upload_photo => [:post]},:collection => {:leave_profile => :get,:employee_structure => :get}
    api.resources :employee_departments
    api.resources :finance_transactions
    api.resources :users
    api.resources :news
    api.resources :reminders
    api.resources :subjects
    api.resources :student_categories
    api.resources :events
    api.resources :employee_leave_types
    api.resources :payroll_categories
    api.resources :timetables
    api.resources :exam_groups
    api.resources :exam_scores
    api.resources :grading_levels
    api.resources :employee_grades
    api.resources :employee_positions
    api.resources :employee_categories
    api.resources :biometric_informations
    api.resources :student_attendances,:member => { :time_status => :post }
  end
  #  map.connect ":class/:id/:attachment/image", :action => "paperclip_attachment", :controller => "user"
  map.connect 'reports/:action', :controller=>:report
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action'
  map.connect ':controller/:action/:id/:id2'
  map.connect ':controller/:action/:id.:format'

end
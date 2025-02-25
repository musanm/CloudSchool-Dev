
FedenaEmailAlert.make do
  alert(:student_creation,:student,:after_create,nil,nil,nil,nil)do
    to(:recipient=>"student",
      :to=>Proc.new{(is_email_enabled)?instance_eval("email.to_s.zip(first_name)"):[]},
      :message=>["full_name","user.school_name","admission_no"],
      :subject=>["full_name","user.school_name"],
      :stud_name=>Proc.new{},
      :first_name=>Proc.new{instance_eval("user.first_name")},
      :footer=>["user.school_details"])
  end
  alert(:transfer_batch,:student,:after_update,nil,nil,Proc.new{"mail_value"},"batch_id") do
    to(:recipient=>"parent",
      :to=>Proc.new{is_email_enabled ?instance_eval("immediate_contact.present?")?instance_eval("immediate_contact.email.to_s.zip(immediate_contact.first_name)"):[]:[]},

      :message=>["immediate_contact.full_name","full_name","admission_no","old_batch","new_batch"],
      :subject=>["full_name","user.school_name"],
      :stud_name=>Proc.new{},
      :footer=>["user.school_details"])


    to(:recipient=>"student",
      :to=>Proc.new{(is_email_enabled)?instance_eval("email.to_s.zip(first_name)"):[]},

      :message=>["full_name","admission_no","old_batch","new_batch"],
      :subject=>["full_name","user.school_name"],
      :stud_name=>Proc.new{},
      :footer=>["user.school_details"])
  end

  alert(:poll_creation,:poll_member,:after_create,"fedena_poll",nil,nil,nil) do
    to(
      :recipient=>"members",
      :to=>Proc.new{poll_member_emails},
      :message=>["poll_question.title","poll_question.poll_creator.school_name"],
      :subject=>["poll_question.title","poll_question.poll_creator.school_name"],
      :stud_name=>Proc.new{},
      :footer=>["poll_question.poll_creator.school_details"]

    )
  end
  alert(:parent_creation,:student,:after_update,nil,nil,Proc.new{immediate_contact_id!=nil},"immediate_contact_id") do
    to(
      :recipient=>"parent",
      :to=>Proc.new{(is_email_enabled? and immediate_contact.email.present?) ? (immediate_contact.email.to_s.zip(immediate_contact.first_name)):[]},
      :subject=>["full_name","user.school_name"],
      :message=>["full_name","user.school_name","immediate_contact.user.username"],
      :stud_name=>Proc.new{},
      :footer=>["user.school_details"]
    )
  end

  alert(:examination_schedule_publishing,:exam_group,:after_update,nil,nil,Proc.new{is_published==true},"is_published") do
    to(
      :recipient=>"student",
      :to=>Proc.new{batch.students.select{|s| s.is_email_enabled?}.empty?? []: instance_eval("batch.students.select{|s| s.is_email_enabled}.collect(&:email).zip(batch.students.select{|s| s.is_email_enabled}.collect(&:first_name))")},

      :stud_name=>Proc.new{},
      :message=>["school_name","name"],
      :subject=>["school_name"],
      :footer=>["school_details"]
    )

    to(
      :recipient=>"parent",
      :to=>Proc.new{parent_email},

      :stud_name=>Proc.new{student_parent_email},
      :message=>["school_name","name"],
      :subject=>["school_name"],
      :footer=>["school_details"]
    )
  end

  alert(:examination_result_publishing,:exam_group,:after_update,nil,nil,Proc.new{result_published==true},"result_published") do
    to(
      :recipient=>"student",
      :to=>Proc.new{batch.students.select{|s| s.is_email_enabled?}.empty?? []: instance_eval("batch.students.select{|s| s.is_email_enabled}.collect(&:email).zip(batch.students.select{|s| s.is_email_enabled}.collect(&:first_name))")},

      :stud_name=>Proc.new{},
      :message=>["name","school_name"],
      :subject=>["name"],
      :footer=>["school_details"])

    to(
      :recipient=>"parent",
      :to=>Proc.new{parent_email},

      :stud_name=>Proc.new{student_parent_email},
      :message=>["school_name","name"],
      :subject=>["name"],
      :footer=>["school_details"])
  end

  alert(:daily_wise_attendance_registration,:attendance,:after_create,nil,nil,nil,nil) do
    to(
      :recipient=>"student",
      :to=>Proc.new{student.is_email_enabled??instance_eval("student.email.to_s.zip(student.first_name)"):[]},
      :message=>["student.full_name","student.admission_no","reason","month_dates","leave_info"],
      :subject=>["student.full_name","month_dates"],
      :stud_name=>Proc.new{},
      :footer=>["student.user.school_details"]

    )
    to(
      :recipient=>"parent",
      :to=>Proc.new{(student.immediate_contact.present? and student.is_email_enabled?)?instance_eval("student.immediate_contact.email.to_s.zip(student.immediate_contact.first_name)"):[]},
      :message=>["student.full_name","student.admission_no","reason","month_dates","leave_info"],
      :subject=>["student.full_name","month_dates"],
      :stud_name=>Proc.new{},
      :footer=>["student.user.school_details"]
    )
  end


  alert(:employee_creation,:user,:after_create,nil,Proc.new{employee==true},nil,nil) do
    to(

      :recipient=>"employee",
      :to=>Proc.new{email.to_s.zip(first_name)},
      :message=>["full_name","school_name","username"],
      :stud_name=>Proc.new{},
      :subject=>["full_name","school_name"],
      :footer=>["school_details"]
    )
  end

  alert(:fee_collection_creation,:finance_fee,:after_create,nil,nil,nil,nil) do
    to(
      :recipient=>"student",
      :to=>Proc.new{student.is_email_enabled??instance_eval("student.email.to_s.zip(student.first_name)"):[]},
      :stud_name=>Proc.new{},
      :message=>["finance_fee_collection.name","student.full_name","due_date","student.user.school_name"],
      :subject=>["finance_fee_collection.name","student.user.school_name"],
      :footer=>["student.user.school_details"]

    )
    to(
      :recipient=>"parent",
      :to=>Proc.new{(student.immediate_contact.present? and student.is_email_enabled?)?instance_eval("student.immediate_contact.email.to_s.zip(student.immediate_contact.first_name)"):[]},
      :message=>["finance_fee_collection.name","student.full_name","due_date","student.user.school_name"],
      :subject=>["finance_fee_collection.name","student.user.school_name"],
      :stud_name=>Proc.new{},
      :footer=>["student.user.school_details"]
    )
  end

  alert(:fee_submission,:finance_transaction,:after_create,nil,Proc.new{finance_type=="FinanceFee"},nil,nil) do
    to(
      :recipient=>"student",
      :to=>Proc.new{payee.is_email_enabled??instance_eval("payee.email.to_s.zip(payee.first_name)"):[]},
      :stud_name=>Proc.new{},
      :message=>["currency_name","date_of_transaction","amount.to_f","finance.finance_fee_collection.name"],
      :subject=>["currency_name","amount.to_f"],
      :footer=>["payee.user.school_details"]
    )
    to(
      :recipient=>"parent",
      :to=>Proc.new{(payee.immediate_contact.present? and payee.is_email_enabled) ? instance_eval("payee.immediate_contact.email.to_s.zip(payee.immediate_contact.first_name)"):[]},
      :stud_name=>Proc.new{},
      :message=>["currency_name","date_of_transaction","amount.to_f","finance.finance_fee_collection.name"],
      :subject=>["currency_name","amount.to_f"],
      :footer=>["payee.user.school_details"]
    )
  end

  alert(:leave_creation,:apply_leave,:after_create,nil,nil,nil,nil) do
    to(
      :recipient=>"employee",
      :to=>Proc.new{employee.reporting_manager.email.to_s.zip(employee.reporting_manager.first_name)},
      :message=>["employee.full_name","employee.employee_number","leave_days","reason"],
      :subject=>["employee.full_name"],
      :stud_name=>Proc.new{},
      :footer=>["employee.user.school_details"]
    )

  end
  alert(:leave_approval,:apply_leave,:after_update,nil,nil,nil,"approved") do
    to(
      :recipient=>"employee",
      :to=>Proc.new{employee.email.to_s.zip(employee.first_name)},

      :message=>["reason","leave_days","leave_status"],
      :subject=>["leave_status","leave_days"],
      :stud_name=>Proc.new{},
      :footer=>["employee.user.school_details"]
    )
  end

  alert(:common_event_creation,:event,:after_create,nil,Proc.new{is_common==true and is_exam==false},nil,nil) do
    to(
      :recipient=>"members",
      :to=>Proc.new{event_member_emails},
      :message=>["title","event_days"],
      :stud_name=>Proc.new{},
      :subject=>["title","school_name","event_days"],
      :footer=>["school_details"]
    )

  end

  alert(:event_creation_for_batch,:batch_event,:after_create,nil,Proc.new{event.is_exam==false and event.is_due==false},nil,nil) do
    to(
      :recipient=>"student",
      :to=>Proc.new{batch_event_emails},
      :message=>["event.title","event.event_days"],
      :stud_name=>Proc.new{},
      :subject=>["event.title","event.school_name","event.event_days"],
      :footer=>["event.school_details"]
    )
    to(
      :recipient=>"parent",
      :to=>Proc.new{parent_event_emails},
      :message=>["event.title","event.event_days"],
      :stud_name=>Proc.new{},
      :subject=>["event.title","event.school_name","event.event_days"],
      :footer=>["event.school_details"]
    )
  end

  alert(:event_creation_for_employee,:employee_department_event,:after_create,nil,nil,nil,nil) do
    to(
      :recipient=>"employee",
      :to=>Proc.new{employee_event_emails},
      :message=>["event.title","event.event_days"],
      :subject=>["event.title","event.school_name","event.event_days"],
      :stud_name=>Proc.new{},
      :footer=>["event.school_details"]

    )

  end

  alert(:subject_wise_attendance_registration,:subject_leave,:after_create,nil,nil,nil,nil) do
    to(
      :recipient=>"student",
      :to=>Proc.new{student.is_email_enabled??instance_eval("student.email.to_s.zip(student.first_name)"):[]},
      :message=>["student.full_name","student.admission_no","reason","subject.name","class_timing.name"],
      :subject=>["student.full_name","month_date"],
      :stud_name=>Proc.new{},
      :footer=>["student.user.school_details"]
    )
    to(
      :recipient=>"parent",
      :to=>Proc.new{student.immediate_contact.present??instance_eval("student.immediate_contact.email.to_s.zip(student.immediate_contact.first_name)"):[]},
      :message=>["student.full_name","student.admission_no","reason","subject.name","class_timing.name"],
      :subject=>["student.full_name","month_date"],
      :stud_name=>Proc.new{},
      :footer=>["student.user.school_details"]

    )
  end
end

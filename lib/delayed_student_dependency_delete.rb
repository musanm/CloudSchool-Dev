class DelayedStudentDependencyDelete < Struct.new(:student_id)
  def perform
    student = Student.find(student_id)
    msg = student.student_dependencies_list
    delete_student_dependency(student)
    log = StudentDeletionLog.new
    log = StudentDeletionLog.new
    log.user_id = @current_user.id
    log.student_id = student.id
    log.dependency_messages = msg
    log.stud_adm_no = student.admission_no
    log.save
    unless student.all_siblings.present?
      student.guardians.destroy_all
    end
    student.user.destroy
    student.destroy
  end

  def delete_student_dependency(student)
    delete_core_dependencies(student)
    delete_plugin_dependencies(student)
  end

  def delete_core_dependencies(student)
    dependency_arr = [:attendances, :subject_leaves, :finance_transactions, :batch_students, :finance_fees, :exam_scores, :students_subjects,:student_discounts,:student_particulars]
    dependency_arr.each do |d|
      student.send(d).destroy_all
    end
  end

  def delete_plugin_dependencies(student)
    FedenaPlugin::AVAILABLE_MODULES.each do |mod|
      modu = mod[:name].camelize.constantize
      if modu.respond_to?("dependency_delete")
        modu.send("dependency_delete", student)
      end
    end
  end 
end
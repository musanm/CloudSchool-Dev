class AssignmentsController < ApplicationController
  before_filter :login_required
  filter_access_to :all,:except=>:show
  filter_access_to :show,:attribute_check=>true
  
  def index
    @current_user = current_user
    if    @current_user.employee?
      @subjects = current_user.employee_record.subjects.active
      @subjects.reject! {|s| !s.batch.is_active}
    elsif    @current_user.student?
      student=current_user.student_record
      @assignments = Assignment.active.for_student student.id
      @assignments=@assignments.select{|assignment| assignment.subject.batch_id==student.batch_id}
    end
  end


  def subject_assignments

    @subject =Subject.find_by_id params[:subject_id]
    unless @subject.nil?
      employee_id = current_user.employee_record.id
      @assignments =Assignment.paginate  :conditions=>"subject_id=#{@subject.id} and employee_id=#{employee_id}",:order=>"duedate desc", :page=>params[:page]
    end
    render(:update) do |page|
      page.replace_html 'subject_assignments_list', :partial=>'subject_assignments'
    end
  end


  def new
    if current_user.employee?
      @subjects = current_user.employee_record.subjects
      
      @subjects.reject! {|s| !s.batch.is_active}
      @assignment= Assignment.new
      unless params[:id].nil?
        subject = Subject.find_by_id(params[:id])
        employeeassociated = EmployeesSubject.find_by_subject_id_and_employee_id( subject.id,current_user.employee_record.id)
        unless employeeassociated.nil?
          if subject.elective_group_id.nil?
            @students = subject.batch.students
          else
            assigned_students = StudentsSubject.find_all_by_subject_id(subject.id)
            @students = assigned_students.map{|s| Student.find s}
          end
          @assignment = subject.assignments.build
        end
      end
    end
  end


  def subjects_students_list
    @subject = Subject.find_by_id params[:subject_id]
    unless @subject.nil?
      if @subject.elective_group_id.nil?
        @students = @subject.batch.students
      else
        assigned_students = StudentsSubject.find_all_by_subject_id(@subject.id)
        @students = assigned_students.map{|s| s.student}
        @students=@students.compact
      end
    end
    render(:update) do |page|
      page.replace_html 'subjects_student_list', :partial=>"subjects_student_list"
    end
  end


  def assignment_student_list
    #List the students of the assignment based on their Status of their assignment
    @assignment = Assignment.active.find_by_id params[:id]
    unless @assignment.nil?
      @status = params[:status]
      if @status == "assigned"
        assigned_students= @assignment.student_list.split(",")
        @students=[]
        assigned_students.each do |assigned_student|
          s = Student.find_by_id assigned_student
          if s.nil?
            s = ArchivedStudent.find_by_former_id assigned_student
          end
          @students << s if s.present?
        end
        @students = @students.sort_by{|s| s.full_name}
      elsif @status == "answered"
        assigned_students= @assignment.student_list.split(",")
        @answers = @assignment.assignment_answers.find_all_by_student_id(assigned_students)
        @answers  = @answers.sort_by{|a| a.updated_at}
        @students = @answers.map{|a| a.student }
      elsif @status== "pending"
        answers = @assignment.assignment_answers
        answered_students = answers.map{|a| a.student_id.to_s }
        assigned_students= @assignment.student_list.split(",")
        pending_students = assigned_students - answered_students
        @students = []
        pending_students.each do |pending_student|
          s = Student.find_by_id pending_student
          if s.nil?
            s=ArchivedStudent.find_by_former_id pending_student
          end
          @students << s if s.present?
        end
        @students = @students.sort_by{|s| s.full_name}
      end
      render(:update) do |page|
        page.replace_html 'student_list', :partial=>'student_list'
      end
    else
      flash[:notice]=t('flash_msg4')
      redirect_to :controller=>:user ,:action=>:dashboard
    end
  end

  def create
    student_ids = params[:assignment][:student_ids]
    params[:assignment].delete(:student_ids)
    @subject = Subject.find_by_id(params[:assignment][:subject_id])
    @assignment = Assignment.new(params[:assignment])
    @assignment.student_list = student_ids.join(",") unless student_ids.nil?
    p @assignment.student_list
    @assignment.employee = current_user.employee_record
    unless @subject.nil?
      if @assignment.save
        flash[:notice] = "#{t('new_assignment_sucessfuly_created')}"
        redirect_to :action=>:index
      else
        if current_user.employee?
          @subjects = current_user.employee_record.subjects
        
          @subjects.reject! {|s| !s.batch.is_active?}
          @students = @subject.batch.students
        end
        render :action=>:new
      end
    else
      unless @assignment.save
        @subjects = current_user.employee_record.subjects
        render :action=>:new
      end
    end
  end

  def show
    @assignment  = Assignment.active.find(params[:id])
    unless @assignment.nil?
      @current_user = current_user
      @assignment_answers = @assignment.assignment_answers
      assigned_students= @assignment.student_list.split(",")
      @students_assigned_count = assigned_students.count
      @answered_count = @assignment_answers.find_all_by_student_id(assigned_students).count
      @pending_count =     @students_assigned_count  -  @answered_count
      @assignment_answers = AssignmentAnswer.find_all_by_student_id_and_assignment_id(current_user.student_record.id,@assignment.id) if current_user.student?
    else
      flash[:notice]=t('flash_msg4')
      redirect_to :controller=>:user ,:action=>:dashboard
    end
  end

  def edit
    @assignment  = Assignment.active.find(params[:id])
    unless @assignment.nil?
      if @assignment.employee_id==current_user.employee_record.id
        load_data
      else
        flash[:notice] ="#{t('you_cannot_edit_this_assignment')}"
        redirect_to assignments_path
      end
    else
      flash[:notice]=t('flash_msg4')
      redirect_to :controller=>:user ,:action=>:dashboard
    end
  end
  def update
    @assignment = Assignment.find_by_id(params[:id])
    unless @assignment.nil?
      student_ids = params[:assignment][:student_ids]
      params[:assignment].delete(:student_ids)
      unless student_ids.nil?
        @assignment.student_list = student_ids.join(",")
      else
        @assignment.student_list = nil
      end
      if  @assignment.update_attributes(params[:assignment])
        flash[:notice]="#{t('assignment_details_updated')}"
        redirect_to @assignment
      else
        load_data
        render :edit ,:id=>params[:id]
      end
    else
      flash[:notice]=t('flash_msg4')
      redirect_to :controller=>:user ,:action=>:dashboard
    end
  end

  def destroy
    @assignment = Assignment.find_by_id(params[:id])
    if (current_user.admin?) or (@assignment.employee_id == current_user.employee_record.id)
      @assignment.destroy
      flash[:notice] = "#{t('assignment_sucessfully_deleted')}"
      redirect_to assignments_path
    else
      flash[:notice] = "#{t('you_do_not_have_permission_to_delete_this_assignment')}"
      redirect_to edit_assignment_path(@assignment)
    end

  end
  def download_attachment
    #download the  attached file
    @assignment =Assignment.active.find params[:id]
    unless @assignment.nil?
      if @assignment.download_allowed_for(current_user)
        send_file  @assignment.attachment.path , :type=>@assignment.attachment.content_type
      else
        flash[:notice] = "#{t('you_are_not_allowed_to_download_that_file')}"
        redirect_to :controller=>:assignments
      end
    else
      flash[:notice]=t('flash_msg4')
      redirect_to :controller=>:user ,:action=>:dashboard
    end
  end

  def load_data
    @subject = @assignment.subject
    @students=[]
    unless @subject.nil?
      if @subject.elective_group_id.nil?
        @subject.batch.students.each do |s|
          @students << s
        end
      else
        students=@subject.students.find_all_by_batch_id(@subject.batch_id)
        students.each do |s|
          @students << s
        end
      end
    end
    @assigned_students = []
    unless @assignment.student_list.nil?
      @assignment.student_list.split(",").each do |s|
        student = Student.find_by_id s
        if student.nil?
          student=ArchivedStudent.find_by_former_id s
          student.id= student.former_id
        end
        unless @students.include?(student) or @assignment.assignment_answers.find_by_student_id(student.id).nil?
          @students << student
        end
        @assigned_students << student
      end
    end
    if current_user.employee?
      @subjects = current_user.employee_record.subjects

      @subjects.reject! {|s| !s.batch.is_active}
    end
  end

end

#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class BatchesController < ApplicationController
  before_filter :init_data,:except=>[:assign_tutor,:update_employees,:assign_employee,:remove_employee,:batches_ajax,:batch_summary]
  before_filter :login_required
  filter_access_to :all
  def index
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
    end
  end

  def new
    @batch = @course.batches.build
  end

  def create
    @batch = @course.batches.build(params[:batch])
    
    if @batch.save
      flash[:notice] = "#{t('flash1')}"
      unless params[:import_subjects].nil?
        msg = []
        msg << "<ol>"
        course_id = @batch.course_id
        @previous_batch = Batch.find(:first,:order=>'id desc', :conditions=>"batches.id < '#{@batch.id }' AND batches.is_deleted = 0 AND course_id = ' #{course_id }'",:joins=>"INNER JOIN subjects ON subjects.batch_id = batches.id  AND subjects.is_deleted = 0")
        unless @previous_batch.blank?
          subjects = Subject.find_all_by_batch_id(@previous_batch.id,:conditions=>'is_deleted=false')
          subjects.each do |subject|
            if subject.elective_group_id.nil?
              Subject.create(:name=>subject.name,:code=>subject.code,:batch_id=>@batch.id,:no_exams=>subject.no_exams,
                :max_weekly_classes=>subject.max_weekly_classes,:elective_group_id=>subject.elective_group_id,:credit_hours=>subject.credit_hours,:is_deleted=>false)
            else
              elect_group_exists = ElectiveGroup.find_by_name_and_batch_id(ElectiveGroup.find(subject.elective_group_id).name,@batch.id)
              if elect_group_exists.nil?
                elect_group = ElectiveGroup.create(:name=>ElectiveGroup.find(subject.elective_group_id).name,
                  :batch_id=>@batch.id,:is_deleted=>false)
                Subject.create(:name=>subject.name,:code=>subject.code,:batch_id=>@batch.id,:no_exams=>subject.no_exams,
                  :max_weekly_classes=>subject.max_weekly_classes,:elective_group_id=>elect_group.id,:credit_hours=>subject.credit_hours,:is_deleted=>false)
              else
                Subject.create(:name=>subject.name,:code=>subject.code,:batch_id=>@batch.id,:no_exams=>subject.no_exams,
                  :max_weekly_classes=>subject.max_weekly_classes,:elective_group_id=>elect_group_exists.id,:credit_hours=>subject.credit_hours,:is_deleted=>false)
              end
            end
            msg << "<li>#{subject.name}</li>"
          end
          msg << "</ol>"
        else
          msg = nil
          flash[:no_subject_error] = "#{t('flash7')}"
        end
      end
      flash[:subject_import] = msg unless msg.nil?
      err = ""
      err1 = "<p style = 'font-size:16px'>#{t('following_pblm_occured_while_saving_the_batch')}</p>"
      err1 += "<ul>"
      unless params[:import_fees].nil?
        fee_msg = []
        course_id = @batch.course_id
        @previous_batch = Batch.find(:first,:order=>'id desc', :conditions=>"batches.id < '#{@batch.id }' AND batches.is_deleted = 0 AND course_id = ' #{course_id }'",:joins=>"INNER JOIN category_batches ON category_batches.batch_id = batches.id  INNER JOIN finance_fee_categories on finance_fee_categories.id=category_batches.finance_fee_category_id AND finance_fee_categories.is_deleted = 0 AND is_master= 1")
        unless @previous_batch.blank?
          fee_msg << "<ol>"
          categories = CategoryBatch.find_all_by_batch_id(@previous_batch.id)

          categories.each do |c|
            
            particulars = FinanceFeeParticular.find(:all,:conditions=>"(receiver_type='Batch' or receiver_type='StudentCategory') and (batch_id=#{@previous_batch.id}) and (finance_fee_category_id=#{c.finance_fee_category_id})")
            
            #particulars = c.finance_fee_category.fee_particulars.all(:conditions=>"receiver_type='Batch' or receiver_type='StudentCategory'")
            particulars.reject!{|pt|pt.deleted_category}
            fee_discounts = FeeDiscount.find(:all,:conditions=>"(receiver_type='Batch' or receiver_type='StudentCategory') and (batch_id=#{@previous_batch.id}) and (finance_fee_category_id=#{c.finance_fee_category_id})")
            
            #category_discounts = StudentCategoryFeeDiscount.find_all_by_finance_fee_category_id(c.id)
            unless particulars.blank? and fee_discounts.blank?
              new_category = CategoryBatch.new(:batch_id=>@batch.id,:finance_fee_category_id=>c.finance_fee_category_id)
              if new_category.save
                fee_msg << "<li>#{c.finance_fee_category.name}</li>"
                particulars.each do |p|
                  receiver_id=p.receiver_type=='Batch' ? @batch.id : p.receiver_id
                  new_particular = FinanceFeeParticular.new(:name=>p.name,:description=>p.description,:amount=>p.amount,\
                      :batch_id=>@batch.id,:receiver_id=>receiver_id,:receiver_type=>p.receiver_type)
                  new_particular.finance_fee_category_id = new_category.finance_fee_category_id
                  unless new_particular.save
                    err += "<li> #{t('particular')} #{p.name} #{t('import_failed')}.</li>"
                  end
                end
                fee_discounts.each do |disc|
                  discount_attributes = disc.attributes
                  discount_attributes.delete "type"
                  discount_attributes.delete "finance_fee_category_id"
                  discount_attributes.delete "batch_id"
                  discount_attributes['receiver_id']=@batch.id if disc.receiver_type=='Batch'
                  discount_attributes["batch_id"]= @batch.id
                  discount_attributes["finance_fee_category_id"]= new_category.finance_fee_category_id
                  unless FeeDiscount.create(discount_attributes)
                    err += "<li> #{t('discount ')} #{disc.name} #{t('import_failed')}.</li>"
                  end
                end
                #                category_discounts.each do |disc|
                #                  discount_attributes = disc.attributes
                #                  discount_attributes.delete "type"
                #                  discount_attributes.delete "finance_fee_category_id"
                #                  discount_attributes["finance_fee_category_id"]= new_category.id
                #                  unless StudentCategoryFeeDiscount.create(discount_attributes)
                #                    err += "<li>  #{t(' discount ')} #{disc.name} #{t(' import_failed')}.</li><br/>"
                #                  end
                #                end
              else

                err += "<li>  #{t('category')} #{c.finance_fee_category.name}1 #{t('import_failed')}.</li>"
              end
            else

              err += "<li>  #{t('category')} #{c.finance_fee_category.name}2 #{t('import_failed')}.</li>"

            end
          end
          fee_msg << "</ol>"
          @fee_import_error = false
          flash[:fees_import_error] =nil
        else
          flash[:fees_import_error] =t('no_fee_import_message')
          @fee_import_error = true
        end
      end
      err2 = "</ul>"
      flash[:warn_notice] =  err1 + err + err2 unless err.empty?
      flash[:fees_import] =  fee_msg unless fee_msg.nil?
      
      redirect_to [@course, @batch]
    else
      @grade_types=[]
      gpa = Configuration.find_by_config_key("GPA").config_value
      if gpa == "1"
        @grade_types << "GPA"
      end
      cwa = Configuration.find_by_config_key("CWA").config_value
      if cwa == "1"
        @grade_types << "CWA"
      end
      render 'new'
    end
  end

  def edit
  end

  def update
    if @batch.update_attributes(params[:batch])
      flash[:notice] = "#{t('flash2')}"
      redirect_to [@course, @batch]
    else
      render 'edit'
      #flash[:notice] ="#{t('flash3')}"
      #redirect_to  edit_course_batch_path(@course, @batch)
    end
  end

  def show
    @config=Configuration.find_by_config_key('StudentAttendanceType')
    if current_user.admin? or current_user.privileges.include?(Privilege.find_by_name('ManageCourseBatch'))
      @courses=Course.active
      if @batch.present?
        @tutors=@batch.employees
        @students = Student.active.paginate(:conditions=>["batch_id=?",@batch.id],:per_page=>20,:page=>params[:page])
        @student_count=@batch.students.active.count
        @batches=@batch.course.batches.active
      end
    elsif current_user.can_view_results?
      @batches=current_user.employee_record.batches
    end
  end

  def list_batches
    if current_user.admin? or current_user.privileges.include?(Privilege.find_by_name('ManageCourseBatch'))
      unless params[:course_id]==""
        course=Course.find(params[:course_id])
        @batches=course.batches.active
        render :update do |page|
          page.replace_html 'batch_area',:partial=>'list_batches'
          page.replace_html 'display_area', :partial => 'select_batch'
          page.replace_html 'batch_tutor_section', ''
          page.replace_html 'batch_mini_details', ''


        end
      else
        render :update do |page|
          page.replace_html 'batch_area',''
          page.replace_html 'display_area', :partial => 'select_batch'
          page.replace_html 'batch_tutor_section', ''
          page.replace_html 'batch_mini_details', ''
        end
      end
    end
  end

  def get_tutors
    if params[:batch_id].present?
      @batch=Batch.find(params[:batch_id])
      @tutors=@batch.employees
    end
    render :partial=>'batch_tutors'
  end

  def get_batch_span
    if params[:batch_id].present?
      @batch=Batch.find(params[:batch_id])
    end
    render :partial=>'batch_span'
  end

  def batch_summary
    if params[:batch_id].present?
      @batch=Batch.find(params[:batch_id])
      @course=@batch.course
      @requested_summary_id=params[:request_id].to_i
      case @requested_summary_id
      when 1
        @students = Student.active.paginate(:conditions=>["batch_id=?",@batch.id],:per_page=>20,:page=>params[:page],:order=>"first_name ASC")
        @student_count=@batch.students.active.count
        render :partial=>'students_summary'
      when 2
        @date = params[:date].nil? ? Date.today : params[:date]
        @students = Student.paginate(:per_page => 20,:page => params[:page],:joins => :attendances,:conditions => ["attendances.batch_id = ? and attendances.month_date = ?",params[:batch_id],@date])
        @absentees_count = Attendance.all(:joins => :student, :conditions => {:batch_id => @batch.id,:month_date => @date}).count
        @batch_students_count=@batch.students.count
        @present_students_count=@batch_students_count-@absentees_count
        @attendance_percentage=@batch_students_count == 0 ? 0 : ((@present_students_count * 100 ) / @batch_students_count)
        render :partial=>'attendance_summary'
      when 3
        @subjects_count=@batch.subjects.count
        @employees_count=@batch.employees_subjects.collect(&:employee_id).uniq.count
        tt_ids=@batch.time_table_class_timings.collect(&:timetable_id)
        @timetables=Timetable.all(:conditions=>["id in (?)",tt_ids],:order => "start_date DESC") if tt_ids.present?
        @timetable_id=params[:timetable_id]||@timetables.first.id if @timetables.present?
        if @timetable_id.present?
          @timetable_entries=TimetableEntry.find_all_by_batch_id_and_timetable_id(@batch.id,@timetable_id)
          @elective_subjects=ElectiveGroup.all(:select=>"elective_groups.*,subjects.id as sid,subjects.name as sname,employees.first_name as ename",:joins=>"LEFT OUTER JOIN `subjects` ON subjects.elective_group_id = elective_groups.id LEFT OUTER JOIN employees_subjects on employees_subjects.subject_id=subjects.id LEFT OUTER JOIN employees on employees_subjects.employee_id=employees.id", :conditions=>["elective_groups.batch_id = ? and subjects.is_deleted=false",@batch.id],:include=>[:subjects=>:employees_subjects])
          @elective_sub_counts=ElectiveGroup.count(:joins=>{:subjects=>:timetable_entries}, :conditions=>["elective_groups.batch_id=? and timetable_entries.timetable_id=?",@batch.id,@timetable_id],:group=>:elective_group_id)
          @grouped_elective_subjects=@elective_subjects.to_a.group_by{|s| s.id}
          @grouped_elective_employees=@elective_subjects.to_a.group_by{|s| s.ename}
          @subject_wise_normal=@batch.subject_wise_normal_subjects(@timetable_id)
          @employee_wise_normal=@batch.employee_wise_normal_subjects(@timetable_id)
          @elelctive_employees_hash=@batch.employee_wise_electives_timetable_assignments(@timetable_id)
        end
        unless params[:timetable_id].present?
          render :partial=>'subject_employee_summary'
        else
          unless params[:link_id].present?
            render :update do |page|
              page.replace_html 'exam_items' ,:partial=>'exam_items'
              page.replace_html 'highlight', :partial=>'subject_teacher_highlights'
            end
          else
            render :partial=>'exam_items',:link_id=>params[:link_id]
          end
        end
      when 4
        date=params[:date]||Date.today
        @date=date.to_date
        @tt_entries=@batch.fetch_timetable_summary(@date)
        @calender_events=@batch.fetch_activities_summary(@date)
        render :partial=>'timetable_activities_summary'
      when 5
        @exam_groups=ExamGroup.paginate(:select=>"exam_groups.*,min(exams.start_time) as min_start,max(exams.end_time) as max_end",:conditions=>["batch_id=?",@batch.id],:per_page=>20,:page=>params[:page],:joins=>:exams,:group=>:exam_group_id)
        @new_exams_count=@batch.exam_groups.count(:conditions=>["is_published=? and result_published=?",false,false])
        @published_exams_count=@batch.exam_groups.all(:select=>"exam_groups.*,min(exams.start_time) as min_start,max(exams.end_time) as max_end",:having=>["is_published=? and result_published = ? and min_start > ? and max_end > ?",true,false,Time.now,Time.now],:joins=>:exams,:group=>:exam_group_id).count
        @results_published_exams_count=@batch.exam_groups.count(:conditions=>["is_published=? and result_published=?",true,true])
        @ongoing_exams_count=@batch.exam_groups.all(:select=>"exam_groups.*,min(exams.start_time) as min_start,max(exams.end_time) as max_end",:having=>["is_published=? and result_published= ? and min_start < ? and max_end > ?",true,false,Time.now,Time.now],:joins=>:exams,:group=>:exam_group_id).count
        @finished_exams_count=@batch.exam_groups.all(:select=>"exam_groups.*,min(exams.start_time) as min_start,max(exams.end_time) as max_end",:having=>["is_published =? and result_published=?  and min_start < ? and max_end < ?",true,false,Time.now,Time.now],:joins=>:exams,:group=>:exam_group_id).count
        render :partial=>'examination_summary'
      else
      
      end
    else
      render :partial=>'select_batch'
    end
  end

  def tab_menu_items
    if params[:batch_id].present?
      @batch=Batch.find(params[:batch_id])
      @course=@batch.course
      render :partial=>'tab_menu_items'
    else
      render :text=>""
    end
  end

  def destroy
    if @batch.students.empty? and @batch.subjects.empty?
      @batch.inactivate
      flash[:notice] = "#{t('flash4')}"
      redirect_to @course
    else
      flash[:warn_notice] = "<p>#{t('batches.flash5')}</p>" unless @batch.students.empty?
      flash[:warn_notice] = "<p>#{t('batches.flash6')}</p>" unless @batch.subjects.empty?
      redirect_to [@course, @batch]
    end
  end

  def assign_tutor
    @batch = Batch.find_by_id(params[:id])
    if @batch.nil?
      page_not_found
    else
      @assigned_employee=@batch.employees
      @departments = EmployeeDepartment.ordered
    end
  end

  def update_employees
    @employees = Employee.find_all_by_employee_department_id(params[:department_id]).sort_by{|e| e.full_name.downcase}
    @batch = Batch.find_by_id(params[:batch_id])
    @assigned_employee=@batch.employees
    render :update do |page|
      page.replace_html 'employee-list', :partial => 'employee_list'
    end
  end

  def assign_employee
    @batch = Batch.find_by_id(params[:batch_id])
    @employees = Employee.find_all_by_employee_department_id(params[:department_id]).sort_by{|e| e.full_name.downcase}
    @batch.employee_ids=@batch.employee_ids << params[:id]
    @assigned_employee=@batch.employees
    render :update do |page|
      page.replace_html 'employee-list', :partial => 'employee_list'
      page.replace_html 'tutor-list', :partial => 'assigned_tutor_list'
      page.replace_html 'flash', :text=>"<p class='flash-msg'>#{t('tutor_assigned_successfully')}</p>"
    end
  end

  def remove_employee
    @batch = Batch.find_by_id(params[:batch_id])
    @employees = Employee.find_all_by_employee_department_id(params[:department_id]).sort_by{|e| e.full_name.downcase}
    @batch.employees.delete(Employee.find params[:id])
    @assigned_employee = @batch.employees
    render :update do |page|
      page.replace_html 'employee-list', :partial => 'employee_list'
      page.replace_html 'tutor-list', :partial => 'assigned_tutor_list'
      page.replace_html 'flash', :text=>"<p class='flash-msg'>#{t('tutor_removed_successfully')}</p>"
    end
  end

  def batches_ajax
    if request.xhr?
      @course = Course.find_by_id(params[:course_id]) unless params[:course_id].blank?
      @batches = @course.batches.active if @course
      if params[:type]=="list"
        render :partial=>"list"
      end
    end
  end
  private
  def init_data
    @batch = Batch.find_by_id params[:id] if ['show', 'edit', 'update', 'destroy'].include? action_name
    @course = Course.find_by_id params[:course_id]
  end
end
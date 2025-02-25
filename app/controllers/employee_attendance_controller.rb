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

class EmployeeAttendanceController < ApplicationController
  before_filter :login_required,:configuration_settings_for_hr
  before_filter :protect_leave_dashboard, :only => [:leaves]#, :employee_attendance_pdf]
  before_filter :protect_applied_leave, :only => [:own_leave_application, :cancel_application]
  before_filter :protect_manager_leave_application_view, :only => [:leave_application]
  before_filter :protect_leave_history, :only => [:leave_history,:update_leave_history]
  #    prawnto :prawn => {:left_margin => 25, :right_margin => 25}

  filter_access_to :all

  def add_leave_types
    @leave_types = EmployeeLeaveType.find(:all, :order => "name ASC",:conditions=>'status = 1')
    @inactive_leave_types = EmployeeLeaveType.find(:all, :order => "name ASC",:conditions=>'status = 0')
    @leave_type = EmployeeLeaveType.new(params[:leave_type])
    @employee = Employee.all
    if request.post? and @leave_type.save
      @employee.each do |e|
        EmployeeLeave.create( :employee_id => e.id, :employee_leave_type_id => @leave_type.id, :leave_count => @leave_type.max_leave_count, :reset_date => @leave_type.reset_date)
      end
      flash[:notice] = t('flash1')
      redirect_to :action => "add_leave_types"
    end
  end

  def edit_leave_types
    @leave_type = EmployeeLeaveType.find(params[:id])
    if request.post? and @leave_type.update_attributes(params[:leave_type])
      flash[:notice] = t('flash2')
      redirect_to :action => "add_leave_types"
    end
  end

  def delete_leave_types
    @leave_type = EmployeeLeaveType.find(params[:id])
    @attendance = EmployeeAttendance.find_all_by_employee_leave_type_id(@leave_type.id)
    @applied_leaves=ApplyLeave.find(:all,:conditions=>["employee_leave_types_id=?", @leave_type.id])
    @leave_count = EmployeeLeave.find_all_by_employee_leave_type_id(@leave_type.id)
    if @attendance.blank? and @applied_leaves.blank?
      @leave_type.delete
      @leave_count.each do |e|
        e.delete
      end
      flash[:notice] = t('flash3')
    else
      flash[:notice] = "#{t('flash13')}"
    end
    redirect_to :action => "add_leave_types"
    

  end

  def leave_reset_settings
    @auto_reset = Configuration.find_by_config_key('AutomaticLeaveReset')
    @reset_period = Configuration.find_by_config_key('LeaveResetPeriod')
    @last_reset = Configuration.find_by_config_key('LastAutoLeaveReset')
    @fin_start_date = Configuration.find_by_config_key('FinancialYearStartDate')
    if request.post?
      @auto_reset.update_attributes(:config_value=> params[:configuration][:automatic_leave_reset])
      @reset_period.update_attributes(:config_value=> params[:configuration][:leave_reset_period])
      @last_reset.update_attributes(:config_value=> params[:configuration][:financial_year_start_date])

      flash[:notice] = "#{t('flash_msg8')}"
      redirect_to :action => "leave_reset_settings"
    end
  end
 
  def update_employee_leave_reset_all
    @leave_count = EmployeeLeave.all
    @leave_count.each do |e|
      @leave_type = EmployeeLeaveType.find_by_id(e.employee_leave_type_id)
      if @leave_type.status
        default_leave_count = @leave_type.max_leave_count
        if @leave_type.carry_forward
          leave_taken = e.leave_taken
          available_leave = e.leave_count
          if leave_taken <= available_leave
            balance_leave = available_leave - leave_taken
            available_leave = balance_leave.to_f
            available_leave += default_leave_count.to_f
            leave_taken = 0
            e.update_attributes(:leave_taken => leave_taken,:leave_count => available_leave, :reset_date => Time.now)
          else
            available_leave = default_leave_count.to_f
            leave_taken = 0
            e.update_attributes(:leave_taken => leave_taken,:leave_count => available_leave, :reset_date => Time.now)
          end
        else
          available_leave = default_leave_count.to_f
          leave_taken = 0
          e.update_attributes(:leave_taken => leave_taken,:leave_count => available_leave, :reset_date => Time.now)
        end
      end
    end
    render :update do |page|
      page.replace_html "main-reset-box", :text => "<p class='flash-msg'>#{t('leave_count_reset_sucessfull')}</p>"
    end
  end

  def employee_leave_reset_by_department
    @departments = EmployeeDepartment.active_and_ordered

  end

  def list_department_leave_reset
    @leave_types = EmployeeLeaveType.find(:all, :conditions => "status = true")
    if params[:department_id] == ""
      render :update do |page|
        page.replace_html "department-list", :text => ""
      end
      return
    end
    @employees=Employee.find(:all,:conditions=>{:employee_department_id=>params[:department_id]}).sort_by{|s| s.full_name.downcase}
    render :update do |page|
      page.replace_html "department-list", :partial => 'department_list'
    end
  end

  def update_department_leave_reset
    @employee = params[:employee_id]
    @employee.each do |e|
      @leave_count = EmployeeLeave.find_all_by_employee_id(e)
      @leave_count.each do |c|
        @leave_type = EmployeeLeaveType.find_by_id(c.employee_leave_type_id)
        if @leave_type.status
          default_leave_count = @leave_type.max_leave_count
          if @leave_type.carry_forward
            leave_taken = c.leave_taken
            available_leave = c.leave_count
            if leave_taken <= available_leave
              balance_leave = available_leave - leave_taken
              available_leave = balance_leave.to_f
              available_leave += default_leave_count.to_f
              leave_taken = 0
              c.update_attributes(:leave_taken => leave_taken,:leave_count => available_leave, :reset_date => Time.now)
            else
              available_leave = default_leave_count.to_f
              leave_taken = 0
              c.update_attributes(:leave_taken => leave_taken,:leave_count => available_leave, :reset_date => Time.now)
            end
          else
            available_leave = default_leave_count.to_f
            leave_taken = 0
            c.update_attributes(:leave_taken => leave_taken,:leave_count => available_leave, :reset_date => Time.now)
          end
        end

      end
    end
    flash[:notice]=t('flash12')
    redirect_to :controller=>"employee_attendance", :action => "employee_leave_reset_by_department"
  end


  def employee_leave_reset_by_employee
    @departments = EmployeeDepartment.ordered
    @categories  = EmployeeCategory.find(:all,:order=>'name ASC')
    @positions   = EmployeePosition.find(:all,:order=>'name ASC')
    @grades      = EmployeeGrade.find(:all,:order=>'name ASC')
  end

  def employee_search_ajax
    other_conditions = ""
    other_conditions += " AND employee_department_id = '#{params[:employee_department_id]}'" unless params[:employee_department_id] == ""
    other_conditions += " AND employee_category_id = '#{params[:employee_category_id]}'" unless params[:employee_category_id] == ""
    other_conditions += " AND employee_position_id = '#{params[:employee_position_id]}'" unless params[:employee_position_id] == ""
    other_conditions += " AND employee_grade_id = '#{params[:employee_grade_id]}'" unless params[:employee_grade_id] == ""
    unless params[:query].length < 3
      @employee = Employee.find(:all,
        :conditions => ["(first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                       OR employee_number LIKE ? OR (concat(first_name, \" \", last_name) LIKE ?))" + other_conditions,
          "#{params[:query]}%","#{params[:query]}%","#{params[:query]}%",
          "#{params[:query]}", "#{params[:query]}"],
        :order => "first_name asc") unless params[:query] == ''
    else
      @employee = Employee.find(:all,
        :conditions => ["employee_number = ? "+ other_conditions, "#{params[:query]}%"],
        :order => "first_name asc") unless params[:query] == ''
    end
    render :layout => false
  end

  def employee_view_all
    @departments = EmployeeDepartment.active_and_ordered
  end

  def employees_list
    department_id = params[:department_id]
    @employees = Employee.find_all_by_employee_department_id(department_id,:order=>'first_name ASC')

    render :update do |page|
      page.replace_html 'employee_list', :partial => 'employee_view_all_list', :object => @employees
    end
  end

  def employee_leave_details
    @employee = Employee.find(params[:id])
    @leave_count = EmployeeLeave.find_all_by_employee_id(@employee.id,:include=>:employee_leave_type,:conditions=>["employee_leave_types.status IS NOT false"])
  end

  def employee_wise_leave_reset
    @employee = Employee.find(params[:id])
    @leave_count = EmployeeLeave.find_all_by_employee_id(@employee.id)
    @leave_count.each do |e|
      @leave_type = EmployeeLeaveType.find_by_id(e.employee_leave_type_id)
      if @leave_type.status
        default_leave_count = @leave_type.max_leave_count
        if @leave_type.carry_forward
          leave_taken = e.leave_taken
          available_leave = e.leave_count
          if leave_taken <= available_leave
            balance_leave = available_leave - leave_taken
            available_leave = balance_leave.to_f
            available_leave += default_leave_count.to_f
            leave_taken = 0
            e.update_attributes(:leave_taken => leave_taken,:leave_count => available_leave, :reset_date => Time.now)
          else
            available_leave = default_leave_count.to_f
            leave_taken = 0
            e.update_attributes(:leave_taken => leave_taken,:leave_count => available_leave, :reset_date => Time.now)
          end
        else
          available_leave = default_leave_count.to_f
          leave_taken = 0
          e.update_attributes(:leave_taken => leave_taken,:leave_count => available_leave, :reset_date => Time.now)
        end
      end
    end
    render :update do |page|
      flash.now[:notice]= "#{t('flash_msg12')}"
      page.replace_html "list", :partial => 'employee_reset_sucess'
    end
  end


  def register
    @departments = EmployeeDepartment.active_and_ordered
    if request.post?
      unless params[:employee_attendance].nil?
        params[:employee_attendance].each_pair do |emp, att|
          @employee_attendance = EmployeeAttendance.create(:attendance_date => params[:date],
            :employees_id => emp, :employee_leave_types_id=> att) unless att == ""
        end
        flash[:notice]=t('flash3')
        redirect_to :controller=>"employee_attendance", :action => "register"
      end
    end
  end

  def update_attendance_form
    @leave_types = EmployeeLeaveType.find(:all, :conditions=>"status = true", :order=>"name ASC")
    if params[:department_id] == ""
      render :update do |page|
        page.replace_html "attendance_form", :text => ""
      end
      return
    end

    @employees = Employee.find_all_by_employee_department_id(params[:department_id])
    render :update do |page|
      page.replace_html 'attendance_form', :partial => 'attendance_form'
    end
  end
  def filter_attendance_report
      @departments = EmployeeDepartment.active_and_ordered
  end
  def update_filterd_attendance_report
      @errors=[]
      @dep_id=params[:employee_department][:id]
      @start_date=params[:start_date]
      @end_date=params[:end_date]
      if @dep_id.blank?
       @errors.push("#{t('no_department_selected_for_filter')}")
      elsif @start_date.to_date>@end_date.to_date
        @errors.push("#{t('start_date_should_less_than_end_date')}")
      end
     unless @errors.present?
          @leave_types = EmployeeLeaveType.find(:all, :conditions => "status = true")
          if @dep_id == ""
            render :update do |page|
              page.replace_html "attendance_report", :text => ""
            end
            return
          end
          unless (@dep_id == "All Departments")
            @employees = Employee.find_all_by_employee_department_id(@dep_id).paginate(:page=>params[:page],:per_page=>50)
          else
            @employees = Employee.paginate(:page =>params[:page],:per_page=>50 )
          end
          if request.xhr?
            render :update do |page|
              page.replace_html "attendance_report", :partial => 'update_filterd_attendance'
              page.replace_html 'error_display', :text=>''
            end
          end
     else
      render(:update) do |page|
        page.replace_html 'error_display', :partial=>'error_partial'
      end
     end
  end




  def report
    @departments = EmployeeDepartment.active_and_ordered
  end

  def update_attendance_report
    @leave_types = EmployeeLeaveType.find(:all, :conditions => "status = true")
    if params[:department_id] == ""
      render :update do |page|
        page.replace_html "attendance_report", :text => ""
      end
      return
    end
    unless (params[:department_id] == "All Departments")
      @employees = Employee.find_all_by_employee_department_id(params[:department_id]).paginate(:page=>params[:page],:per_page=>50)
    else
      @employees = Employee.paginate(:page =>params[:page],:per_page=>50 )
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "attendance_report", :partial => 'attendance_report'
      end
    end
  end

  def report_pdf
    @data_hash = EmployeeAttendance.fetch_employee_attendance_data(params)
    render :pdf => 'report_pdf', :margin=>{:left=>5,:right=>5}
  end

  def emp_attendance
    @employee = Employee.find(params[:id])
    @attendance_report = EmployeeAttendance.find_all_by_employee_id(@employee.id)
    @leave_types = EmployeeLeaveType.find(:all, :conditions => "status = true")
    @leave_count = EmployeeLeave.find_all_by_employee_id(@employee,:joins=>:employee_leave_type,:conditions=>"status = true")
    @total_leaves = 0
    @leave_types.each do |lt|
      leave_count = EmployeeAttendance.find_all_by_employee_id_and_employee_leave_type_id(@employee.id,lt.id).size
      @total_leaves = @total_leaves +leave_count
    end
  end

  def leave_history
    @employee = Employee.find(params[:id])
  end

  def in_out_report
    if request.post?
      @employee = Employee.find( params["advance_search"]["id"] )
      if params["advance_search"]["date"].present?
        @start_date = ("1-" + params["advance_search"]["date"]).to_date.beginning_of_day
        @end_date = @start_date.end_of_month
        @attendances = StudentAttendance.find(:all, :conditions => {:employee_id => @employee.id, :created_at => @start_date..@end_date})
      end
    else
      @employee = Employee.find(params[:id])
      @dates = ((Date.today - 1.year)..(Date.today)).map{|c| "#{c.strftime("%B-%Y")}"}.uniq
    end
  end

  def update_leave_history
    @employee = Employee.find(params[:id])
    @start_date = (params[:period][:start_date])
    @end_date = (params[:period][:end_date])
    @error=true if @end_date < @start_date
    @leave_types = EmployeeLeaveType.find(:all, :conditions => "status = true")
    @employee_attendances = {}
    @leave_types.each do |lt|
      @employee_attendances[lt.name] = EmployeeAttendance.find_all_by_employee_id_and_employee_leave_type_id(@employee.id,lt.id,:conditions=> "attendance_date between '#{@start_date.to_date}' and '#{@end_date.to_date}'")
    end
    render :update do |page|
      page.replace_html "attendance-report", :partial => 'update_leave_history'
    end
  end
  def leaves
    @employee = Employee.find(params[:id])
    @leave_types = EmployeeLeaveType.find(:all,:joins => :employee_leaves, :conditions=>["status = true AND employee_leaves.employee_id = ? AND employee_leaves.reset_date IS NOT NULL",@employee.id])
    @reporting_employees = Employee.find_all_by_reporting_manager_id(@employee.user_id)
    @total_leave_count = 0
    @reporting_employees.each do |e|
      @app_leaves = ApplyLeave.count(:conditions=>["employee_id =? AND viewed_by_manager =?", e.id, false])
      @total_leave_count = @total_leave_count + @app_leaves
    end

    @leave_apply = ApplyLeave.new(params[:leave_apply])
    if request.post?
      if(@leave_apply.start_date.to_date != @leave_apply.end_date.to_date and @leave_apply.is_half_day == true)
        @leave_apply.errors.add_to_base("#{t('half_day_not_possible')}") and return
      end
      applied_dates = (@leave_apply.start_date..@leave_apply.end_date).to_a.uniq
      detect_overlaps = ApplyLeave.find(:all, :conditions => ["employee_id = ? AND (start_date IN (?) OR end_date IN (?))",@employee.id, applied_dates, applied_dates])
      if detect_overlaps.present? and detect_overlaps.map(&:approved).include? true
        @leave_apply.errors.add_to_base("#{t('range_conflict')}") and return
      end
      leaves_half_day = ApplyLeave.count(:all,:conditions=>{:employee_id=>params[:leave_apply][:employee_id],:start_date=>params[:leave_apply][:start_date],:end_date=>params[:leave_apply][:end_date],:is_half_day=>true})
      leaves = ApplyLeave.count(:all,:conditions=>{:approved => true, :employee_id=>params[:leave_apply][:employee_id],:start_date=>params[:leave_apply][:start_date],:end_date=>params[:leave_apply][:end_date]})
      already_apply = ApplyLeave.count(:all,:conditions=>{:approved => nil, :employee_id=>params[:leave_apply][:employee_id],:start_date=>params[:leave_apply][:start_date],:end_date=>params[:leave_apply][:end_date]})
      if(leaves == 0 and already_apply == 0) or (leaves <= 1 and leaves_half_day < 2)
        unless leaves_half_day == 1 and params[:leave_apply][:is_half_day]=='0'
          @leave_apply.approved = nil
          @leave_apply.viewed_by_manager = false
          if @leave_apply.save
            flash[:notice]=t('flash5')
            redirect_to :controller => "employee_attendance", :action=> "leaves", :id=>@employee.id
          end
        else
          @leave_apply.errors.add_to_base("#{t('half_day_alredy_applied')}")
        end
      else
        @leave_apply.errors.add_to_base("#{t('already_applied')}")
      end
    end
  end
  
  def leave_application
    @applied_leave = ApplyLeave.find(params[:id])
    @applied_employee = Employee.find(@applied_leave.employee_id)
    @leave_type = EmployeeLeaveType.find(@applied_leave.employee_leave_types_id)
    @manager = @applied_employee.reporting_manager_id
    @leave_count = EmployeeLeave.find_by_employee_id(@applied_employee.id,:conditions=> "employee_leave_type_id = '#{@leave_type.id}'")
  end

  def leave_app
    @employee = Employee.find(params[:id2])
    @applied_leave = ApplyLeave.find(params[:id])
    @leave_type = EmployeeLeaveType.find(@applied_leave.employee_leave_types_id)
    @applied_employee = Employee.find(@applied_leave.employee_id)
    @manager = @applied_employee.reporting_manager_id
  end

  def approve_remarks
    @applied_leave = ApplyLeave.find(params[:id])
  end

  def deny_remarks
    @applied_leave = ApplyLeave.find(params[:id])
  end

  def approve_leave
    @applied_leave = ApplyLeave.find(params[:applied_leave])
    @applied_employee = Employee.find(@applied_leave.employee_id)
    @employee_leave = EmployeeLeave.find_by_employee_id_and_employee_leave_type_id(@applied_employee.id,@applied_leave.employee_leave_types_id)
    @manager = @applied_employee.reporting_manager_id    
    start_date = @applied_leave.start_date
    end_date = @applied_leave.end_date
    reset_date = @employee_leave.reset_date || @applied_employee.joining_date - 1.day
    @leave_count = 0
    (start_date..end_date).each do |date|
      @leave_count += @applied_leave.is_half_day == true ? 0.5 : 1.0
    end
    if @employee_leave.leave_count >= (@employee_leave.leave_taken + @leave_count)
      if start_date >= reset_date.to_date
        (start_date..end_date).each do |d|
          emp_attendance = EmployeeAttendance.find_by_employee_id_and_attendance_date(@applied_employee.id, d)
          unless emp_attendance.present?
            att = EmployeeAttendance.new(:attendance_date=> d, :employee_id=>@applied_employee.id,:employee_leave_type_id=>@applied_leave.employee_leave_types_id, :reason => @applied_leave.reason, :is_half_day => @applied_leave.is_half_day)
            if att.save
              att.update_attributes(:is_half_day => @applied_leave.is_half_day)
              @reset_count = EmployeeLeave.find_by_employee_id(@applied_leave.employee_id, :conditions=> "employee_leave_type_id = '#{@applied_leave.employee_leave_types_id}'")
              leave_taken = @reset_count.leave_taken
              if @applied_leave.is_half_day
                leave_taken += 0.5
                @reset_count.update_attributes(:leave_taken=> leave_taken)
              else
                leave_taken += 1
                @reset_count.update_attributes(:leave_taken=> leave_taken)
              end
            end
          else
            already_half_day = emp_attendance.is_half_day
            emp_attendance.update_attributes(:is_half_day => false)
            @reset_count = EmployeeLeave.find_by_employee_id(@applied_leave.employee_id, :conditions=> "employee_leave_type_id = '#{@applied_leave.employee_leave_types_id}'")
            leave_taken = @reset_count.leave_taken
            if already_half_day == true
              if @applied_leave.is_half_day
                leave_taken += 0.5
                @reset_count.update_attributes(:leave_taken=> leave_taken)
              else
                leave_taken += 0.5
                @reset_count.update_attributes(:leave_taken=> leave_taken)
              end
            end
          end
        end
        @applied_leave.update_attributes(:approved => true, :manager_remark => params[:manager_remark],:viewed_by_manager => true, :approving_manager => current_user.id)
        flash[:notice]="#{t('flash6')} #{@applied_employee.first_name} from #{@applied_leave.start_date} to #{@applied_leave.end_date}"
        redirect_to :controller=>"employee_attendance", :action=>"leaves", :id=>@applied_employee.reporting_manager.employee_record.id and return
      else
        flash[:notice] = "The application contains dates which are earlier than reset date."
        redirect_to :controller=>"employee_attendance", :action=>"leaves", :id=>@applied_employee.reporting_manager.employee_record.id and return
      end
    else
      flash[:notice] = "Total amount of leave exceeded."
      redirect_to :controller => "employee_attendance", :action => "leave_application", :id => @applied_leave.id and return
    end  
  end

  def deny_leave
    @applied_leave = ApplyLeave.find(params[:applied_leave])
    start_date = @applied_leave.start_date
    end_date = @applied_leave.end_date
    @applied_employee = Employee.find(@applied_leave.employee_id)
    @employee_leave = EmployeeLeave.find_by_employee_id_and_employee_leave_type_id(@applied_employee.id,@applied_leave.employee_leave_types_id)
    @manager = @applied_employee.reporting_manager_id
    @employee_attendances = EmployeeAttendance.find(:all, :conditions => ["((attendance_date = ?) OR (attendance_date = ?) or (attendance_date BETWEEN ? and ?)) AND employee_id = ?",start_date,end_date,start_date,end_date,@applied_employee.id])
    @employee_half_day_attendances = EmployeeAttendance.count(:all, :conditions => ["((attendance_date = ?) OR (attendance_date = ?) or (attendance_date BETWEEN ? and ?)) AND (is_half_day = ? AND employee_id = ?)",start_date,end_date,start_date,end_date,true, @applied_employee.id])
    count = @employee_attendances.count.to_f - (@employee_half_day_attendances.to_f / 2)
    @employee_attendances.each do |attendance|
      if attendance.created_at < @employee_leave.reset_date
        update_value = @applied_leave.is_half_day == true ? 0.5 : 1.0
        @employee_leave.update_attributes(:leave_count => @employee_leave.leave_count + update_value)
      else
        update_value = @applied_leave.is_half_day == true ? 0.5 : 1.0
        @employee_leave.update_attributes(:leave_taken => @employee_leave.leave_taken - update_value)
      end
    end
    @employee_attendances.each do |employee_attendance|
      if @applied_leave.is_half_day == true and employee_attendance.is_half_day == true
        employee_attendance.destroy
      elsif @applied_leave.is_half_day == true and employee_attendance.is_half_day == false
        employee_attendance.update_attributes(:is_half_day => true)
      elsif @applied_leave.is_half_day == false and employee_attendance.is_half_day == false
        employee_attendance.destroy
      elsif @applied_leave.is_half_day == false and employee_attendance.is_half_day == true
        employee_attendance.destroy
      end
    end
    @applied_leave.update_attributes(:approved => false,:viewed_by_manager => true, :manager_remark =>params[:manager_remark], :approving_manager => current_user.id)
    flash[:notice]="#{t('flash7')} #{@applied_employee.first_name} from #{@applied_leave.start_date} to #{@applied_leave.end_date}"
    redirect_to :action=>"leaves", :id=>@applied_employee.reporting_manager.employee_record.id
  end

  def cancel
    render :text=>""
  end

  def new_leave_applications
    @employee = Employee.find(params[:id])
    @reporting_employees = Employee.find_all_by_reporting_manager_id(@employee.user_id)
    render :partial => "new_leave_applications"
  end

  def all_employee_new_leave_applications
    @employee = Employee.find(params[:id])
    @all_employees = Employee.find(:all)
    render :partial => "all_employee_new_leave_applications"
  end

  def all_leave_applications
    @employee = Employee.find(params[:id])
    @reporting_employees = Employee.find_all_by_reporting_manager_id(@employee.user_id)
    render :partial => "all_leave_applications"
  end

  def individual_leave_applications
    @employee = Employee.find(params[:id])
    @pending_applied_leaves = ApplyLeave.find_all_by_employee_id(@employee.id, :conditions=> "approved = false AND viewed_by_manager = false", :order=>"start_date DESC")
    @applied_leaves = ApplyLeave.paginate(:page => params[:page],:per_page=>10 , :conditions=>[ "employee_id = '#{@employee.id}'"], :order=>"start_date DESC")
    render :partial => "individual_leave_applications"
  end

  def own_leave_application
    @applied_leave = ApplyLeave.find(params[:id])
    @leave_type = EmployeeLeaveType.find(@applied_leave.employee_leave_types_id)
    @employee = Employee.find(@applied_leave.employee_id)
  end

  def cancel_application
    @applied_leave = ApplyLeave.find(params[:id])
    @employee = Employee.find(@applied_leave.employee_id)
    unless @applied_leave.viewed_by_manager
      ApplyLeave.destroy(params[:id])
      flash[:notice] = t('flash8')
    else
      flash[:notice] = t('flash10')
    end
    redirect_to :action=>"leaves", :id=>@employee.id
  end

  def update_all_application_view
    if params[:employee_id] == ""
      render :update do |page|
        page.replace_html "all-application-view", :text => ""
      end
      return
    end
    @employee = Employee.find(params[:employee_id])

    @all_pending_applied_leaves = ApplyLeave.find_all_by_employee_id(params[:employee_id], :conditions=> "approved = false AND viewed_by_manager = false", :order=>"start_date DESC")
    @all_applied_leaves = ApplyLeave.paginate(:page => params[:page], :per_page=>10, :conditions=> ["employee_id = '#{@employee.id}'"], :order=>"start_date DESC")
    render :update do |page|
      page.replace_html "all-application-view", :partial => "all_leave_application_lists"
    end
  end

  #PDF Methods

  def employee_attendance_pdf
    @employee = Employee.find(params[:id])
    @attendance_report = EmployeeAttendance.find_all_by_employee_id(@employee.id)
    @leave_types = EmployeeLeaveType.find(:all, :conditions => "status = true")
    @leave_count = EmployeeLeave.find_all_by_employee_id(@employee,:joins=>:employee_leave_type,:conditions=>"status = true")
    @total_leaves = 0
    @leave_types.each do |lt|
      leave_count = EmployeeAttendance.find_all_by_employee_id_and_employee_leave_type_id(@employee.id,lt.id).size
      @total_leaves = @total_leaves + leave_count
    end
    render :pdf => 'employee_attendance_pdf'
          

    #        respond_to do |format|
    #            format.pdf { render :layout => false }
    #        end
  end

  def additional_leave_history
    @departments = EmployeeDepartment.active_and_ordered
    if request.post?
      @month = params["month"]["month_id"]
      @year = params["year"]["year_id"]
      @department = params[:employee_department][:department_id]
      if @department == "" || @month == "" || @year == ""
        render(:update) do |page|
          page.replace_html 'additional-leave-report', :text=>"<p class='flash-msg'>#{t('no_reports')}</p>"
        end
        return
      end
      additional_leave_history_calculation @month,@year,@department
      render :update do |page|
        page.replace_html "additional-leave-report", :partial => "additional_leave_report"
      end
    end    
  end

  def additional_leave_detailed
    begin
      additional_leave_detailed_calculation params
    rescue Exception => e
      not_found
    end
  end

  def additional_leave_detailed_report_pdf
    begin
      additional_leave_detailed_calculation params
      render :pdf => 'additional_leave_detailed_report_pdf'
    rescue Exception => e
      not_found
    end
  end

  def additional_leave_report_pdf
    begin
      month = params[:month]
      year = params[:year]
      department = params[:department]
      additional_leave_history_calculation month,year,department
      render :pdf => 'additional_leave_report_pdf', :margin=>{:left=>5,:right=>5}
    rescue Exception => e
      not_found
    end
  end

  def not_found
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
    end
  end

  private

  def additional_leave_history_calculation(month,year,department)
    @employees = Employee.get_employees(department)
    @additional_leave_history = {}
    @leave_types = [] 
    @employee_attendance = EmployeeAttendance.find_employee_attendance
    @employees.each do |e|
      @additional_leave_history[e.id] = [e.full_name,e.employee_number]
      total = 0
      e.employee_leaves.each do |el|
        next unless el.employee_leave_type.status
        if el.employee_id == e.id && ((Date.parse("#{el.reset_date.year}-#{el.reset_date.month}-#{el.reset_date.day}") <= Date.parse("#{year}-#{month}-#{Date.new(year.to_i,month.to_i, -1).day}") unless el.reset_date.nil?) || el.reset_date.nil? )
          @leave_types << el.employee_leave_type.code unless @leave_types.include? el.employee_leave_type.code
          additional_leaves = find_additional_leaves(el,e.id)
          additional_leave_count_of_month = 0.0
          additional_leaves.each do |leave|
            if leave[:record].attendance_date.to_s.include? "#{year}-#{month}"
              if leave[:half_day] == true
                additional_leave_count_of_month += 0.5
              else
                additional_leave_count_of_month += 1.0
              end
            end
          end
          @additional_leave_history[e.id] << additional_leave_count_of_month
          total += additional_leave_count_of_month
        end
      end
      sum = 0.0
      (2..@additional_leave_history[e.id].length - 1).each { |a|
        sum += @additional_leave_history[e.id][a]
      }
      @additional_leave_history.delete(e.id) if sum == 0.0
      @additional_leave_history[e.id] << total if @additional_leave_history[e.id]
    end
    @additional_leave_history = @additional_leave_history.sort
  end

  def additional_leave_detailed_calculation(params)
    @additional_leaves_detailed = {}
    @leave_types = []
    @employee_attendance = EmployeeAttendance.find_employee_attendance
    @total = {}
    @employee = Employee.find(params[:id])
    @grand_total = 0
    @employee.employee_leaves.each do |el|
      next unless el.employee_leave_type.status
      if el.employee_id == params[:id].to_i && ((Date.parse("#{el.reset_date.year}-#{el.reset_date.month}-#{el.reset_date.day}") <= Date.parse("#{params[:year]}-#{params[:month]}-#{Date.new(params[:year].to_i,params[:month].to_i, -1).day}") unless el.reset_date.nil?) || el.reset_date.nil? )
        @leave_types << el.employee_leave_type.code unless @leave_types.include? el.employee_leave_type.code
        leave_name = el.employee_leave_type.name
        @additional_leaves_detailed[leave_name] = []
        additional_leaves = find_additional_leaves(el,params[:id].to_i)
        additional_leave_count_of_month = 0.0
        additional_leaves.each do |ad_leave|
          if ad_leave[:record].attendance_date.to_s.include? "#{params[:year]}-#{params[:month]}"
            if ad_leave[:half_day] == true
              @additional_leaves_detailed[leave_name] << I18n.l(ad_leave[:record].attendance_date,:format => :normal) + "(Half Day)"
              additional_leave_count_of_month  += 0.5
            else
              @additional_leaves_detailed[leave_name] << I18n.l(ad_leave[:record].attendance_date,:format => :normal)
              additional_leave_count_of_month += 1.0
            end
          end
        end
        total = additional_leave_count_of_month
        @additional_leaves_detailed[leave_name] <<  t('no_leaves_taken') if additional_leave_count_of_month.zero?
        @total["Total " + "#{leave_name}"] = [ "#{total}"]
        @grand_total += total
      end
    end
    @total["Total"] = ["#{@grand_total}"]
  end

  def find_additional_leaves(employee_leave,employee)
    leave_count = employee_leave.leave_count
    additional_leaves = []
    count = 0.0
    employee_leaves = @employee_attendance.sort_by(&:attendance_date).select {|r| r["employee_leave_type_id"] == employee_leave.employee_leave_type_id && r["employee_id"] == employee}
    employee_leaves.each do |leave|
      ad_count = leave.is_half_day? ? count + 0.5 : count + 1.0
      if ad_count <= leave_count
        count = ad_count
      else
        if ad_count - 0.5 == leave_count
          additional_leaves << { :record => leave , :half_day => true}
          count += 0.5
        else
          additional_leaves << {:record => leave,:half_day => false} if leave.is_half_day == false
          additional_leaves << {:record => leave,:half_day => true} if leave.is_half_day == true
        end
      end
    end
    return additional_leaves
  end
end

          



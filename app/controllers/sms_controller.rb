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

class SmsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  def index
    @sms_setting = SmsSetting.new()
    @parents_sms_enabled = SmsSetting.find_by_settings_key("ParentSmsEnabled")
    @students_sms_enabled = SmsSetting.find_by_settings_key("StudentSmsEnabled")
    @employees_sms_enabled = SmsSetting.find_by_settings_key("EmployeeSmsEnabled")
  end

  def settings
    @application_sms_enabled = SmsSetting.find_by_settings_key("ApplicationEnabled")
    @student_admission_sms_enabled = SmsSetting.find_by_settings_key("StudentAdmissionEnabled")
    @exam_schedule_result_sms_enabled = SmsSetting.find_by_settings_key("ExamScheduleResultEnabled")
    @student_attendance_sms_enabled = SmsSetting.find_by_settings_key("AttendanceEnabled")
    @news_events_sms_enabled = SmsSetting.find_by_settings_key("NewsEventsEnabled")
    @parents_sms_enabled = SmsSetting.find_by_settings_key("ParentSmsEnabled")
    @students_sms_enabled = SmsSetting.find_by_settings_key("StudentSmsEnabled")
    @employees_sms_enabled = SmsSetting.find_by_settings_key("EmployeeSmsEnabled")
    @fee_submission_sms_enabled = SmsSetting.find_by_settings_key("FeeSubmissionEnabled")
    @in_out_attendance_sms_enabled = SmsSetting.find_by_settings_key("InOutAttendanceEnabled")
    if request.post?
      SmsSetting.update(@application_sms_enabled.id,:is_enabled=>params[:sms_settings][:application_enabled])
      flash[:notice] = "#{t('flash1')}"
      redirect_to :action=>"settings"
    end
  end

  def update_general_sms_settings
    @student_admission_sms_enabled = SmsSetting.find_by_settings_key("StudentAdmissionEnabled")
    @exam_schedule_result_sms_enabled = SmsSetting.find_by_settings_key("ExamScheduleResultEnabled")
    @student_attendance_sms_enabled = SmsSetting.find_by_settings_key("AttendanceEnabled")
    @news_events_sms_enabled = SmsSetting.find_by_settings_key("NewsEventsEnabled")
    @parents_sms_enabled = SmsSetting.find_by_settings_key("ParentSmsEnabled")
    @students_sms_enabled = SmsSetting.find_by_settings_key("StudentSmsEnabled")
    @employees_sms_enabled = SmsSetting.find_by_settings_key("EmployeeSmsEnabled")
    @fee_submission_sms_enabled = SmsSetting.find_by_settings_key("FeeSubmissionEnabled")
    @in_out_attendance_sms_enabled = SmsSetting.find_by_settings_key("InOutAttendanceEnabled")
    SmsSetting.update(@student_admission_sms_enabled.id,:is_enabled=>params[:general_settings][:student_admission_enabled])
    SmsSetting.update(@exam_schedule_result_sms_enabled.id,:is_enabled=>params[:general_settings][:exam_schedule_result_enabled])
    SmsSetting.update(@student_attendance_sms_enabled.id,:is_enabled=>params[:general_settings][:student_attendance_enabled])
    SmsSetting.update(@news_events_sms_enabled.id,:is_enabled=>params[:general_settings][:news_events_enabled])
    SmsSetting.update(@parents_sms_enabled.id,:is_enabled=>params[:general_settings][:sms_parents_enabled])
    SmsSetting.update(@students_sms_enabled.id,:is_enabled=>params[:general_settings][:sms_students_enabled])
    SmsSetting.update(@employees_sms_enabled.id,:is_enabled=>params[:general_settings][:sms_employees_enabled])
    SmsSetting.update(@fee_submission_sms_enabled.id,:is_enabled=>params[:general_settings][:fee_submission_enabled])
    if @in_out_attendance_sms_enabled.present?
      status = @student_attendance_sms_enabled.is_enabled ? params[:general_settings][:in_out_attendance_sms_enabled] : false
      SmsSetting.update(@in_out_attendance_sms_enabled.id,:is_enabled=>params[:general_settings][:in_out_attendance_sms_enabled])
    end
    flash[:notice] = "#{t('flash2')}"
    redirect_to :action=>"settings"
  end

  def students
    @batches=Batch.active.all(:include=>:course)
    if request.post?
      error=false
      unless params[:send_sms][:student_ids].nil?
        student_ids = params[:send_sms][:student_ids]
        sms_setting = SmsSetting.new()
        @recipients=[]
        student_ids.each do |s_id|
          student = Student.find(s_id)
          guardian = student.immediate_contact
          if student.is_sms_enabled
            if sms_setting.student_sms_active           
              @recipients.push student.phone2 unless (student.phone2.nil? or student.phone2 == "")
            end
            if sms_setting.parent_sms_active
              unless guardian.nil?
                @recipients.push guardian.mobile_phone unless (guardian.mobile_phone.nil? or guardian.mobile_phone == "")
              end
            end
          end
        end
        unless @recipients.empty?
          message = params[:send_sms][:message]
          unless message.blank?
            sms = Delayed::Job.enqueue(SmsManager.new(message,@recipients))
            # raise @recipients.inspect
            render(:update) do |page|
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
              page.visual_effect(:highlight, 'status-message')
              page.replace_html 'student-list',:text=>""
            end
          else
            render(:update) do |page|
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('message_blank')}</p>"
            end
          end
        else
          error=true
        end
      else
        error=true
      end
      if error
        render(:update) do |page|
          page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('select_valid_students')}</p>"
        end
      end
    end
  end
  
  def list_students
    batch = Batch.find(params[:batch_id])
    @students = batch.students.all(:select => 'students.id,admission_no,students.first_name,middle_name,students.last_name,students.phone2,students.roll_number,guardians.id as guardian_id,guardians.mobile_phone',:joins => 'LEFT OUTER JOIN `guardians` ON `guardians`.id = `students`.immediate_contact_id', :conditions=>'is_sms_enabled=true', :order => 'first_name')
    @sms_setting = SmsSetting.new()
    #    @students = Student.find_all_by_batch_id(batch.id,:conditions=>'is_sms_enabled=true')
  end

  def batches
    @batches = Batch.all(:select => "batches.*,CONCAT(courses.code,'-',batches.name) as course_full_name,count(DISTINCT IF((students.phone2 != '' OR guardians.mobile_phone != '') AND students.is_sms_enabled = true,students.id,NULL)) as students_count",:joins => "INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN students ON students.batch_id = batches.id LEFT OUTER JOIN guardians ON guardians.id = students.immediate_contact_id",:conditions => { :is_deleted => false, :is_active => true },:order => "course_full_name",:group => 'id')
    if request.post?
      unless params[:send_sms][:batch_ids].nil?
        batch_ids = params[:send_sms][:batch_ids]
        sms_setting = SmsSetting.new()
        @recipients = []
        batch_ids.each do |b_id|
          batch = Batch.find(b_id)
          batch_students = batch.students
          batch_students.each do |student|
            if student.is_sms_enabled
              if sms_setting.student_sms_active
                @recipients.push student.phone2 unless (student.phone2.nil? or student.phone2 == "")
              end
              if sms_setting.parent_sms_active
                guardian = student.immediate_contact
                unless guardian.nil?
                  @recipients.push guardian.mobile_phone unless (guardian.mobile_phone.nil? or guardian.mobile_phone == "")
                end
              end
            end
          end
        end
        unless @recipients.empty?
          message = params[:send_sms][:message]
          unless message.blank?
            sms = Delayed::Job.enqueue(SmsManager.new(message,@recipients))
            render(:update) do |page|
              page.replace_html 'batches_list',:text=>""
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
              page.visual_effect(:highlight, 'status-message')
            end
          else
            render(:update) do |page|
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('message_blank')}</p>"
            end
          end
        else
          error = true
        end
      else
        error = true
      end
      if error
        render(:update) do |page|
          page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('select_valid_batches')}</p>"
        end
      end
    end
  end

  def sms_all
    batches=Batch.active.all({:include=>{:students=>:immediate_contact}})
    sms_setting = SmsSetting.new()
    student_sms=sms_setting.student_sms_active
    parent_sms=sms_setting.parent_sms_active
    employee_sms=sms_setting.employee_sms_active
    @recipients = []
    batches.each do |batch|
      batch_students = batch.students
      batch_students.each do |student|
        if student.is_sms_enabled
          if student_sms
            @recipients.push student.phone2 unless (student.phone2.nil? or student.phone2 == "")
          end
          if parent_sms
            guardian = student.immediate_contact
            unless guardian.nil?
              @recipients.push guardian.mobile_phone unless (guardian.mobile_phone.nil? or guardian.mobile_phone == "")
            end
          end
        end
      end
    end
    emp_departments = EmployeeDepartment.active_and_ordered(:include=>:employees)
    emp_departments.each do |dept|
      dept_employees = dept.employees
      dept_employees.each do |employee|
        if employee_sms
          @recipients.push employee.mobile_phone unless (employee.mobile_phone.nil? or employee.mobile_phone == "")
        end
      end
    end
    unless @recipients.empty?
      message = params[:send_sms][:message]
      Delayed::Job.enqueue(SmsManager.new(message,@recipients))
    end

  end

  def employees
    if request.post?
      unless params[:send_sms][:employee_ids].nil?
        employee_ids = params[:send_sms][:employee_ids]
        sms_setting = SmsSetting.new()
        @recipients=[]
        employee_ids.each do |e_id|
          employee = Employee.find(e_id)
          if sms_setting.employee_sms_active
            @recipients.push employee.mobile_phone unless (employee.mobile_phone.nil? or employee.mobile_phone == "")
          end
        end
        unless @recipients.empty?
          message = params[:send_sms][:message]
          unless message.blank?
            Delayed::Job.enqueue(SmsManager.new(message,@recipients))
            render(:update) do |page|
              page.replace_html 'employee-list',:text=>""
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
              page.visual_effect(:highlight, 'status-message')
            end
          else
            render(:update) do |page|
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('message_blank')}</p>"
            end
          end
        else
          error = true
        end
      else
        error = true
      end
      if error
        render(:update) do |page|
          page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('select_valid_employees')}</p>"
        end
      end
    end
  end

  def list_employees
    dept = EmployeeDepartment.find(params[:dept_id])
    @employees = dept.employees.all(:order => 'first_name')
  end

  def departments
    @departments = EmployeeDepartment.all(:select =>"employee_departments.*,COUNT(IF(employees.mobile_phone != '', employees.id,NULL)) as employees_count",:joins => "LEFT OUTER JOIN employees ON employees.employee_department_id = employee_departments.id",:group => 'id',:order => 'name')
    if request.post?
      unless params[:send_sms][:dept_ids].nil?
        dept_ids = params[:send_sms][:dept_ids]
        sms_setting = SmsSetting.new()
        @recipients = []
        dept_ids.each do |d_id|
          department = EmployeeDepartment.find(d_id)
          department_employees = department.employees
          department_employees.each do |employee|
            if sms_setting.employee_sms_active
              @recipients.push employee.mobile_phone unless (employee.mobile_phone.nil? or employee.mobile_phone == "")
            end
          end
        end
        unless @recipients.empty?
          message = params[:send_sms][:message]
          unless message.blank?
            Delayed::Job.enqueue(SmsManager.new(message,@recipients))
            render(:update) do |page|
              page.replace_html 'departments_list',:text=>""
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
              page.visual_effect(:highlight, 'status-message')
            end
          else
            render(:update) do |page|
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('message_blank')}</p>"
            end
          end
        else
          error = true
        end
      else
        error = true
      end
      if error
        render(:update) do |page|
          page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('select_valid_departments')}</p>"
        end
      end
    end
  end

  def show_sms_messages
    @sms_messages = SmsMessage.get_sms_messages(params[:page])
    @total_sms = Configuration.get_config_value("TotalSmsCount")
  end

  def show_sms_logs
    @sms_message = SmsMessage.find(params[:id])
    @sms_logs = @sms_message.get_sms_logs(params[:page])
  end
end

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

class AttendancesController < ApplicationController
  before_filter :login_required
  filter_access_to :all, :except=>[:index, :list_subject, :show, :new, :create, :edit,:update, :destroy,:subject_wise_register,:quick_attendance]
  filter_access_to [:index, :list_subject, :show, :new, :create, :edit,:update, :destroy,:subject_wise_register,:quick_attendance], :attribute_check=>true, :load_method => lambda { current_user }
  before_filter :default_time_zone_present_time
  before_filter :check_status
  def index
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @date_today = @local_tzone_time.to_date
    if current_user.admin?
      @batches = Batch.active
    elsif @current_user.privileges.map{|p| p.name}.include?('StudentAttendanceRegister')
      @batches = Batch.active
    elsif @current_user.employee?
      if @config.config_value == 'Daily'
        @batches = @current_user.employee_record.batches
      else
        @batches = @current_user.employee_record.subjects.collect{|b| b.batch}
        @batches += TimetableSwap.find_all_by_employee_id(@current_user.employee_record.try(:id)).map(&:subject).flatten.compact.map(&:batch)
        @batches = @batches.uniq unless @batches.empty?
      end
    end
  end

  def list_subject
    if params[:batch_id].present?
      @batch = Batch.find(params[:batch_id])
      @subjects = @batch.subjects
      if @current_user.employee?  and !@current_user.privileges.map{|m| m.name}.include?("StudentAttendanceRegister")
        employee = @current_user.employee_record
        if @batch.employee_id.to_i == employee.id
          @subjects= @batch.subjects
        else
          subjects = Subject.find(:all,:joins=>"INNER JOIN employees_subjects ON employees_subjects.subject_id = subjects.id AND employee_id = #{employee.try(:id)} AND batch_id = #{@batch.id} ")
          swapped_subjects = Subject.find(:all, :joins => :timetable_swaps, :conditions => ["subjects.batch_id = ? AND timetable_swaps.employee_id = ?",params[:batch_id],employee.try(:id)])
          @subjects = (subjects + swapped_subjects).compact.flatten.uniq
        end
      end
      render(:update) do |page|
        page.replace_html 'subjects', :partial=> 'subjects'
      end
    else
      render(:update) do |page|
        page.replace_html "register", :text => ""
        page.replace_html "subjects", :text => ""
      end
    end
  end

  def show
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    unless params[:next].nil?
      @today = params[:next].to_date
    else
      @today = @local_tzone_time.to_date
    end
    if @config.config_value == 'Daily'
      @batch = Batch.find(params[:batch_id])
      @students = Student.find_all_by_batch_id(@batch.id)
      @dates=@batch.working_days(@today)
    else
      @sub =Subject.find params[:subject_id]
      @batch=Batch.find(@sub.batch_id)
      unless @sub.elective_group_id.nil?
        elective_student_ids = StudentsSubject.find_all_by_subject_id(@sub.id).map { |x| x.student_id }
        @students = Student.find_all_by_batch_id(@batch, :conditions=>"FIND_IN_SET(id,\"#{elective_student_ids.split.join(',')}\")")
      else
        @students = Student.find_all_by_batch_id(@batch)
      end
      @dates=Timetable.tte_for_range(@batch,@today,@sub)
      @dates_key=@dates.keys - @batch.holiday_event_dates
    end
    respond_to do |format|
      format.js { render :action => 'show' }
    end
  end

  def subject_wise_register
    if params[:subject_id].present?
      @sub = Subject.find params[:subject_id]
      to_search = @sub.elective_group_id.nil? ? @sub.to_a : @sub.elective_group.subjects.active
      @batch = Batch.find(@sub.batch_id)
      @timetable = TimetableEntry.find(:all, :conditions => ["batch_id = ? and subject_id IN (?)", @batch.id, to_search.map(&:id)])
      @subject=@sub
      unless @timetable.empty?
        @subject=@timetable.first.subject
      end
      unless (@timetable.present? and @batch.present? and @batch.weekday_set_id.present?)
        unless @subject.timetable_swaps.present?
          render :update do |page|
            page.replace_html "register", :partial => "no_timetable"
            page.hide "loader"
          end
          return
        end
      end
      @today = params[:next].present? ? params[:next].to_date : @local_tzone_time.to_date
      unless @sub.elective_group_id.nil?
        elective_student_ids = StudentsSubject.find_all_by_subject_id(@sub.id).map { |x| x.student_id }
        if Configuration.enabled_roll_number?
          @students = @batch.students.by_first_name.with_full_name_roll_number.all(:conditions=>"FIND_IN_SET(id,\"#{elective_student_ids.split.join(',')}\")")
        else
          @students = @batch.students.by_first_name.with_full_name_admission_no.all(:conditions=>"FIND_IN_SET(id,\"#{elective_student_ids.split.join(',')}\")")
        end
      else
        if Configuration.enabled_roll_number?
          @students = @batch.students.by_first_name.with_full_name_roll_number.all
        else  
          @students = @batch.students.by_first_name.with_full_name_admission_no.all
        end
      end
      p @students
      subject_leaves = SubjectLeave.by_month_batch_subject(@today,@batch.id,@sub.id).group_by(&:student_id)
      @leaves = Hash.new
      @students.each do |student|
        @leaves[student.id] = Hash.new(false)
        unless subject_leaves[student.id].nil?
          subject_leaves[student.id].group_by(&:month_date).each do |m,mleave|
            @leaves[student.id]["#{m}"]={}
            mleave.group_by(&:class_timing_id).each do |ct,ctleave|
              ctleave.each do |leave|
                @leaves[student.id]["#{m}"][ct] = leave.id
              end
            end
          end
        end
      end
      if @subject.elective_group_id.present?
        unless @timetable.empty?
          employee = @timetable.first.employee
        end
      end
      employee ||= current_user.employee_record
      @dates = Timetable.tte_for_range(@batch,@today,@subject,employee)
      @translated=Hash.new
      @translated['name']=t('name')
      @translated['student']=t('student_text')
      @translated['rapid_attendance']=t('rapid_attendance')
      @translated['subjectwise_quick_attendance_explanation']=t('subjectwise_quick_attendance_explanation')
      @translated['attendance_before_the_date_of_admission_is_invalid']=t('attendance_before_the_date_of_admission_is_invalid')
      @translated['no_timetable_entries']=t('no_entries_found')
      (0..6).each do |i|
        @translated[Date::ABBR_DAYNAMES[i].to_s]=t(Date::ABBR_DAYNAMES[i].downcase)
      end
      (1..12).each do |i|
        @translated[Date::MONTHNAMES[i].to_s]=t(Date::MONTHNAMES[i].downcase)
      end
      respond_to do |fmt|
        fmt.json {render :json=>{'leaves'=>@leaves,'students'=>@students,'dates'=>@dates,'batch'=>@batch,'today'=>@today,'translated'=>@translated}}
      end
    else
      render :update do |page|
        page.replace_html "register", :text => ""
        page.hide "loader"
      end
      return
    end
  end

  def daily_register
    @batch = Batch.find_by_id(params[:batch_id])
    @timetable = TimetableEntry.find(:all, :conditions => {:batch_id => @batch.try(:id)})
    if(@timetable.nil? or @batch.nil?)
      render :update do |page|
        page.replace_html "register", :partial => "no_timetable"
        page.hide "loader"
      end
      return
    end
    @today = params[:next].present? ? params[:next].to_date : @local_tzone_time.to_date
    if Configuration.enabled_roll_number?
      @students = @batch.students.by_first_name.with_full_name_roll_number
    else
      @students = @batch.students.by_first_name.with_full_name_admission_no
    end
    @leaves = Hash.new
    attendances = Attendance.by_month_and_batch(@today,params[:batch_id]).group_by(&:student_id)
    @students.each do |student|
      @leaves[student.id] = Hash.new(false)
      unless attendances[student.id].nil?
        attendances[student.id].each do |attendance|
          @leaves[student.id]["#{attendance.month_date}"] = attendance.id
        end
      end
    end
    #    @dates=((@batch.end_date.to_date > @today.end_of_month) ? (@today.beginning_of_month..@today.end_of_month) : (@today.beginning_of_month..@batch.end_date.to_date))
    @dates=@batch.total_days(@today)
    @working_dates=@batch.working_days(@today)
    @holidays = []
    @translated=Hash.new
    @translated['name']=t('name')
    @translated['student']=t('student_text')
    @translated['rapid_attendance']=t('rapid_attendance')
    @translated['daily_quick_attendance_explanation']=t('daily_quick_attendance_explanation')
    @translated['attendance_before_the_date_of_admission_is_invalid']=t('attendance_before_the_date_of_admission_is_invalid')
    (0..6).each do |i|
      @translated[Date::ABBR_DAYNAMES[i].to_s]=t(Date::ABBR_DAYNAMES[i].downcase)
    end
    (1..12).each do |i|
      @translated[Date::MONTHNAMES[i].to_s]=t(Date::MONTHNAMES[i].downcase)
    end
    respond_to do |fmt|
      fmt.json {render :json=>{'leaves'=>@leaves,'students'=>@students,'dates'=>@dates,'holidays'=>@holidays,'batch'=>@batch,'today'=>@today, 'translated'=>@translated,'working_dates'=>@working_dates}}
      #      format.js { render :action => 'show' }
    end
  end

  def new
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @student = Student.find(params[:id])
      @month_date = params[:date]
      @absentee = Attendance.new
    else
      @student = Student.find(params[:id]) unless params[:id].nil?
      @student ||= Student.find(params[:subject_leave][:student_id])
      @subject_leave=SubjectLeave.new
    end
    respond_to do |format|
      format.js { render :action => 'new' }
    end
  end

  def create
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=="SubjectWise"
      @student = Student.find(params[:subject_leave][:student_id])
      @tte=TimetableEntry.find(params[:timetable_entry])
      @absentee = SubjectLeave.new(params[:subject_leave])
      @absentee.subject_id=params[:subject_leave][:subject_id]
      @absentee.employee_id=@tte.employee_id
      #      @absentee.subject_id=@tte.subject_id
      @absentee.class_timing_id=@tte.class_timing_id
      @absentee.batch_id = @student.batch_id

    else
      @student = Student.find(params[:attendance][:student_id])
      @absentee = Attendance.new(params[:attendance])
    end
    respond_to do |format|
      if @absentee.save
        #        sms_setting = SmsSetting.new()
        #        guardian_message = ""
        #        student_message = ""
        #        if sms_setting.application_sms_active and @student.is_sms_enabled and sms_setting.attendance_sms_active
        #          recipients = []
        #          unless @config.config_value=="SubjectWise"
        #            if @absentee.is_full_day
        #              guardian_message = "#{t('dear_parent')}, #{@student.first_and_last_name} #{t('flash_msg7')} #{@absentee.month_date}. #{t('thanks')}"
        #              student_message = "#{t('hi_you_are_marked_absent_on')} #{format_date(@absentee.month_date)}. #{t('thanks')}"
        #            elsif @absentee.forenoon == true and @absentee.afternoon == false
        #              guardian_message = "#{t('dear_parent')}, #{@student.first_and_last_name} #{t('flash_msg7')} #{@absentee.month_date} #{t('during_forenoon')}. #{t('thanks')}"
        #              student_message = "#{t('hi_you_are_marked_absent_on')} #{format_date(@absentee.month_date)} #{t('during_forenoon')}. #{t('thanks')}"
        #            elsif @absentee.afternoon == true and @absentee.forenoon == false
        #              guardian_message = "#{t('dear_parent')}, #{@student.first_and_last_name} #{t('flash_msg7')} #{@absentee.month_date} #{t('during_afternoon')}. #{t('thanks')}"
        #              student_message = "#{t('hi_you_are_marked_absent_on')} #{format_date(@absentee.month_date)} #{t('during_afternoon')}. #{t('thanks')}"
        #            end
        #          else
        #            guardian_message = "#{t('your_ward')} #{@student.first_and_last_name} #{t('flash_msg7')} #{@absentee.month_date} #{t('for_subject')} #{@absentee.subject.name} #{t('during_period')} #{@absentee.class_timing.try(:name)}. #{t('thanks')}"
        #            student_message = "#{t('hi_you_are_marked_absent_on')} #{format_date(@absentee.month_date)} #{t('for_subject')} #{@absentee.subject.name} #{t('during_period')} #{@absentee.class_timing.try(:name)}. #{t('thanks')}"
        #          end
        #          if sms_setting.student_sms_active
        #            recipients.push @student.phone2 unless @student.phone2.nil?
        #          end
        #          unless recipients.empty?
        #            Delayed::Job.enqueue(SmsManager.new(student_message,recipients))
        #            recipients = []
        #          end
        #          if sms_setting.parent_sms_active
        #            unless @student.immediate_contact_id.nil?
        #              guardian = Guardian.find(@student.immediate_contact_id)
        #              recipients.push guardian.mobile_phone unless guardian.mobile_phone.nil?
        #            end
        #          end
        #          unless recipients.empty?
        #            Delayed::Job.enqueue(SmsManager.new(guardian_message,recipients))
        #          end
        #        end
        format.js { render :action => 'create' }
      else
        @error = true
        format.html { render :action => "new" }
        format.js { render :action => 'create' }
      end
    end
  end

  def quick_attendance
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @student = Student.find(params[:id])
      @month_date = params[:date]
      @absentee = Attendance.new(:student_id=>@student.id,:batch_id=>@student.batch_id,:month_date=>@month_date,:forenoon=>true,:afternoon=>true,:reason => '-')
      #      if
      @absentee.save
      #        sms_setting = SmsSetting.new()
      #        guardian_message = ""
      #        student_message = ""
      #        if sms_setting.application_sms_active and @student.is_sms_enabled and sms_setting.attendance_sms_active
      #          recipients = []
      #          guardian_message = "#{t('dear_parent')}, #{@student.first_and_last_name} #{t('flash_msg7')} #{@absentee.month_date}. #{t('thanks')}"
      #          student_message = "#{t('hi_you_are_marked_absent_on')} #{@absentee.month_date}. #{t('thanks')}"
      #          if sms_setting.student_sms_active
      #            recipients.push @student.phone2 unless @student.phone2.nil?
      #          end
      #          unless recipients.empty?
      #            Delayed::Job.enqueue(SmsManager.new(student_message,recipients))
      #            recipients = []
      #          end
      #          if sms_setting.parent_sms_active
      #            unless @student.immediate_contact_id.nil?
      #              guardian = Guardian.find(@student.immediate_contact_id)
      #              recipients.push guardian.mobile_phone unless guardian.mobile_phone.nil?
      #            end
      #          end
      #          unless recipients.empty?
      #            Delayed::Job.enqueue(SmsManager.new(guardian_message,recipients))
      #          end
      #        end
      #      end
      
    else
      @student = Student.find(params[:id])
      @tte=TimetableEntry.find(params[:timetable_entry])
      @absentee=SubjectLeave.new(:student_id=>@student.id,:batch_id=>@student.batch_id,:month_date=>params[:date],:reason => '-')
      @absentee.subject_id=params[:subject_id]
      @absentee.employee_id=@tte.employee_id
      @absentee.class_timing_id=@tte.class_timing_id
      #      if
      @absentee.save
      #        sms_setting = SmsSetting.new()
      #        guardian_message = ""
      #        student_message = ""
      #        if sms_setting.application_sms_active and @student.is_sms_enabled and sms_setting.attendance_sms_active
      #          recipients = []
      #          guardian_message = "#{t('your_ward')} #{@student.first_and_last_name} #{t('flash_msg7')} #{@absentee.month_date} #{t('for_subject')} #{@absentee.subject.name} #{t('during_period')} #{@absentee.class_timing.try(:name)}. #{t('thanks')}"
      #          student_message = "#{t('hi_you_are_marked_absent_on')} #{@absentee.month_date} #{t('for_subject')} #{@absentee.subject.name} #{t('during_period')} #{@absentee.class_timing.try(:name)}. #{t('thanks')}"
      #          if sms_setting.student_sms_active
      #            recipients.push @student.phone2 unless @student.phone2.nil?
      #          end
      #          unless recipients.empty?
      #            Delayed::Job.enqueue(SmsManager.new(student_message,recipients))
      #            recipients = []
      #          end
      #          if sms_setting.parent_sms_active
      #            unless @student.immediate_contact_id.nil?
      #              guardian = Guardian.find(@student.immediate_contact_id)
      #              recipients.push guardian.mobile_phone unless guardian.mobile_phone.nil?
      #            end
      #          end
      #          unless recipients.empty?
      #            Delayed::Job.enqueue(SmsManager.new(guardian_message,recipients))
      #          end
      #        end
      #      end
    end
    respond_to do |format|
      format.js { render :action => 'quick_attendance' }
    end
  end

  def edit
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @absentee = Attendance.find params[:id]
    else
      @absentee = SubjectLeave.find params[:id]
    end
    @student = Student.find(@absentee.student_id)
    respond_to do |format|
      format.html { }
      format.js { render :action => 'edit' }
    end
  end

  def update
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @absentee = Attendance.find params[:id]
      @student = Student.find(@absentee.student_id)
      if @absentee.update_attributes(params[:attendance])
      else
        @error = true
      end
    else
      @absentee = SubjectLeave.find params[:id]
      @student = Student.find(@absentee.student_id)
      if @absentee.update_attributes(params[:subject_leave])
      else
        @error = true
      end
    end
    respond_to do |format|
      format.js { render :action => 'update' }
    end
  end


  def destroy
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value=='Daily'
      @absentee = Attendance.find params[:id]
    else
      @absentee = SubjectLeave.find params[:id]
      @tte_entry = TimetableEntry.find_by_subject_id_and_class_timing_id(@absentee.subject_id,@absentee.class_timing_id)
      sub=Subject.find @absentee.subject_id
    end
    @absentee.delete
    @student = Student.find(@absentee.student_id)
    respond_to do |format|
      format.js { render :action => 'update' }
    end
  end

end

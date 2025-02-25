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

class AttendanceReportsController < ApplicationController
  before_filter :login_required
  filter_access_to :all, :except=>[:index, :subject, :mode, :show, :year, :report, :filter, :student_details,:report_pdf,:filter_report_pdf,:day_wise_report,:day_wise_report_filter_by_course,:daily_report_batch_wise]
  filter_access_to [:index, :subject, :mode, :show, :year, :report, :filter, :student_details,:report_pdf,:filter_report_pdf,:day_wise_report,:day_wise_report_filter_by_course], :attribute_check=>true, :load_method => lambda { current_user }
  filter_access_to [:daily_report_batch_wise], :attribute_check=>true, :load_method => lambda { Batch.find params[:batch_id] }
  before_filter :default_time_zone_present_time
  before_filter :check_status


  def index
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if current_user.admin?
      @batches = Batch.active
    elsif @current_user.privileges.map{|p| p.name}.include?('StudentAttendanceView')
      @batches = Batch.active
    elsif @current_user.employee?
      if @config.config_value == 'Daily'
        @batches=@current_user.employee_record.batches
      else
        @batches=@current_user.employee_record.batches
        @batches+=@current_user.employee_record.subjects.collect{|b| b.batch}
        @batches=@batches.uniq unless @batches.empty?
      end
    end
    @config = Configuration.find_by_config_key('StudentAttendanceType')
  end

  def subject
    @batch = Batch.find params[:batch_id] unless params[:batch_id]==""
    if params[:batch_id] != ""
      if @current_user.employee?
        @role_symb = @current_user.role_symbols
        if @role_symb.include?(:student_attendance_view) or @role_symb.include?(:student_attendance_register)
          @subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>'is_deleted = false')
        else
          if @batch.employee_id.to_i==@current_user.employee_record.id
            @subjects= @subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>'is_deleted = false')
          else
            @subjects= Subject.find(:all,:joins=>"INNER JOIN employees_subjects ON employees_subjects.subject_id = subjects.id AND employee_id = #{@current_user.employee_record.id} AND batch_id = #{@batch.id} AND is_deleted = false")
          end
        end
      else
        @subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>'is_deleted = false')
      end
    end

    render :update do |page|
      page.replace_html 'subject', :partial => 'subject' if params[:batch_id] !=""
      page.replace_html 'subject','' if params[:batch_id]==""
      page.replace_html 'mode',''
      page.replace_html 'month',''
      page.replace_html 'year',''
      page.replace_html 'report',''
    end
  end

  def mode
    @batch = Batch.find params[:batch_id] unless params[:batch_id]==""
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value == 'Daily'
      unless params[:subject_id] == ''
        @subject = params[:subject_id]
      else
        @subject = 0
      end
      render :update do |page|
        page.replace_html 'mode', :partial => 'mode' unless params[:batch_id]==""
        page.replace_html 'mode',:partial => '' if params[:batch_id]==""
        page.replace_html 'month',''
        page.replace_html 'year',''
        page.replace_html 'report',''
      end
    else
      if params[:subject_id] ==''
        render :update do |page|
          page.replace_html 'mode', :text => ''
          page.replace_html 'month',''
          page.replace_html 'year',''
          page.replace_html 'report',''
        end
      else
        unless params[:subject_id] == 'all_sub'
          @subject = params[:subject_id]
        else
          @subject = 0
        end
        render :update do |page|
          page.replace_html 'mode', :partial => 'mode' unless params[:batch_id]==""
          page.replace_html 'mode', '' if params[:batch_id]==""
          page.replace_html 'month',''
          page.replace_html 'year',''
          page.replace_html 'report',''
        end
      end
    end
  end
  def show
    @batch = Batch.find params[:batch_id]
    @start_date = @batch.start_date.to_date
    @end_date = @local_tzone_time.to_date
    @leaves=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @mode = params[:mode]
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @students = @batch.students.by_first_name
    unless @config.config_value == 'Daily'
      if @mode == 'Overall'
        unless params[:subject_id] == '0'
          @subject = Subject.find params[:subject_id]
          unless @subject.elective_group_id.nil?
            @students = @subject.students.by_first_name
          end
          @academic_days=@batch.subject_hours(@start_date, @end_date, params[:subject_id].to_i).values.flatten.compact.count
          @subject = Subject.find params[:subject_id]
          @grouped = @batch.subject_leaves.find(:all,  :conditions =>{:subject_id => @subject.id, :batch_id=>@batch.id,:month_date => @start_date..@end_date}).group_by(&:student_id)
          @report = @batch.subject_leaves.find(:all,:conditions =>{:subject_id => @subject.id, :batch_id=>@batch.id,:month_date => @start_date..@end_date})
          @students.each do |s|
            if @grouped[s.id].nil?
              @leaves[s.id]['leave']=0
            else
              @leaves[s.id]['leave']=@grouped[s.id].count
            end
            @leaves[s.id]['total'] = (@academic_days - @leaves[s.id]['leave'])
            @leaves[s.id]['percent'] = (@leaves[s.id]['total'].to_f/@academic_days)*100 unless @academic_days == 0
          end
        else
          @academic_days=@batch.subject_hours(@start_date, @end_date, 0).values.flatten.compact.count
          @report = @batch.subject_leaves.find(:all,:conditions =>{:batch_id=>@batch.id,:month_date => @start_date..@end_date})
          @grouped = @batch.subject_leaves.find(:all,  :conditions =>{:batch_id=>@batch.id,:month_date => @start_date..@end_date}).group_by(&:student_id)
          @students.each do |s|
            if @grouped[s.id].nil?
              @leaves[s.id]['leave']=0
            else
              @leaves[s.id]['leave']=@grouped[s.id].count
            end
            @leaves[s.id]['total'] = (@academic_days - @leaves[s.id]['leave'])
            @leaves[s.id]['percent'] = (@leaves[s.id]['total'].to_f/@academic_days)*100 unless @academic_days == 0
          end
        end
        render :update do |page|
          page.replace_html 'report', :partial => 'report' unless params[:mode]==""
          page.replace_html 'month', '' if params[:mode]=="" or params[:mode]=="Overall"
          page.replace_html 'year', '' if params[:mode]=="" or params[:mode]=="Overall"
          page.replace_html 'report','' if params[:mode]==""
        end
      else
        @year = @local_tzone_time.to_date.year
        @academic_days=@batch.working_days(@local_tzone_time.to_date).count
        @subject = params[:subject_id]
        render :update do |page|
          page.replace_html 'month', :partial => 'month' unless params[:mode]==""
          page.replace_html 'month', '' if params[:mode]==""
          page.replace_html 'year', '' if params[:mode]==""
          page.replace_html 'report','' if params[:mode]==""
        end
      end
    else
      if @mode == 'Overall'
        @academic_days=@batch.academic_days.count
        leaves_forenoon=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:forenoon=>true,:afternoon=>false,:month_date => @start_date..@end_date},:group=>:student_id)
        leaves_afternoon=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:forenoon=>false,:afternoon=>true,:month_date => @start_date..@end_date},:group=>:student_id)
        leaves_full=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:forenoon=>true,:afternoon=>true,:month_date => @start_date..@end_date},:group=>:student_id)
        @students.each do |student|
          @leaves[student.id]['total']=@academic_days-leaves_full[student.id].to_f-(0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
          @leaves[student.id]['percent'] = (@leaves[student.id]['total'].to_f/@academic_days)*100 unless @academic_days == 0
        end
        render :update do |page|
          page.replace_html 'report', :partial => 'report' unless params[:mode]==""
          page.replace_html 'report','' if params[:mode]==""
          page.replace_html 'month', :text => ''
          page.replace_html 'year', :text => ''
        end
      else
        @year = @local_tzone_time.to_date.year
        @subject = params[:subject_id]
        render :update do |page|
          page.replace_html 'month', :partial => 'month' unless params[:mode]==""
          page.replace_html 'month','' if params[:mode]==""
          page.replace_html 'year','' if params[:mode]==""
          page.replace_html 'report','' if params[:mode]==""
        end
      end
    end
  end
  def year
    @batch = Batch.find params[:batch_id]
    @subject = params[:subject_id]
    @mode = params[:mode]
    if request.xhr?
      @year = @local_tzone_time.to_date.year
      @month = params[:month]
      render :update do |page|
        page.replace_html 'year', :partial => 'year'
        page.replace_html 'report',''
      end
    end
  end

  def report2
    @batch = Batch.find params[:batch_id]
    @month = params[:month]
    @year = params[:year]
    @students = @batch.students.by_first_name
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    #    @date = "01-#{@month}-#{@year}"
    @date = '01-'+@month+'-'+@year
    @start_date = @date.to_date
    @today = @local_tzone_time.to_date
    working_days=@batch.working_days(@date.to_date)
    unless @start_date > @local_tzone_time.to_date
      if @month == @today.month.to_s
        @end_date = @local_tzone_time.to_date
      else
        @end_date = @start_date.end_of_month
      end
      @academic_days=  working_days.select{|v| v<=@end_date}.count
      if @config.config_value == 'Daily'
        @report = @batch.attendances.find(:all,:conditions =>{:month_date => @start_date..@end_date})
      else
        unless params[:subject_id] == '0'
          @subject = Subject.find params[:subject_id]
          @report = SubjectLeave.find_all_by_subject_id(@subject.id,  :conditions =>{:batch_id=>@batch.id,:month_date => @start_date..@end_date})
        else
          @report = @batch.subject_leaves.find(:all,:conditions =>{:batch_id=>@batch.id,:month_date => @start_date..@end_date})
        end
      end
    else
      @report = ''
    end
    render :update do |page|
      page.replace_html 'report', :partial => 'report'
    end
  end

  def report
    @batch = Batch.find params[:batch_id]
    @month = params[:month]
    @year = params[:year]
    @mode = params[:mode]
    @students = @batch.students.by_first_name
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    #    @date = "01-#{@month}-#{@year}"
    unless @year==""
      @date = '01-'+@month+'-'+@year
      @start_date = @date.to_date
      @today = @local_tzone_time.to_date
      if (@start_date<@batch.start_date.to_date.beginning_of_month || @start_date>@batch.end_date.to_date || @start_date>=@today.next_month.beginning_of_month)
        render :update do |page|
          page.replace_html 'report', :text => t('no_reports')
        end
      else
        @leaves=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
        working_days=@batch.working_days(@date.to_date)
        unless @start_date > @local_tzone_time.to_date
          if @month == @today.month.to_s
            @end_date = @local_tzone_time.to_date
          else
            @end_date = @start_date.end_of_month
          end
          if @config.config_value == 'Daily'
            @academic_days=  working_days.select{|v| v<=@end_date}.count
            @students = @batch.students.by_first_name
            leaves_forenoon=Attendance.count(:all,:joins=>:student,:conditions=>{:batch_id=>@batch.id,:forenoon=>true,:afternoon=>false,:month_date => @start_date..@end_date},:group=>:student_id)
            leaves_afternoon=Attendance.count(:all,:joins=>:student,:conditions=>{:batch_id=>@batch.id,:forenoon=>false,:afternoon=>true,:month_date => @start_date..@end_date},:group=>:student_id)
            leaves_full=Attendance.count(:all,:joins=>:student,:conditions=>{:batch_id=>@batch.id,:forenoon=>true,:afternoon=>true,:month_date => @start_date..@end_date},:group=>:student_id)
            @students.each do |student|
              @leaves[student.id]['total']=@academic_days-leaves_full[student.id].to_f-(0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
              @leaves[student.id]['percent'] = (@leaves[student.id]['total'].to_f/@academic_days)*100 unless @academic_days == 0
            end
          else
            unless params[:subject_id] == '0'
              @subject = Subject.find params[:subject_id]
              unless @subject.elective_group_id.nil?
                @students = @subject.students.by_first_name
              end
              @academic_days=@batch.subject_hours(@start_date, @end_date, params[:subject_id].to_i).values.flatten.compact.count
              @report = SubjectLeave.find_all_by_subject_id(@subject.id,  :conditions =>{:batch_id=>@batch.id,:month_date => @start_date..@end_date})
              @grouped = SubjectLeave.find_all_by_subject_id(@subject.id,  :conditions =>{:batch_id=>@batch.id,:month_date => @start_date..@end_date}).group_by(&:student_id)
              @students.by_first_name.each do |s|
                if @grouped[s.id].nil?
                  @leaves[s.id]['leave']=0
                else
                  @leaves[s.id]['leave']=@grouped[s.id].count
                end
                @leaves[s.id]['total'] = (@academic_days - @leaves[s.id]['leave'])
                @leaves[s.id]['percent'] = (@leaves[s.id]['total'].to_f/@academic_days)*100 unless @academic_days == 0
              end
            else
              @academic_days=@batch.subject_hours(@start_date, @end_date, 0).values.flatten.compact.count
              @report = @batch.subject_leaves.find(:all,:conditions =>{:month_date => @start_date..@end_date})
              @grouped = @batch.subject_leaves.find(:all,  :conditions =>{:month_date => @start_date..@end_date}).group_by(&:student_id)
              @batch.students.by_first_name.each do |s|
                if @grouped[s.id].nil?
                  @leaves[s.id]['leave']=0
                else
                  @leaves[s.id]['leave']=@grouped[s.id].count
                end
                @leaves[s.id]['total'] = (@academic_days - @leaves[s.id]['leave'])
                @leaves[s.id]['percent'] = (@leaves[s.id]['total'].to_f/@academic_days)*100 unless @academic_days == 0
              end
            end
          end
        else
          @report = ''
        end
        render :update do |page|
          page.replace_html 'report', :partial => 'report' unless params[:year]==""

        end
      end
    else
      render :update do |page|

        page.replace_html 'report','' if params[:year]==""
      end
    end
  end

  def student_details
    @student = Student.find params[:id]
    @batch = @student.batch
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value == 'Daily'
      @report = Attendance.find(:all,:conditions=>{:student_id=>@student.id,:batch_id=>@batch.id})
    else
      unless params[:subject_id].to_i == 0
        @report = SubjectLeave.find(:all,:conditions=>{:student_id=>@student.id,:batch_id=>@batch.id, :subject_id => params[:subject_id]})
      else
        @report = SubjectLeave.find(:all,:conditions=>{:student_id=>@student.id,:batch_id=>@batch.id})
      end
    end
  end

  def filter
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @batch = Batch.find(params[:filter][:batch])
    @students = @batch.students.by_first_name
    @start_date = (params[:filter][:start_date]).to_date
    @end_date = (params[:filter][:end_date]).to_date
    @range = (params[:filter][:range])
    @value = (params[:filter][:value])
    @leaves=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    #    @academic_days=  @working_days.select{|v| v<=@end_date}.count
    @today = @local_tzone_time.to_date
    @mode=params[:filter][:report_type]
    working_days=@batch.working_days(@start_date.to_date)
    if request.post?
      unless @start_date > @local_tzone_time.to_date
        unless @config.config_value == 'Daily'
          unless params[:filter][:subject] == '0'
            @subject = Subject.find params[:filter][:subject]
            @academic_days=@batch.subject_hours(@start_date, @end_date, params[:filter][:subject].to_i).values.flatten.compact.count
            @report = SubjectLeave.find_all_by_subject_id(@subject.id,  :conditions =>{:batch_id=>@batch.id,:month_date => @start_date..@end_date})
            @grouped = SubjectLeave.find_all_by_subject_id(@subject.id,  :conditions =>{:batch_id=>@batch.id,:month_date => @start_date..@end_date}).group_by(&:student_id)
            unless @subject.elective_group_id.nil?
              @students=@subject.students.by_first_name
            end
            @students.each do |s|
              if @grouped[s.id].nil?
                @leaves[s.id]['leave']=0
              else
                @leaves[s.id]['leave']=@grouped[s.id].count
              end
              @leaves[s.id]['total'] = (@academic_days - @leaves[s.id]['leave'])
              @leaves[s.id]['percent'] = (@leaves[s.id]['total'].to_f/@academic_days)*100 unless @academic_days == 0
            end
          else
            @academic_days=@batch.subject_hours(@start_date, @end_date, 0).values.flatten.compact.count
            @report = @batch.subject_leaves.find(:all,:conditions =>{:month_date => @start_date..@end_date})
            @grouped = @batch.subject_leaves.find(:all,  :conditions =>{:month_date => @start_date..@end_date}).group_by(&:student_id)
            @batch.students.by_first_name.each do |s|
              if @grouped[s.id].nil?
                @leaves[s.id]['leave']=0
              else
                @leaves[s.id]['leave']=@grouped[s.id].count
              end
              @leaves[s.id]['total'] = (@academic_days - @leaves[s.id]['leave'])
              @leaves[s.id]['percent'] = (@leaves[s.id]['total'].to_f/@academic_days)*100 unless @academic_days == 0
            end
          end
        else
          if @mode=='Overall'
            #            @working_days=@batch.academic_days.count
            @academic_days=@batch.academic_days.count
          else
            working_days=@batch.working_days(@start_date.to_date)
            #            @working_days=  working_days.select{|v| v<=@end_date}.count
            @academic_days=  working_days.select{|v| v<=@end_date}.count
          end
          #          unless @subject.elective_group_id.nil?
          #            @students=@subject.students.by_first_name
          #          end
          leaves_forenoon=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:forenoon=>true,:afternoon=>false,:month_date => @start_date..@end_date},:group=>:student_id)
          leaves_afternoon=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:forenoon=>false,:afternoon=>true,:month_date => @start_date..@end_date},:group=>:student_id)
          leaves_full=Attendance.count(:all,:conditions=>{:batch_id=>@batch.id,:forenoon=>true,:afternoon=>true,:month_date => @start_date..@end_date},:group=>:student_id)
          @students.each do |student|
            @leaves[student.id]['total']=@academic_days-leaves_full[student.id].to_f-(0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
            @leaves[student.id]['percent'] = (@leaves[student.id]['total'].to_f/@academic_days)*100 unless @academic_days == 0
          end
          #          @report = @batch.attendances.find(:all,:conditions =>{:month_date => @start_date..@end_date})
          #          @report = @batch.attendances.find(:all,:conditions =>{:month_date => @start_date..@end_date})
        end
      end
    end
  end

  def filter2
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @batch = Batch.find(params[:filter][:batch])
    @students = @batch.students.by_first_name
    @start_date = (params[:filter][:start_date]).to_date
    @end_date = (params[:filter][:end_date]).to_date
    @range = (params[:filter][:range])
    @value = (params[:filter][:value])
    if request.post?
      unless @config.config_value == 'Daily'
        unless params[:filter][:subject] == '0'
          @subject = Subject.find params[:filter][:subject]
        end
        if params[:filter][:subject] == '0'
          @report = @batch.subject_leaves.find(:all,:conditions =>{:month_date => @start_date..@end_date})
        else
          @report = SubjectLeave.find_all_by_subject_id(@subject.id,  :conditions =>{:month_date => @start_date..@end_date})
        end
      else
        @report = @batch.attendances.find(:all,:conditions =>{:month_date => @start_date..@end_date})
      end
    end
  end

  def advance_search
    @batches = []
  end

  def report_pdf
    @data_hash = Attendance.fetch_student_attendance_data params
    render :pdf => 'report_pdf'
  end

  def filter_report_pdf
    @data_hash = Attendance.fetch_student_attendance_data params
    render :pdf => 'filter_report_pdf'
  end

  def day_wise_report
    @date = params[:date].nil? ? Date.today : params[:date]
    if current_user.admin? or (current_user.employee? and current_user.privileges.map{|p| p.name}.include?('StudentAttendanceView'))
      @batches =  Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
        :per_page => 10,:page =>params[:page],
        :order => "courses.course_name,batches.id",
        :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id",
        :include => :course,
        :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0"],
        :group => "batches.id")
      @courses = Course.active
      @active_courses = Course.active.all(:select => "course_name,count(batches.id)",
        :joins => ["LEFT OUTER JOIN batches ON courses.id = batches.course_id"],
        :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 "],
        :group => "course_id").collect(&:course_name)
    else
      @batches = Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
        :per_page => 10,:page =>params[:page],:order => "courses.course_name,batches.id",
        :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}' LEFT OUTER JOIN students ON attendances.student_id = students.id AND students.batch_id = batches.id LEFT OUTER JOIN batch_tutors ON batches.id = batch_tutors.batch_id",
        :include => :course,:conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batch_tutors.employee_id = #{current_user.employee_record.id}"],
        :group => "batches.id")
      @courses = current_user.employee_record.batches.all(:include => :course,:order => "courses.course_name",:conditions => {:is_deleted => false,:is_active => true,:'courses.is_deleted' => false}).collect(&:course).uniq
      @active_courses = @courses.collect(&:course_name)
    end
    @leave_count =  Attendance.all(:joins => ["INNER JOIN batches ON batches.id = attendances.batch_id INNER JOIN students ON attendances.student_id = students.id AND students.batch_id = batches.id"],
      :conditions=>{:month_date => "#{@date}",:'batches.is_deleted' => false,:'batches.is_active' => true}).count
    @students_count = Student.active.count
    @grouped_batches = @batches.to_a.group_by{|b| b.course_name}

    if request.xhr?
      render(:update) do |page|
        page.replace_html'report_details',:partial=>'report_details'
      end
    end
  end

  def day_wise_report_filter_by_course
    @date = params[:date].nil? ? Date.today : params[:date]
    if current_user.admin? or (current_user.employee? and current_user.privileges.map{|p| p.name}.include?('StudentAttendanceView'))
      if params[:course_id].present?
        @course = Course.find params[:course_id]
        @batches =  Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
          :per_page => 10,:page =>params[:page],
          :order => "courses.course_name,batches.id",
          :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id",
          :include => :course,
          :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batches.course_id = #{params[:course_id]}"],
          :group => "batches.id")
      else
        @batches =  Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
          :per_page => 10,:page =>params[:page],
          :order => "courses.course_name,batches.id",:joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id",
          :include => :course,
          :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0"],
          :group => "batches.id")
        @active_courses = Course.active.all(:select => "course_name,count(batches.id)",
          :joins => ["LEFT OUTER JOIN batches ON courses.id = batches.course_id"],
          :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 "],
          :group => "course_id").collect(&:course_name)
      end
    else
      if params[:course_id].present?
        @course = Course.find params[:course_id]
        @batches = Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
          :per_page => 10,:page =>params[:page],
          :order => "courses.course_name,batches.id",
          :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id LEFT OUTER JOIN batch_tutors ON batches.id = batch_tutors.batch_id",
          :include => :course,
          :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batch_tutors.employee_id = #{current_user.employee_record.id} AND batches.course_id = #{params[:course_id]}"],
          :group => "batches.id")
      else
        @batches = Batch.paginate(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
          :per_page => 10,:page =>params[:page],
          :order => "courses.course_name,batches.id",
          :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{@date}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id LEFT OUTER JOIN batch_tutors ON batches.id = batch_tutors.batch_id",
          :include => :course,
          :conditions => ["'#{@date}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batch_tutors.employee_id = #{current_user.employee_record.id}"],
          :group => "batches.id")
        @active_courses = current_user.employee_record.batches.all(:include => :course,:order => "courses.course_name",:conditions => {:is_deleted => false,:is_active => true,:'courses.is_deleted' => false}).collect(&:course).uniq.collect(&:course_name)
      end
    end
    @grouped_batches = @batches.to_a.group_by{|b| b.course_name}
    render(:update) do |page|
      page.replace_html'list',:partial=>'list_batches'
    end
  end

  def daily_report_batch_wise
    @date = params[:date].nil? ? Date.today : params[:date]
    @batch = Batch.find params[:batch_id]
    @students = Student.paginate(:per_page => 10,:page => params[:page],:joins => :attendances,:conditions => "students.batch_id = #{params[:batch_id]} AND attendances.month_date = '#{@date}'")
    @absentees_count = Attendance.all(:joins => :student, :conditions => {:batch_id => params[:batch_id],:month_date => params[:date], :'students.batch_id' => params[:batch_id]}).count
    if request.xhr?
      render(:update) do |page|
        page.replace_html'students_list',:partial=>'list_students'
      end
    end
  end

  def in_out_attendance
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @date_today = @local_tzone_time.to_date
    @dates = ((Date.today - 1.year)..(Date.today)).map{|c| "#{c.strftime("%B-%Y")}"}.uniq
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

  def get_in_out_attendance_report
    @error = nil
    if params["advance_search"]["date"].present? && params["advance_search"]["batch_id"].present?
      @header, @data, @result = StudentAttendance.get_attendance_hash(params["advance_search"])
    else
      @error = "Please select date and batch"
    end
      respond_to do |format|
        format.js { render 'get_in_out_attendance_report' }
      end
  end

  def get_in_out_attendance_pdf_report
    @header, @data, @result = StudentAttendance.get_attendance_hash(params["advance_search"])
    render :pdf => 'get_in_out_attendance_pdf_report',
            :layout => false,
            :zoom => 0.68,
            :orientation => :landscape,
            :page_size =>  'A1'    
  end

  def employee_in_out_attendance
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @date_today = @local_tzone_time.to_date
    @dates = ((Date.today - 1.year)..(Date.today)).map{|c| "#{c.strftime("%B-%Y")}"}.uniq
    @departments =  EmployeeDepartment.all
  end

  def get_employee_in_out_attendance_report
    @error = nil
    if params["advance_search"]["date"].present? && params["advance_search"]["department_id"].present?
      @date = "1-#{params["advance_search"]["date"]}".to_date
      @department = EmployeeDepartment.find_by_id params["advance_search"]["department_id"].to_i
    else
      @error = "Please select date and department"
    end
  end


  def employee_in_out_attendance_pdf_report
    @date = "1-#{params["advance_search"]["date"]}".to_date
    @department = EmployeeDepartment.find_by_id params["advance_search"]["department_id"].to_i
    render :pdf => 'employee_in_out_attendance_pdf_report',
        :layout => false,
        :zoom => 0.68,
        :orientation => :landscape,
        :page_size =>  'A1'
  end

  def individual_employee_in_out_attendance
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @date_today = @local_tzone_time.to_date
    @dates = ((Date.today - 1.year)..(Date.today)).map{|c| "#{c.strftime("%B-%Y")}"}.uniq
    @departments =  EmployeeDepartment.all

    @department_changed = params["advance_search"]["department_changed"] == "true" rescue false
    if @department_changed
      @department =  EmployeeDepartment.find params["advance_search"]["department_id"].to_i
      @employees = @department.employees
    end
    if !@department_changed && params[:advance_search].present?
      @employee = Employee.find_by_id(params["advance_search"]["employee_id"])
      @start_date = ("1-" + params["advance_search"]["date"]).to_date.beginning_of_day
      @end_date = @start_date.end_of_month
      @student_attendances = StudentAttendance.find(:all, :conditions => {:employee_id => @employee.id, :created_at => @start_date..@end_date})
      render :layout => false
      # @student_attendances = StudentAttendance.find(:all, :conditions => {:employee_id => @employee.id, :created_at => @start_date..@start_date.end_of_year})
      # debugger if @student_attendances.present?
    end
  end

  def individual_employee_in_out_attendance_pdf
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    @date_today = @local_tzone_time.to_date
    @dates = ((Date.today - 1.year)..(Date.today)).map{|c| "#{c.strftime("%B-%Y")}"}.uniq

    @employee = Employee.find_by_id(params["id"])
    @start_date = params["date"].to_datetime
    @end_date = @start_date.end_of_month
    @student_attendances = StudentAttendance.find(:all, :conditions => {:employee_id => @employee.id, :created_at => @start_date..@end_date})

    render :pdf => 'individual_employee_in_out_attendance_pdf',
      :zoom => 0.68,:orientation => :landscape,
      :margin => {    :top=> 10,
                :bottom => 0,
                :left=> 2,
                :right => 2},
      :layout => false

  end

end

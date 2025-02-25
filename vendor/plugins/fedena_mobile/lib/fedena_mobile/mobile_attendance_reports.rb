module FedenaMobile
  module MobileAttendanceReports

    def self.included(base)
      base.instance_eval do
        before_filter :is_mobile_user?
      end
    end

    def student_attendance_view
      @config = Configuration.find_by_config_key('StudentAttendanceType')
      @student = Student.find(params[:id])
      date=Date.today
      batch=@student.batch
      start_date=batch.start_date.to_date
      end_date=Date.today.to_date
      if @config.config_value=="Daily"
        @academic_days=batch.academic_days.count
        leaves_forenoon=Attendance.count(:all,:conditions=>{:student_id=>@student.id,:forenoon=>true,:afternoon=>false,:month_date => start_date..end_date})
        leaves_afternoon=Attendance.count(:all,:conditions=>{:student_id=>@student.id,:forenoon=>false,:afternoon=>true,:month_date => start_date..end_date})
        leaves_full=Attendance.count(:all,:conditions=>{:student_id=>@student.id,:forenoon=>true,:afternoon=>true,:month_date => start_date..end_date})
        @leaves=Attendance.find(:all,:conditions=>{:student_id=>@student.id,:batch_id=>batch.id,:month_date => start_date..end_date})
        @present=@academic_days-leaves_forenoon*0.5-leaves_afternoon*0.5-leaves_full
        @percent=100*(@present/@academic_days)
      else
        @subjects=batch.subjects.all(:conditions=>{:elective_group_id=>nil})
        @subjects+=@student.subjects
        unless @subjects.empty?
          @subject=@subjects.first
          @academic_days=batch.subject_hours(start_date, end_date, @subject.id).values.flatten.compact.count
          @leaves = SubjectLeave.find(:all,:conditions=>{:subject_id=>@subject.id,:batch_id=>batch.id,:student_id=>@student.id, :month_date => start_date..end_date})
          @present=@academic_days-@leaves.count.to_f
          @percent=100*(@present/@academic_days)
        end
      end
      @page_title=t('attendance_report')
      render :layout =>"mobile"
    end
    def update_student_mobile_view
      @config = Configuration.find_by_config_key('StudentAttendanceType')
      @student = Student.find(params[:id])
      date=Date.today
      batch=@student.batch
      start_date=batch.start_date.to_date
      end_date=Date.today.to_date
      @subjects=batch.subjects.all(:conditions=>{:elective_group_id=>nil})
      @subjects+=@student.subjects
      @subject=Subject.find(params[:subject_id])
      @academic_days=batch.subject_hours(start_date, end_date, @subject.id).values.flatten.compact.count
      @leaves = SubjectLeave.find(:all,:conditions=>{:subject_id=>@subject.id,:batch_id=>batch.id,:student_id=>@student.id, :month_date => start_date..end_date})
      @present=@academic_days-@leaves.count.to_f
      @percent=100*(@present/@academic_days)
      render :update do |page|
        page.replace_html "report", :partial => "mobile_report"
      end
    end

    private

    def is_mobile_user?
      unless FedenaPlugin.can_access_plugin?("fedena_mobile")
        if FedenaMobile::MobileAttendanceReports.instance_methods.include?(action_name)
          flash[:notice]=t('flash_msg4')
          redirect_to :controller => 'user', :action => 'dashboard'
        end
      end
    end

  end
end

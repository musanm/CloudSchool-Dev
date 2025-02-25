module FedenaMobile
  module MobileAttendances

    def self.included(base)
      base.instance_eval do
        before_filter :is_mobile_user?
      end
    end

    def mobile_attendance
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

      if request.post?
        if params[:batch_id].present?
          @batch=Batch.find(params[:batch_id])
          if @config.config_value=="Daily"
            @students=@batch.students.by_first_name
            render :update do |page|
              page.replace_html "student_list", :partial => "students_list"
            end
          else
            unless params[:subject_id].present?
              if @batch.subjects.present?
                load_subjects
                @subject=@subjects.first
                @sub=@subject
                to_search = @sub.elective_group_id.nil? ? @sub.to_a : @sub.elective_group.subjects.active
                timetable = TimetableEntry.find(:all, :conditions => ["batch_id = ? and subject_id IN (?)", @batch.id, to_search.map(&:id)])
                if (timetable.present? or @sub.timetable_swaps.present?) and @subject.present?
                  load_subject_students
                else
                  @tt_error=true
                end
              end

              render(:update) do |page|
                page.replace_html 'subject_list', :partial=> 'subjects_list'
                page.replace_html "student_list", :partial => "students_list"
              end
            else
              @sub =Subject.find params[:subject_id]
              @batch=Batch.find(@sub.batch_id)
              @today = params[:next].present? ? params[:next].to_date : @local_tzone_time
              to_search = @sub.elective_group_id.nil? ? @sub.to_a : @sub.elective_group.subjects.active
              timetable = TimetableEntry.find(:all, :conditions => ["batch_id = ? and subject_id IN (?)", @batch.id, to_search.map(&:id)])
              if (timetable.present? or @sub.timetable_swaps.present?)
                load_subject_students
              else
                @tt_error=true
              end
              render :update do |page|
                page.replace_html "student_list", :partial => "students_list"
              end
            end
          end
        end
      else
        @batch=@batches.first
        if @config.config_value=="Daily"
          @students=@batch.students.by_first_name
        else
          unless @batch.subjects.empty?
            load_subjects
            @subject=@subjects.first
            @sub=@subject
            to_search = @sub.elective_group_id.nil? ? @sub.to_a : @sub.elective_group.subjects.active
            timetable = TimetableEntry.find(:all, :conditions => ["batch_id = ? and subject_id IN (?)", @batch.id, to_search.map(&:id)])
            if (timetable.present? or @sub.timetable_swaps.present?)
              load_subject_students
            else
              @tt_error=true
            end
          end
        end
        @page_title=t('attendance')
        render :layout =>"mobile"
      end
    end

    def mobile_leave
      @page_title=t('attendance')
      @student=Student.find(params[:id])
      @batch=@student.batch
      @config = Configuration.find_by_config_key('StudentAttendanceType')
      if @config.config_value=="Daily"
        @attendance=Attendance.new
      else
        @subject=Subject.find(params[:subject_id])
        #        date=Date.today.to_date
        date=@local_tzone_time.to_date
        @subject_hours=[]
        @subject_hours=Timetable.subject_tte(params[:subject_id],date) if (date >= @batch.start_date.to_date and date <= @batch.end_date.to_date)
        @attendance=SubjectLeave.new
      end
      if request.post?
        if @config.config_value=="Daily"
          @attendance=Attendance.new(params[:attendance])
          working_dates=@batch.working_days(@attendance.month_date.to_date)
          if working_dates.map(&:to_date).include? @attendance.month_date.to_date
            if @attendance.save
              @error=false
            else
              @error=true
            end
          else
            @error=true
            @attendance.errors.add_to_base("#{t('attendance_date_is_invalid')}")
          end
          if @error
            render :layout =>"mobile"
          else
            flash[:notice]="#{t('attendance_marked_for')} #{@student.full_name}"
            redirect_to :action => "mobile_attendance",:batch_id=>@batch.id
          end
        else
          @attendance=SubjectLeave.new(params[:attendance])
          @subject_hours=Timetable.subject_tte(params[:subject_id],@attendance.month_date)
          if params[:class_timing_ids]
            class_timings=params[:class_timing_ids]
            @error=false
            class_timings.each do |ct|
              @subject=Subject.find(params[:subject_id])
              @attendance=SubjectLeave.new(params[:attendance])
              @attendance.class_timing_id=ct
              @error=true unless @attendance.save
            end
            if @error
              render :layout =>"mobile"
            else
              flash[:notice]="#{t('attendance_marked_for')} #{@student.full_name}"
              redirect_to :action => "mobile_attendance",:batch_id=>@batch.id,:subject_id=>@subject.id
            end
          else
            @attendance.errors.add_to_base t("class_timings_empty")
            render :layout =>"mobile"
          end
        end
      else
        render :layout =>"mobile"
      end
    end

    def load_class_hours
      date=params[:date].to_date
      @subject_hours=[]
      batch=Subject.find(params[:subject_id]).batch
      @subject_hours=Timetable.subject_tte(params[:subject_id],date) if (date >= batch.start_date.to_date and date <= batch.end_date.to_date)
      render :update do |page|
        page.replace_html "class_hours" ,:partial => "subject_hours"
      end
    end
    private
    def load_subjects
      @subjects = @batch.subjects
      if @current_user.employee?  and !@current_user.privileges.map{|m| m.name}.include?("StudentAttendanceRegister")
        employee = @current_user.employee_record
        if @batch.employee_id.to_i == employee.id
          @subjects= @batch.subjects
        else
          subjects = Subject.find(:all,:joins=>"INNER JOIN employees_subjects ON employees_subjects.subject_id = subjects.id AND employee_id = #{employee.try(:id)} AND batch_id = #{@batch.id} ")
          swapped_subjects = Subject.find(:all, :joins => :timetable_swaps, :conditions => ["subjects.batch_id = ? AND timetable_swaps.employee_id = ?",@batch.id,employee.try(:id)])
          @subjects = (subjects + swapped_subjects).compact.flatten.uniq
        end
      end
    end
    
    def load_subject_students
      unless @sub.elective_group_id.nil?
        elective_student_ids = StudentsSubject.find_all_by_subject_id(@sub.id).map { |x| x.student_id }
        @students = @batch.students.with_name_admission_no_only.all(:conditions=>"FIND_IN_SET(id,\"#{elective_student_ids.split.join(',')}\")")
      else
        @students = @batch.students.with_name_admission_no_only
      end
    end

    def is_mobile_user?
      unless FedenaPlugin.can_access_plugin?("fedena_mobile")
        if FedenaMobile::MobileAttendances.instance_methods.include?(action_name)
          flash[:notice]=t('flash_msg4')
          redirect_to :controller => 'user', :action => 'dashboard'
        end
      end
    end
  end

end

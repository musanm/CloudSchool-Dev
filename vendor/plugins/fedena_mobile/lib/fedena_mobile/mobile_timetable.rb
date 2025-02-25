module FedenaMobile
  module MobileTimetable

    def self.included(base)
      base.instance_eval do
        before_filter :is_mobile_user?
      end
    end

    def student_mobile_view
      @student = Student.find(params[:id])
      date=Date.today
      @wday=date.wday
      batch=@student.batch
      @weekdays = batch.weekday_set.present? ? batch.weekday_set.weekday_ids : Array.new
      @entries=Timetable.tte_for_the_weekday(batch,@wday)
      @page_title=t('timetable_text')
      render :layout =>"mobile"
    end

    def update_student_mobile_view
      @student = Student.find(params[:id])
      batch=@student.batch
      @weekdays = batch.weekday_set.weekday_ids
      @wday=params[:wday]
      @entries=Timetable.tte_for_the_weekday(batch,@wday.to_i)
      render :update do |page|
        page.replace_html "timetable", :partial => "timetable"
      end
    end

    def employee_mobile_view
      @employee = current_user.employee_record
      date=Date.today
      @wday=date.wday
      @entries=Timetable.employee_tte(@employee,date)
      @page_title=t('timetable_text')
      render :layout =>"mobile"
    end
    
    def update_employee_mobile_view
      @employee = Employee.find(params[:id])
      date=Date.today
      day=date.wday
      wday=params[:wday].to_i
      diff=day-wday
      @wday=date-diff.days
      @entries=Timetable.employee_tte(@employee,@wday)
      render :update do |page|
        page.replace_html "timetable", :partial => "employee_mobile_timetable"
      end
    end

    private

    def is_mobile_user?
      unless FedenaPlugin.can_access_plugin?("fedena_mobile")
        if FedenaMobile::MobileTimetable.instance_methods.include?(action_name)
          flash[:notice]=t('flash_msg4')
          redirect_to :controller => 'user', :action => 'dashboard'
        end
      end
    end

  end
end

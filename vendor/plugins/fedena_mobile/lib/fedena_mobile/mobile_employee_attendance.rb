module FedenaMobile
  module MobileEmployeeAttendance

    def self.included(base)
      base.instance_eval do
        before_filter :is_mobile_user?
      end
    end

    def mobile_leave
      @page_title=t('leave_application')
      @leave_types = EmployeeLeaveType.find(:all, :conditions=>"status = true")
      @employee = Employee.find(params[:id])
      @reporting_employees = Employee.find_all_by_reporting_manager_id(@employee.user_id)
      @total_leave_count = 0
      @leave_count = EmployeeLeave.find_all_by_employee_id(@employee,:joins=>:employee_leave_type,:conditions=>"status = true")
      @reporting_employees.each do |e|
        @app_leaves = ApplyLeave.count(:conditions=>["employee_id =? AND viewed_by_manager =?", e.id, false])
        @total_leave_count = @total_leave_count + @app_leaves
      end
      @leave_apply = ApplyLeave.new(params[:leave_apply])
      if request.post? and @leave_apply.save
        ApplyLeave.update(@leave_apply, :approved=> false, :viewed_by_manager=> false)
        flash[:notice]=t('flash5')
        redirect_to :controller => "employee_attendance", :action=> "mobile_leave", :id=>@employee.id
      else
        render :layout =>"mobile"
      end
    end

    private

    def is_mobile_user?
      unless FedenaPlugin.can_access_plugin?("fedena_mobile")
        if FedenaMobile::MobileEmployeeAttendance.instance_methods.include?(action_name)
          flash[:notice]=t('flash_msg4')
          redirect_to :controller => 'user', :action => 'dashboard'
        end
      end
    end
    
  end
end

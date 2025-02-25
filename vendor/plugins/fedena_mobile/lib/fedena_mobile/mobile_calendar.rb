# To change this template, choose Tools | Templates
# and open the template in the editor.

module FedenaMobile
  module MobileCalendar

    def self.included(base)
      base.instance_eval do
        before_filter :is_mobile_user?
      end
    end

    def mobile_index
      @date=Date.today
      @events=current_user.days_events(@date)
      @next_date=current_user.next_event(@date)
      @page_title=t("calender_text")
      render :layout =>"mobile"
    end

    def mobile_events_load
      if request.post?
        @date=params[:date].to_date
        @next_date=current_user.next_event(@date)
        @events=current_user.days_events(@date)
        render :update do |page|
          page.replace_html "reminders", :partial => "reminder_list"
          page.replace_html "footer_link", :partial => "footer_link"
        end
      end
    end

    private

    def is_mobile_user?
      unless FedenaPlugin.can_access_plugin?("fedena_mobile")
        if FedenaMobile::MobileCalendar.instance_methods.include?(action_name)
          flash[:notice]=t('flash_msg4')
          redirect_to :controller => 'user', :action => 'dashboard'
        end
      end
    end

  end
end

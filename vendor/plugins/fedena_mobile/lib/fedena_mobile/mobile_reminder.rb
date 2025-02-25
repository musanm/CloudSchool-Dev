# To change this template, choose Tools | Templates
# and open the template in the editor.

module FedenaMobile
  module MobileReminder

    def self.included(base)
      base.instance_eval do
        before_filter :is_mobile_user?
      end
    end

    def mobile_index
      @user = current_user
      @reminders = Reminder.paginate(:page => params[:page], :conditions=>["recipient = '#{@user.id}' and is_deleted_by_recipient = false"], :order=>"created_at DESC")
      @read_reminders = Reminder.find_all_by_recipient(@user.id, :conditions=>"is_read = true and is_deleted_by_recipient = false", :order=>"created_at DESC")
      @new_reminder_count = Reminder.find_all_by_recipient(@user.id, :conditions=>"is_read = false and is_deleted_by_recipient = false")
      @page_title=t('messages')
      @paginate = @reminders.count > 20
      #      @page = params[:page].to_i
      #      @page||= 1
      render :layout =>"mobile"
    end

    def mobile_view
      user = current_user
      @new_reminder = Reminder.find(params[:id2])
      Reminder.update(@new_reminder.id, :is_read => true)
      @sender = @new_reminder.user

      if request.post?
        unless params[:reminder][:body] == "" or params[:recipients] == ""
          Reminder.create(:sender=>user.id, :recipient=>@sender.id, :subject=>params[:reminder][:subject],
            :body=>params[:reminder][:body], :is_read=>false, :is_deleted_by_sender=>false,:is_deleted_by_recipient=>false)
          flash[:notice]="#{t('flash3')}"
          redirect_to :controller=>"reminder", :action=>"mobile_view", :id2=>params[:id2]
        else
          flash[:notice]="<b>ERROR:</b>#{t('flash4')}"
          redirect_to :controller=>"reminder", :action=>"mobile_view",:id2=>params[:id2]
        end
      end
      @page_title=t('messages')
      render :layout =>"mobile"
    end

    private

    def is_mobile_user?
      unless FedenaPlugin.can_access_plugin?("fedena_mobile")
        if FedenaMobile::MobileReminder.instance_methods.include?(action_name)
          flash[:notice]=t('flash_msg4')
          redirect_to :controller => 'user', :action => 'dashboard'
        end
      end
    end

  end
end

# To change this template, choose Tools | Templates
# and open the template in the editor.

module FedenaMobile
  module MobileUser

    def self.included(base)
      base.instance_eval do
        skip_before_filter :login_required,:only=>[:mobile_login,:mlogin]
        before_filter :mobile_login, :only=>[:login]
        before_filter :mobile_dash, :only=>[:dashboard]
        before_filter :is_mobile_user?
        layout :what_layout
      end
    end

    def mobile_login
      select_layout
      if @ret==true
        redirect_to :controller => 'user',:action=>:mlogin
        return
      end
    end

    def mobile_dash
      select_layout
      if @ret==true
        redirect_to :controller => 'user',:action=>:mobile_dashboard
        return
      end
    end

    def mlogin
      @institute = Configuration.find_by_config_key("LogoName")
      available_login_authes = FedenaPlugin::AVAILABLE_MODULES.select{|m| m[:name].camelize.constantize.respond_to?("login_hook")}
      selected_login_hook = available_login_authes.first if available_login_authes.count>=1
      if selected_login_hook
        authenticated_user = selected_login_hook[:name].camelize.constantize.send("login_hook",self)
      else
        if request.post? and params[:user]
          @user = User.new(params[:user])
          user = User.active.first(:conditions => ["username LIKE BINARY(?)",@user.username])
          if user.present? and User.authenticate?(@user.username, @user.password)
            authenticated_user = user
          end
        end
      end
      if authenticated_user.present?
        successful_mobile_login(authenticated_user) and return
      elsif authenticated_user.blank? and request.post?
        flash[:notice] = "#{t('login_error_message')}"
      end
    end

    def mobile_dashboard
      @user = current_user
    end

    def mobile_logout
      Rails.cache.delete("user_main_menu#{session[:user_id]}")
      Rails.cache.delete("user_autocomplete_menu#{session[:user_id]}")
      session[:user_id] = nil
      session[:language] = nil
      flash[:notice] = "#{t('logged_out')}"
      available_login_authes = FedenaPlugin::AVAILABLE_MODULES.select{|m| m[:name].camelize.constantize.respond_to?("logout_hook")}
      selected_logout_hook = available_login_authes.first if available_login_authes.count>=1
      if selected_logout_hook
        selected_logout_hook[:name].camelize.constantize.send("logout_hook",self,"/")
      else
        redirect_to :controller => 'user', :action => 'mlogin' and return
      end
    end

    def select_layout
      user_agents=["android","ipod","opera mini","opera mobi","blackberry","palm","hiptop","avantgo","plucker", "xiino","blazer","elaine", "windows ce; ppc;", "windows ce; smartphone;","windows ce; iemobile", "up.browser","up.link","mmp","symbian","smartphone", "midp","wap","vodafone","o2","pocket","kindle", "mobile","pda","psp","treo"]
      @ret=false
      if FedenaPlugin.can_access_plugin?("fedena_mobile")
        user_agents.each do |ua|
          if request.env["HTTP_USER_AGENT"].downcase=~ /#{ua}/i
            @ret=true
            return
          end
        end
      end
    end

    private

    def what_layout
      select_layout
      return 'login' if action_name == 'login' or action_name == 'set_new_password'
      return 'forgotpw' if action_name == 'forgot_password'
      return 'mobile' if action_name == 'mobile_dashboard'
      return 'mobile_login' if action_name == 'mlogin'
      return 'dashboard' if action_name == 'dashboard'
      return 'mobile'  if @ret==true
      'application'
    end


    def successful_mobile_login(user)
      session[:user_id] = user.id
      flash[:notice] = "#{t('welcome')}, #{user.first_name} #{user.last_name}!"
      redirect_to session[:back_url] || {:controller => 'user', :action => 'mobile_dashboard'}
    end

    def is_mobile_user?
      unless FedenaPlugin.can_access_plugin?("fedena_mobile")
        if FedenaMobile::MobileUser.instance_methods.include?(action_name)
          flash[:notice]=t('flash_msg4')
          redirect_to :controller => 'user', :action => 'dashboard'
        end
      end
    end
    
  end
end

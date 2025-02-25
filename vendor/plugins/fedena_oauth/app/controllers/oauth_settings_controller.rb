super_class = MultiSchoolController rescue ApplicationController #checks whether multi school environment or single school, creates ordinary class inheriting #Object if not multi school
class OauthSettingsController < super_class
  def settings
    @provider = params[:provider].blank? ?  nil : params[:provider].to_sym
    render :text=> "Provider name not given" and return unless @provider
    oauth_settings_object = FedenaOauth.auth_provider_settings[@provider]
    @owner = admin_user_session.school_group
    @settings = if(@owner.send "#{oauth_settings_object.model_name.underscore}")
      @owner.send "#{oauth_settings_object.model_name.underscore}"
    else
      @owner.send "build_#{oauth_settings_object.model_name.underscore}"
    end
    if request.post? or request.put?
      @settings.settings = params[oauth_settings_object.to_s.underscore.to_sym][:settings]
      render :update do |page|
        if @settings.save
          page.replace_html "content_div", "<label>Saved</label>"
        else
        end
      end
    else
      render :partial=>'settings'
    end

  end
end

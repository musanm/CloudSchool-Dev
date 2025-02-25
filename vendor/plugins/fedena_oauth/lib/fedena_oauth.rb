require 'dispatcher'
module FedenaOauth
  mattr_accessor :auth_provider_settings
  @@auth_provider_settings = {}

  def self.attach_overrides
    Dispatcher.to_prepare :fedena_oauth do
      FedenaOauth.generate_settings_model(:google) if(MultiSchool rescue nil)
      UserController.instance_eval { include OauthUserLogin }
      ApplicationController.instance_eval { include OauthApplication }
    end
  end
  
  def self.general_settings_checkbox
    "configuration/oauth"
  end

  def self.oauth_enabled?
    Configuration.get_config_value('EnableOauth')
  end

  def self.generate_settings_model(provider)
    if (AdditionalSetting rescue nil)
      settings_model_name = "#{provider}_oauth_setting".camelize
      settings_model = Object.const_set(settings_model_name, Class.new(AdditionalSetting)) rescue nil
      return unless settings_model
      @@auth_provider_settings[provider] = settings_model
      ["ClientSchoolGroup","MultiSchoolGroup"].each{|klass| klass.constantize.send :has_one, settings_model_name.underscore, :as=>:owner if (klass.constantize rescue nil)}
      case provider
      when :google
        settings_model.const_set('SETTING_FIELDS',[:client_key,:client_secret])
      end
      settings_model
    end
  end

  def self.oauth_settings(provider)
    oauth_config = oauth_setting =nil
    if File.exists?("#{Rails.root}/vendor/plugins/fedena_oauth/config/oauth_settings.yml")
      oauth_config = YAML.load_file(File.join(Rails.root,"vendor","plugins","fedena_oauth","config","oauth_settings.yml"))
    end
    if(@@auth_provider_settings[provider] rescue nil)
      oauth_assoc = @@auth_provider_settings[provider].to_s.underscore
      oauth_setting = ((MultiSchool.current_school.school_group.send oauth_assoc if MultiSchool.current_school).send :settings) rescue (oauth_config[provider.to_s] rescue nil)
    end
    if oauth_setting and oauth_setting[:client_key].present? and oauth_setting[:client_secret].present?
      oauth_setting
    else
      return (oauth_config[provider.to_s] rescue nil)
    end
  end
end

module OauthApplication
  def self.included(base)
    base.extend ClassMethods
    base.alias_method_chain :login_check,:oauth if ApplicationController.instance_methods.include? "login_check"
  end

  def login_check_with_oauth
    if session[:user_id].present?
      unless (controller_name == "user" or controller_name == "oauth") and ["first_login_change_password","login","logout","new","google_authenticate","list_users","login_user"].include? action_name
        user = User.find(session[:user_id])
        setting = Configuration.get_config_value('FirstTimeLoginEnable')
        if setting == "1" and user.is_first_login != false
          flash[:notice] = "#{t('first_login_attempt')}"
          redirect_to :controller => "user",:action => "first_login_change_password"
        end
      end
    end
  end

end

module OauthUserLogin

  def self.included(base)
    base.extend ClassMethods
    base.send :before_filter, :redirect_to_oauth, :only=>[:login]
  end


  def redirect_to_oauth
    @config = Configuration.get_config_value('EnableOauth')
    if @config == '1'
      if FedenaPlugin::AVAILABLE_MODULES.collect{|mod| mod[:name]}.include?('fedena_mobile')
        select_layout
        if @ret==true
          redirect_to :controller => 'user',:action=>:mlogin
          return
        end
      end
      redirect_to :controller=>"oauth", :action=>"login" if can_access_request?(:login,:oauth)
      return
    end
  end


end



require 'net/http'

class OauthController < ApplicationController
  layout :choose_layout

  # skip_before_filter :verify_authenticity_token (Not needed since oauth handles this)

  def choose_layout
    return 'oauth_login' if action_name == 'login'
    return 'list_users' if action_name == 'google_authenticate' or action_name == 'new'
    ''
  end

  def login
    check_for_file
    @institute = Configuration.find_by_config_key("LogoName")
    if request.post? and params[:user]
      @user = User.new(params[:user])
      user = User.active.first(:conditions => ["username LIKE BINARY(?)",@user.username])
      if user.present? and User.active.authenticate?(@user.username, @user.password)
        authenticated_user = user
      end
    end
    if authenticated_user.present?
      flash.clear
      successful_user_login(authenticated_user) and return
    elsif authenticated_user.blank? and request.post?
      flash[:notice] = "#{t('login_error_message')}"
    end
  end

  def new
    provider = params[:provider]
    client = get_client(provider)
    authorize_url = client.auth_code.authorize_url(:redirect_uri => client_redirect_url(provider), :response_type => 'code', :access_type => 'offline')
    redirect_to authorize_url + other_params(provider)
  end

  def google_authenticate

    client = get_client(:google)
    begin
      user_code = params[:code]
      token_request = client.auth_code.get_token(user_code, :redirect_uri => client_redirect_url(:google))
      token_request.options[:header_format] = "OAuth %s"
      token_string = token_request.token
      refresh_token = token_request.refresh_token
      users = User.active.find_all_by_google_access_token(token_string)
      unless users.present?
        user_email = fetch_email(token_string)
        all_users = User.find_all_by_email(user_email)
        users = all_users.select{|u| u.is_deleted==false }
        unless users.blank?
          unless users.size > 1
            user = users.first
            user.update_attributes(:google_access_token => token_string, :google_expired_at => token_request.expires_at)
            unless refresh_token.nil?
              user.update_attributes(:google_refresh_token => refresh_token)
            else
              ref_token_user = all_users.select{|usr| usr.google_refresh_token.present?}.first
              user.update_attributes(:google_refresh_token => ref_token_user.google_refresh_token) unless ref_token_user.nil?
            end
            #   user.update_attributes(:google_refresh_token => refresh_token) unless refresh_token.nil?
            successful_user_login(user)
          else
            users.each do |user|
              user.update_attributes(:google_access_token => token_string, :google_expired_at => token_request.expires_at)
              unless refresh_token.nil?
                user.update_attributes(:google_refresh_token => refresh_token)
              else
                ref_token_user = all_users.select{|usr| usr.google_refresh_token.present?}.first
                user.update_attributes(:google_refresh_token => ref_token_user.google_refresh_token) unless ref_token_user.nil?
              end
             # user.update_attributes(:google_refresh_token => refresh_token) unless refresh_token.nil?
            end
            @users = users
            render :action=>:list_users
          end
        else
          failed_login "#{t('no_user_with_email')}#{user_email}"
        end
        return
      end
      unless users.size > 1
        successful_user_login(users.first)
      else
        @users = users
        render :action=>:list_users
      end
    rescue OAuth2::Error => e
      failed_login "#{t('could_not_authenticate_with')}Google"
    end
  end


  def list_users

  end

  def login_user
    user = User.find params[:id]
    successful_user_login(user)
  end

  private

  # Maps OpenID sreg keys to fields of your user model.
  # - registration is a hash containing valid sreg keys
  def successful_user_login(user)
    session[:user_id] = user.id
    #    flash[:notice] = "#{t('welcome')}, #{user.first_name} #{user.last_name}!"
    redirect_to ((session[:back_url] unless (session[:back_url]) =~ /user\/logout$/) || {:controller => 'user', :action => 'dashboard'})
  end

  def failed_login(message)
    flash[:notice] = message
    redirect_to :action=>:login
  end

  def fetch_email(token_string)
    parsed_url = URI.parse(URI.encode("https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{token_string}"))
    http = Net::HTTP.new(parsed_url.host, parsed_url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(parsed_url.request_uri)
    response = http.request(request)
    profile = ActiveSupport::JSON.decode(response.body)
    return profile['email']
  end

  def get_client(provider)
    case provider.to_sym
    when :google
      return get_google_client
    else
      return nil
    end
  end

  def client_redirect_url(provider)
    case provider.to_sym
    when :google
      return url_for(:action => 'google_authenticate', :controller => 'oauth')
    else
      return nil
    end
  end

  def get_google_client
    oauth_settings = load_oauth_settings :google

    client_id = oauth_settings['client_key']
    client_secret = oauth_settings['client_secret']

    client = OAuth2::Client.new(client_id, client_secret,
      :authorize_url => '/o/oauth2/auth',
      :token_url => '/o/oauth2/token',
      :token_method     => :post,
      :site =>'https://accounts.google.com')
    return client
  end

  def other_params(provider)
    case provider.to_sym
    when :google
      return "&ltmpl=popup&scope=https://docs.google.com/feeds/ " +
        "https://docs.googleusercontent.com/ " +
        "https://spreadsheets.google.com/feeds/ " +
        "https://www.googleapis.com/auth/userinfo.email "+
        "https://www.googleapis.com/auth/userinfo.profile"
    else
      return ""
    end
  end

  def load_oauth_settings(provider)
    return FedenaOauth.oauth_settings provider
  end

  def check_for_file
    @config = Configuration.get_config_value('EnableOauth')
    if @config == '0'
      redirect_to :controller=>"user", :action=>"login"
      return
    end
  end

end

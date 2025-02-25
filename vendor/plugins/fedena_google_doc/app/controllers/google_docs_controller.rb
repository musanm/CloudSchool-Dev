require "rubygems"
require "google_drive"
require "google_drive/util"
require "oauth2"

class GoogleDocsController < ApplicationController
  before_filter :login_required
  before_filter :get_files, :except => :upload
  before_filter :get_session, :only => :upload

  CONTENT_TYPE_TO_EXT = {
    "application/x-shockwave-flash"=>".swf",
    "image/png"=>".png",
    "text/html"=>".html",
    "application/vnd.sun.xml.writer"=>".sxw",
    "application/vnd.ms-excel"=>".xls",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"=>".xlsx",
    "application/zip"=>".zip",
    "application/msword"=>".doc",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"=>".docx",
    "text/csv"=>".csv",
    "application/x-vnd.oasis.opendocument.spreadsheet"=>".ods",
    "application/rtf"=>".rtf",
    "application/vnd.oasis.opendocument.text"=>".odt",
    "text/tab-separated-values"=>".tsv",
    "text/plain"=>".txt",
    "application/pdf"=>".pdf",
    "application/vnd.ms-powerpoint"=>".ppt",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation"=>".pptx"
  }

  def index
  end

  def download
    file = get_file
#    unless file.available_content_types.first.to_s == "text/html"
#      file.download_to_file(file_path(file))
#      send_file(file_path(file))
#      File.delete(file_path(file))
#      return
#    else
      get_html_file(file)
#    end
  end

  def delete_file
    file = get_file
    file.delete(false)
    flash[:notice] = t('document_moved_to_trash')
    redirect_to :action => 'index'
  end

  def upload
    if request.post?
      if params[:document]
        f = params[:document][:file]
        name =  f.original_filename
        directory = "public/google_uploads"
        path = File.join(directory, name)
        File.open(path, "wb") { |file| file.write(f.read) }
        @session.upload_from_file("#{Rails.root}/#{path}", File.basename(name,File.extname(name)), {:convert => true })
        File.delete(path)
        flash[:notice] = "#{t('file_uploaded_successfully')}"
        redirect_to :action=>'upload'
      end
    end
  end

  private

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

  def load_oauth_settings(provider)
    return FedenaOauth.oauth_settings(provider)
  end

  def get_files
    get_session
    unless @session.nil?
      begin
        @files = @session.files
      rescue GoogleDrive::AuthenticationError || OAuth2::Error
        redirect_to :controller=>'user', :action=>'logout'
      end
    end
  end

  def get_session
    if current_user.respond_to?('google_refresh_token') || current_user.respond_to?('google_expired_at')
      if current_user.google_refresh_token.blank? or current_user.google_expired_at.blank?
        flash[:notice] = t('please_login_using_google')
        redirect_to :action => 'dashboard', :controller => "user" and return
      end
    else
      flash[:notice] = t('oauth_plugin_not_installed')
      redirect_to :action => 'dashboard', :controller => "user" and return
    end
    client = get_google_client
    access_token = OAuth2::AccessToken.from_hash(client,
      {:refresh_token => current_user.google_refresh_token, :expires_at => current_user.google_expired_at.to_i})
    access_token = access_token.refresh!
    current_user.update_attributes(:google_access_token => access_token.token, :google_expired_at => access_token.expires_at)
    @session = GoogleDrive.login_with_oauth(access_token)
  end

  def get_file
    file_url = params[:feed_url]
    return @files.select{|f| f.document_feed_url == file_url }.first
  end

  def file_path(file)
    "#{Rails.root}/public/google_docs/#{get_key(file.document_feed_url)}#{CONTENT_TYPE_TO_EXT[file.available_content_types.first.to_s]}"
  end

  def file_png_path(file)
    "#{Rails.root}/public/google_docs/#{get_key(file.document_feed_url)}.png"
  end

  def get_html_file(file)
    type = get_file_type(file.document_feed_url)
    key = get_key(file.document_feed_url)
    case type
    when "document"
      redirect_to "http://docs.google.com/document/export?format=doc&id=#{key}"
      return
    when "pdf"
      redirect_to "https://docs.google.com/uc?export=download&id=#{key}&hl=en_US"
      return
    when "presentation"
      redirect_to "http://docs.google.com/presentation/d/#{key}/export/ppt?format=ppt&id=#{key}"
      return
    when "spreadsheet"
      redirect_to "https://spreadsheets.google.com/feeds/download/spreadsheets/Export?key=#{key}&exportFormat=xls"
      return
    else
      file.download_to_file(file_png_path(file))
      send_file file_png_path(file)
    end
  end

  def get_key(feed_url)
    feed_url.split("%3A")[-1].split('?')[0]
  end

  def get_file_type(feed_url)
    feed_url.split("%3A")[-2].split('/').last
  end
end

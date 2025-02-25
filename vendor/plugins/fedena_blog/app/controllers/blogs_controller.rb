class BlogsController < ApplicationController
  before_filter :login_required
  before_filter :restrict_fedena_admin,:only => [:notification,:show_notification]
  before_filter :blog_profile,:except => [:notification,:show_notification,:activate_deactivate]
  filter_access_to :all
  
  def new
    if @current_user.blog.nil?
      flash[:notice] = t('flash1')
      @blog = Blog.new
    else
      redirect_to blog_blog_posts_path(@current_user.id)
    end
  end

  def create
    @blog = Blog.new(params[:blog])
    if @blog.save
      redirect_to my_blog_path
    else
      render :new
    end
  end

  def notification
    @user = @current_user
    @blog = @user.blog
    unless @blog.nil?
      @blog_comments = @blog.blog_posts.map{|bp| bp.blog_comments.showable.reject{|bc| bc.user == bp.blog.user}}.flatten.compact.sort!{|t1,t2|t1.created_at <=> t2.created_at}.reverse.paginate :per_page => 10,:page => params[:page]
    else
      flash[:notice] = t('flash1')
      redirect_to new_blog_path
    end
  end

  def show_notification
    @user = @current_user
    @blog = @user.blog
    @blog_comments = @blog.blog_posts.map{|bp| bp.blog_comments.showable.reject{|bc| bc.user == bp.blog.user}}.flatten.compact.sort!{|t1,t2|t1.created_at <=> t2.created_at}.reverse.paginate :per_page => 10,:page => params[:page]
    render :update do |page|
      page.replace_html 'list_notifications',:partial => "list_notifications"
    end
  end

  def edit
    @blog = @current_user.blog
    if @blog.nil?
      flash[:notice] = t('flash1')
      redirect_to blog_blog_posts_path(@current_user.id)
    end
  end

  def update
    @blog = @current_user.blog
    if @blog.update_attributes(params[:blog])
      flash[:notice] = t('flash_update')
      redirect_to my_blog_path
    else
      @user = current_user
      render :edit
    end
  end

  def activate_deactivate
    @blog = Blog.find(params[:id])
    if @blog.is_active == true
      @blog.update_attributes(:is_active => 0)
      flash[:notice] = t('blog_deactivated')
    else
      @blog.update_attributes(:is_active => 1)
      flash[:notice] = t('blog_activated')
    end
    redirect_to blog_directory_path(@blog.user_id)
  end
  

  private

  def blog_profile
    if params[:user_id]
      @user = User.find(params[:user_id])
    else
      @user ||= current_user
    end
    if @user.nil?
      flash[:notice] = t('flash_no_user')
      redirect_to
    end
    @blog = Blog.find_by_user_id(@user.id)
  end

  def restrict_fedena_admin
    if @current_user.admin?
      flash[:notice] = t('flash_admin')
      redirect_to :controller => "user",:action => "dashboard"
    end
  end
end

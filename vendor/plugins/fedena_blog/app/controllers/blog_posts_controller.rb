class BlogPostsController < ApplicationController
  include Juixe::Acts::Voteable::InstanceMethods
  extend  Juixe::Acts::Voteable::SingletonMethods
          
  before_filter :login_required
  before_filter :restrict_fedena_admin,:only => [:my_blog]
  before_filter :blog_profile,:except => [:index,:show,:like,:blog_like,:my_blog,:show_my_blog_posts,:new,:create,:search,:search_user_ajax,:show_all_recent_blog_posts,:show_all_blog_posts,:toggle_blog_posts,:ban_blog]
  filter_access_to :all,:except=>[:edit,:update]
  filter_access_to [:edit,:update], :attribute_check=>true
  
  in_place_edit_with_validation_for :blog_comment,:body
  
  def index
    @user = @current_user
    unless @current_user.privileges.map(&:name).include? "BlogAdmin" or @current_user.admin?
      @blog_posts = BlogPost.showable.first(50).paginate :per_page=> 10,:page => params[:page]
    else
      @blog_posts = BlogPost.showable_to_blog_admin.first(50).paginate :per_page=> 10,:page => params[:page]
    end
  end

  def new
    @blog = Blog.find(params[:blog_id])
    @user = @blog.user
    if @blog == @current_user.blog
      @blog_post = @blog.blog_posts.build
    else
      flash[:notice] = t('not_authorized')
      redirect_to my_blog_path
    end
  end

  def create
    @user = current_user
    @blog = @user.blog
    @blog_post = @blog.blog_posts.build(params[:blog_post])
    if params[:draft].nil?
      @blog_post.is_published = true
    elsif params[:publish].nil?
      @blog_post.is_published = 0
    end
    if @blog_post.save
      if params[:draft].nil?
        flash[:notice] =  t('flash3')
      else
        flash[:notice] =  t('flash2')
      end
      redirect_to my_blog_path
    else
      render :action => "new"
    end
  end

  def edit
    @blog_post = @blog.blog_posts.find(params[:id])
    unless @blog_post.is_owner? or @current_user.privileges.map(&:name).include? "BlogAdmin"
      flash[:notice] = t('not_authorized')
      redirect_to :controller => "user",:action => "dashboard"
    end
  end

  def update
    @blog_post = @blog.blog_posts.find(params[:id])
    if @blog_post.update_attributes(params[:blog_post])
      flash[:notice] = t('flash_edit')
      redirect_to my_blog_path(:user_id => @user.id)
    else
      render :edit
    end
  end

  def show
    blog_post_id = params[:title].split('-').last
    @blog_post = BlogPost.find_by_id(blog_post_id)
    @blog = @blog_post.blog
    if @blog_post.is_viewable?(@current_user) or @current_user.privileges.map(&:name).include?("BlogAdmin") or @current_user.admin?
      @blog_comment = @blog_post.blog_comments.build
      @blog_comments = @blog_post.blog_comments.showable.reject{|bc| bc.new_record?}.paginate :per_page=> 6,:page => params[:page]
    else
      flash[:notice] = t('flash_not_available')
      redirect_to :controller => 'user',:action => 'dashboard'
    end
  end

  def my_blog
    @user = @current_user
    @blog = @user.blog
    if @blog.nil?
      redirect_to new_blog_path
    else
      @blog_posts = @blog.blog_posts.showable_to_owner.paginate :per_page=> 10,:page => params[:page]
    end
  end

  def show_all_blog_posts
    @user = @current_user
    unless @current_user.privileges.map(&:name).include? "BlogAdmin"
      @blog_posts = BlogPost.showable.sort_by(&:total_likes).reject{|bp| bp.total_likes == 0}.reverse.first(50).paginate :per_page=> 10,:page => params[:page]
    else
      @blog_posts = BlogPost.showable_to_blog_admin.sort_by(&:total_likes).reject{|bp| bp.total_likes == 0}.reverse.first(50).paginate :per_page=> 10,:page => params[:page]
    end
    render :update do |page|
      page.replace_html 'list_blog_posts',:partial => "list_blog_posts"
    end
  end

  def show_my_blog_posts
    @user = current_user
    @blog = @user.blog
    @blog_posts = @blog.blog_posts.showable_to_owner.paginate :per_page=> 10,:page => params[:page]
    render :update do |page|
      page.replace_html 'list_blog_posts',:partial => "list_my_blog_posts"
    end
  end

  def show_all_recent_blog_posts
    @user = @current_user
    unless @current_user.privileges.map(&:name).include? "BlogAdmin" or @current_user.admin?
      @blog_posts = BlogPost.showable.first(50).paginate :per_page=> 10,:page => params[:page]
    else
      @blog_posts = BlogPost.showable_to_blog_admin.first(50).paginate :per_page=> 10,:page => params[:page]
    end
    render :update do |page|
      page.replace_html 'list_blog_posts',:partial => "list_all_recent_blog_posts"
    end
  end

  def toggle_blog_posts
    @user = @current_user
    render :update do |page|
      if params[:toggle_blog_post] == "latest"
        unless @current_user.privileges.map(&:name).include? "BlogAdmin"
          @blog_posts = BlogPost.showable.paginate :per_page=> 10,:page => params[:page]
        else
          @blog_posts = BlogPost.showable_to_blog_admin.paginate :per_page=> 10,:page => params[:page]
        end
        page.replace_html 'list_blog_posts',:partial => "list_all_recent_blog_posts"
      elsif params[:toggle_blog_post] == "popular"
        unless @current_user.privileges.map(&:name).include? "BlogAdmin"
          @blog_posts = BlogPost.showable.sort_by(&:total_likes).reject{|bp| bp.total_likes == 0}.reverse.paginate :per_page=> 10,:page => params[:page]
        else
          @blog_posts = BlogPost.showable_to_blog_admin.sort_by(&:total_likes).reject{|bp| bp.total_likes == 0}.reverse.paginate :per_page=> 10,:page => params[:page]
        end
        page.replace_html 'list_blog_posts',:partial => "list_blog_posts"
      end
    end
  end

  def publish_unpublish
    @blog_post = @blog.blog_posts.find(params[:id])
    status = @blog_post.is_published? ? 0 : 1
    @blog_post.update_attributes(:is_published => status)
    render :update do |page|
      @blog_posts = @blog.blog_posts.showable_to_owner.paginate :per_page=> 10,:page => params[:page]
      page.replace_html 'list_blog_posts',:partial => "list_my_blog_posts"
      if @blog_post.is_published==true
        page.replace_html 'flash_notice', :text=>"<p class='flash-msg'>#{t('blog_posts.published_successfully')}</p>"
      else
        page.replace_html 'flash_notice', :text=>"<p class='flash-msg'>#{t('blog_posts.unpublished_successfully')}</p>"
      end
    end
  end

  def activate_deactivate
    @blog_post = @blog.blog_posts.find(params[:id])
    status = @blog_post.is_active? ? 0 : 1
    @blog_post.update_attributes(:is_active => status)
    render :update do |page|
      @blog_posts = @blog.blog_posts.showable_to_blog_admin.paginate :per_page=> 3,:page => params[:page]
      if @blog_posts.blank?
        show_page = params[:page].to_i > 1 ? (params[:page].to_i - 1) : 1
        @blog_posts = @blog.blog_posts.showable_to_blog_admin.paginate :per_page=> 3,:page => show_page
      end
      page.replace_html 'list_blog_posts',:partial => "list_my_blog_posts"
    end
  end

  def delete
    @blog_post = @blog.blog_posts.find(params[:id])
    @blog_post.update_attributes(:is_deleted => true)
    render :update do |page|
      @blog_posts = @blog.blog_posts.showable_to_owner.paginate :per_page=> 10,:page => params[:page]
      if @blog_posts.blank?
        show_page = params[:page].to_i > 1 ? (params[:page].to_i - 1) : 1
        @blog_posts = @blog.blog_posts.showable_to_owner.paginate :per_page=> 10,:page => show_page
      end
      page.replace_html 'list_blog_posts',:partial => "list_my_blog_posts"
      page.replace_html 'flash_notice', :text=>"<p class='flash-msg'>#{t('blog_posts.blog_post_deleted_successfully')}</p>"
    end
  end

  def like
    @blog_post = BlogPost.find(params[:blog_id]) 
    @user = @current_user
    @user.vote_for(@blog_post) unless @user.voted_for?(@blog_post)
    render :update do |page|
      page.replace_html 'favourite_details',:partial => "favourite_details"
    end
  end

  def blog_like
    @blog_post = BlogPost.find(params[:blog_id])
    @user = @current_user
    @user.vote_for(@blog_post) unless @user.voted_for?(@blog_post)
    redirect_to blog_directory_path(@blog_post.blog.user_id,:page => params[:page])
  end

  def ban_blog
    @blog_post = BlogPost.find(params[:blog_id])
    @user = @current_user
    status = @blog_post.is_active == true ? false : true
    @blog_post.update_attributes(:is_active => status)
    if status == true
      flash[:notice] = t('unban_blog_post')
    else
      flash[:notice] = t('ban_blog_post')
    end
    unless params[:singlepost] == "true"
      redirect_to blog_directory_path(@blog_post.blog.user_id,:page => params[:page])
    else
      redirect_to show_blog_path(:user_id => @blog_post.blog.user.nil? ? "deleted_user" : @blog_post.blog.user_id,:title => "#{@blog_post.title.gsub('/','%2F').gsub('.','%20S').gsub('?',"%2G")}-#{@blog_post.id}")
    end
  end

  def search
    
  end

  def search_user_ajax
    unless params[:query].nil? or params[:query].empty? or params[:query] == ' '
      if params[:query].length>= 3
        if (current_user.privileges.map(&:name).include? "BlogAdmin" or current_user.admin?)
          @blogs=Blog.all(:select=>"users.*,blogs.name",:joins=>:user,:conditions=>["(blogs.is_published=1) and (first_name LIKE ? OR last_name LIKE ?  OR username LIKE ? OR blogs.name LIKE ? OR concat(users.first_name,' ',users.last_name) LIKE ? )","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%"])
        else
          @blogs=Blog.all(:select=>"users.*,blogs.name",:joins=>:user,:conditions=>["(blogs.is_active=1 and blogs.is_published=1) and (first_name LIKE ? OR last_name LIKE ?  OR username LIKE ? OR blogs.name LIKE ? OR concat(users.first_name,' ',users.last_name) LIKE ? )","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%"])
        end
      else
        if (current_user.privileges.map(&:name).include? "BlogAdmin" or current_user.admin?)
          @blogs=Blog.all(:select=>"users.*,blogs.name",:joins=>:user,:conditions=>["(blogs.is_published=1) and (first_name LIKE ? OR last_name LIKE ?  OR username LIKE ? OR blogs.name LIKE ? OR concat(users.first_name,' ',users.last_name) LIKE ? )","#{params[:query]}","#{params[:query]}","#{params[:query]}","#{params[:query]}","#{params[:query]}"])
        else
          @blogs=Blog.all(:select=>"users.*,blogs.name",:joins=>:user,:conditions=>["(blogs.is_active=1 and blogs.is_published=1) and (first_name LIKE ? OR last_name LIKE ?  OR username LIKE ? OR blogs.name LIKE ? OR concat(users.first_name,' ',users.last_name) LIKE ? )","#{params[:query]}","#{params[:query]}","#{params[:query]}","#{params[:query]}","#{params[:query]}"])
        end
      end
    else
      @blogs = ''
    end
    render :layout => false
  end

  def blog_directory
    if @current_user.privileges.map(&:name).include? "BlogAdmin" or @current_user.admin?
      @blog_posts = @blog.blog_posts.showable_to_blog_admin.paginate :per_page => 5,:page => params[:page]
    elsif @current_user == @blog.user
      @blog_posts = @blog.blog_posts.showable_to_owner.paginate :per_page => 5,:page => params[:page]
    elsif @blog.is_active 
      @blog_posts = @blog.blog_posts.showable.paginate :per_page => 5,:page => params[:page]
    else
      flash[:notice] = t('flash_not_available')
      redirect_to :controller => 'user',:action => 'dashboard'
    end
  end
  
  private
  
  def blog_profile
    if params[:user_id]
      @user = User.find(params[:user_id])
    elsif params[:blog_id]
      @user = User.find(params[:blog_id])
    else
      @user = @current_user
    end
    unless @user.nil?
      @blog = Blog.find_by_user_id(@user.id)
      if @blog.nil?
        flash[:notice] = t('flash_no_blog')
        redirect_to :controller => 'user',:action => 'dashboard'
      end
    else
      flash[:notice] = t('flash_no_user')
      redirect_to :controller => 'user',:action => 'dashboard'
    end
  end

  def restrict_fedena_admin
    if @current_user.admin?
      flash[:notice] = t('flash_admin')
      redirect_to :controller => "user",:action => "dashboard"
    end
  end
end

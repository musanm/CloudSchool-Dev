class BlogCommentsController < ApplicationController
  before_filter :login_required
  before_filter :restrict_fedena_admin
  before_filter :fetch_blog_post,:except => [:set_blog_comment_body]
  filter_access_to :all
  
  in_place_edit_with_validation_for :blog_comment,:body
  
  def create
    @blog_comment = @blog_post.blog_comments.build(params[:blog_comment])
    @error = false
    unless @blog_comment.save
      @error = true
    end
    respond_to do |format|
      @blog_comments = @blog_post.blog_comments.showable.paginate :per_page=> 6,:page => params[:page]
      format.js
    end
  end

  def delete
    @blog_comment = @blog_post.blog_comments.find(params[:id])
    @blog_comment.update_attributes(:is_deleted => true)
    render :update do |page|
      @blog_comments = @blog_post.blog_comments.showable.paginate :per_page=> 6,:page => params[:page]
      if @blog_comments.blank?
        show_page = params[:page].to_i > 1 ? (params[:page].to_i - 1) : 1
        @blog_comments = @blog_post.blog_comments.showable.paginate :per_page=> 6,:page => show_page
      end  
      page.replace_html 'list_comments',:partial => "blog_comments/list_blog_comments"
      page.replace_html 'flash-msg',:text=>''
      page.replace_html 'flash-msg1',:text=>"<p class='flash-msg'>#{t('blog_comments.comment_deleted')}</p>"
      page.replace_html 'leave-a-comment',:text => " #{@blog_post.blog_comments.showable.count} #{t('comments')}"
    end
  end

  def show_comments
    @blog_comments = @blog_post.blog_comments.showable.paginate :per_page=> 6,:page => params[:page]
    render :update do |page|
      @blog_comments = @blog_post.blog_comments.showable.paginate :per_page=> 6,:page => params[:page]
      page.replace_html 'list_comments',:partial => "blog_comments/list_blog_comments"
    end
  end

  private
  
  def fetch_blog_post
    @blog_post = BlogPost.find(params[:blog_post_id])
    @blog = @blog_post.blog
  end

  def restrict_fedena_admin
    if @current_user.admin?
      flash[:notice] = t('flash_admin')
      redirect_to :controller => "user",:action => "dashboard"
    end
  end
end

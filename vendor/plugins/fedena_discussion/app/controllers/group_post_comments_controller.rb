class GroupPostCommentsController < ApplicationController
  before_filter :login_required

  def create
    @group_post=GroupPost.find(params[:group_post_id])
    @group_post_comment=@group_post.group_post_comments.build(params[:group_post_comment])
    @group_post_comment.user_id=current_user.id
    if @group_post_comment.save
      @group_post_comments=@group_post.group_post_comments.all(:order=>"updated_at DESC").paginate( :page => params[:page], :per_page => 5)
      respond_to do |format|
        format.html{redirect_to group_post_path(:id=>@group_post)}
        format.js
      end
    else
      render(:update) do |page|
        page.replace_html :er, :partial => 'error_msg_display'
      end
    end
  end

  def destroy
    @group_post_comment = GroupPostComment.find(params[:id])
    @group_post=@group_post_comment.group_post
    if current_user.id==@group_post_comment.user_id or  @group_post.user_id ==current_user.id   or current_user.admin? or @current_user.privileges.map(&:name).include? "GroupCreate"
      @group_post_comment.destroy
      @group_post_comments=@group_post.group_post_comments.all(:order=>"updated_at DESC").paginate( :page => params[:page], :per_page => 5)
    else
      flash[:notice] =t('no_permission')
      redirect_to   :controller=>"group_posts", :action => "show", :group_post_id=>@group_post_comment.group_post_id
    end
    respond_to do |format|
      format.html{redirect_to group_post_path(:id=>@group_post_comment.group_post_id)}
      format.js
    end
  end

end

authorization do

  role :blog_admin do
    includes :blog_viewer
    has_permission_on [:blogs], :to => [
      :activate_deactivate
    ]
    has_permission_on [:blog_posts], :to =>[
      :activate_deactivate,
      :ban_blog
    ]
  end


  role :blog_viewer do
    has_permission_on [:blogs],:to=>
      [
      :new,
      :home,
      :create,
      :edit,
      :update,
      :blog_profile,
      :notification,
      :show_notification
    ]
    has_permission_on [:blog_posts],:to =>
      [
      :index,
      :new,
      :create,
#      :edit,
#      :update,
      :show,
      :my_blog,
      :show_all_blog_posts,
      :show_my_blog_posts,
      :publish_unpublish,
      :delete,
      :like,
      :blog_like,
      :blog_profile,
      :set_blog_comment_body,
      :employee_blog,
      :search,
      :search_user_ajax,
      :blog_directory,
      :show_blog_directory_blog_posts,
      :show_all_recent_blog_posts,
      :toggle_blog_posts
    ]
    has_permission_on [:blog_posts], :to =>
      [
      :edit,
      :update] do
      if_attribute :is_owner? => is{true}
    end
    has_permission_on [:blog_comments],:to =>
      [
      :create,
      :delete,
      :show_comments,
      :fetch_blog_posts,
      :set_blog_comment_body
    ]
  end

  role :employee do
    includes :blog_viewer
  end

  role :student do
    includes :blog_viewer
  end

  role :admin do
    includes :blog_admin
  end


end
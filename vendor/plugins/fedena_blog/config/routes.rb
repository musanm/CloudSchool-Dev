ActionController::Routing::Routes.draw do |map|
  map.resources :blogs,:except => [:show],
    :collection => {:notification => [:get,:post],
    :show_notification => [:get,:post]},
    :member => {:activate_deactivate => [:get,:post]},
    :path_names => { :new => 'home',:edit => 'settings' } do |blog|
    blog.resources :blog_posts,:collection => {
      :show_all_blog_posts => [:get,:post],
      :show_my_blog_posts => [:get,:post],
      :list_blog_directory_blog_posts => [:get,:post],
      :like => [:post],
      :set_blog_comment_body => [:post],
      :search => [:get,:post],
      :blog_directory => [:get,:post]
    },
      :member => {
      :publish_unpublish => [:post],
      :activate_deactivate => [:post],
      :delete => [:post]
    } do |blog_post|
      blog_post.resources :blog_comments
    end
  end

  map.my_blog 'blogs/myblog', :controller=>'blog_posts',:action=>'my_blog'
  map.blog_directory 'blogs/:user_id' ,:controller => "blog_posts",:action => "blog_directory"
  map.show_blog 'blogs/:user_id/:title', :controller=>'blog_posts',:action=>'show'
  
  
end
Gretel::Crumbs.layout do
  crumb :blog_posts_index do
    link I18n.t('blog_posts.blogs_text'), {:controller=>"blog_posts", :action=>"index"}
  end
  crumb :blog_posts_my_blog do
    link I18n.t('blog_posts.my_blog'), {:controller=>"blog_posts", :action=>"my_blog"}
    parent :blog_posts_index
  end
  crumb :blog_posts_new do
    link I18n.t('new_text'), {:controller=>"blogs", :action=>"new"}
    parent :blog_posts_my_blog
  end
  crumb :blog_posts_create do
    link I18n.t('new_text'), {:controller=>"blogs", :action=>"new"}
    parent :blog_posts_my_blog
  end
  crumb :blog_posts_show1 do |list|
    link list.first.title_was, {:controller=>"blog_posts", :action=>"show", :user_id => list.last, :title => list.first }
    parent :blog_posts_index
  end

  crumb :blog_posts_show do
    link I18n.t('blog_posts.deleted_user'), {:controller=>"blog_posts", :action=>"show"}
    parent :blog_posts_index
  end
  crumb :blog_posts_my_show do |list|
    link list.first.title_was, {:controller=>"blog_posts", :action=>"show", :user_id => list.last, :title => "#{list.first.title}-#{list.first.id}" }
    parent :blog_posts_my_blog
  end
  crumb :blog_posts_edit do |list|
    link I18n.t('edit_text'), {:controller=>"blog_posts", :action=>"show", :id => list.first.id }
    parent :blog_posts_my_show,list
  end
  crumb :blog_posts_update do |list|
    link I18n.t('edit_text'), {:controller=>"blog_posts", :action=>"show", :id => list.first.id }
    parent :blog_posts_my_show,list
  end
  crumb :blogs_new do
    link I18n.t('new_text'), {:controller=>"blogs", :action=>"new"}
    parent :blog_posts_index
  end
  crumb :blogs_create do
    link I18n.t('new_text'), {:controller=>"blogs", :action=>"new"}
    parent :blog_posts_index
  end
  crumb :blogs_edit do |blog|
    link "#{I18n.t('edit_text')} - #{I18n.t('blog_posts.my_blog')}", {:controller=>"blogs", :action=>"edit" ,:id => blog.id}
    parent :blog_posts_index
  end
  crumb :blogs_update do |blog|
    link "#{I18n.t('edit_text')} - #{I18n.t('blog_posts.my_blog')}", {:controller=>"blogs", :action=>"edit" ,:id => blog.id}
    parent :blog_posts_index
  end
  crumb :blogs_notification do
    link I18n.t('blog_posts.notifications'), {:controller=>"blogs", :action=>"notification"}
    parent :blog_posts_index
  end
  crumb :blog_posts_search do
    link I18n.t('blog_posts.search'), {:controller=>"blog_posts", :action=>"search"}
    parent :blog_posts_index
  end
  crumb :blog_posts_blog_directory_when_user_present do |user|
    link user.first_name, {:controller=>"blog_posts", :action=>"blog_directory", :user_id => user.id}
    parent :blog_posts_index
  end
  crumb :blog_posts_blog_directory do
    link I18n.t('blog_posts.search'), {:controller=>"blog_posts", :action=>"blog_directory"}
    parent :blog_posts_index
  end
end

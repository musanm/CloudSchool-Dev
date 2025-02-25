Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "BlogAdmin",:description => "blog_admin_privilege"
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('BlogAdmin').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('social_other_activity').id, :priority=>360 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  collaboration_category = MenuLinkCategory.find_by_name("collaboration")
  MenuLink.create(:name=>'blog_text',:target_controller=>'blog_posts',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'blog-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>collaboration_category.id) unless MenuLink.exists?(:name=>'blog_text')
end

if FedenaPlugin.plugin_installed?("fedena_data_palette")
  unless Palette.exists?(:name=>"blogs")
    p = FedenaDataPalette.create("blogs","BlogPost","fedena_blog","blog-icon") do
      user_roles [:admin,:employee,:student] do
        with do
          all(:joins=>"inner JOIN blogs on blog_posts.blog_id = blogs.id",:select=>"blog_posts.*",:conditions=>["DATE(blog_posts.created_at) = ? AND blog_posts.is_active = 1 AND blog_posts.is_published = 1 AND blog_posts.is_deleted = 0 AND blogs.is_active = 1 AND blogs.is_published = 1",:cr_date],:limit=>:lim,:offset=>:off)
        end
      end
    end

    p.save
  end
end
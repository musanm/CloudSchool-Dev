Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "Gallery",:description => 'gallery'
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('Gallery').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('social_other_activity').id, :priority=>370 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  collaboration_category = MenuLinkCategory.find_by_name("collaboration")
  MenuLink.create(:name=>'gallery',:target_controller=>'galleries',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'galleries-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>collaboration_category.id) unless MenuLink.exists?(:name=>'gallery')
end

if FedenaPlugin.plugin_installed?("fedena_data_palette")
  unless Palette.exists?(:name=>"photos_added")
    p = FedenaDataPalette.create("photos_added","GalleryPhoto","fedena_gallery","galleries-icon") do
      user_roles [:admin,:photo_admin] do
        with do
          all(:conditions=>["DATE(created_at) = ?",:cr_date],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:employee] do
        with do
          all(:conditions=>["DATE(created_at) = ? AND id IN (select gallery_photo_id from gallery_tags where member_id = ? and member_type = 'Employee')",:cr_date,later(%Q{Authorization.current_user.employee_record.id})],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:student] do
        with do
          all(:conditions=>["DATE(created_at) = ? AND id IN (select gallery_photo_id from gallery_tags where member_id = ? and member_type = 'Student')",:cr_date,later(%Q{Authorization.current_user.student_record.id})],:limit=>:lim,:offset=>:off)
        end
      end
    end

    p.save
  end
end
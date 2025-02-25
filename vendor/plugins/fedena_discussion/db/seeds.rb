Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "GroupCreate",:description => 'group_create_privilege'
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('GroupCreate').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('social_other_activity').id, :priority=>340 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  collaboration_category = MenuLinkCategory.find_by_name("collaboration")
  MenuLink.create(:name=>'discussion',:target_controller=>'groups',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'discussion-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>collaboration_category.id) unless MenuLink.exists?(:name=>'discussion')
end

if FedenaPlugin.plugin_installed?("fedena_data_palette")
  unless Palette.exists?(:name=>"discussions")
    p = FedenaDataPalette.create("discussions","GroupPost","fedena_discussion","discussion-icon") do
      user_roles [:admin,:employee,:student] do
        with do
          all(:conditions=>["DATE(created_at) = ? AND group_id IN (select group_id from group_members where user_id = ?)",:cr_date,later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
        end
      end
    end

    p.save
  end
end
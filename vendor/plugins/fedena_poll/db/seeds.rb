Privilege.reset_column_information
Privilege.find_or_create_by_name :name =>"PollControl",:description => "poll_control_privilege"
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('PollControl').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('social_other_activity').id, :priority=>350 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  collaboration_category = MenuLinkCategory.find_by_name("collaboration")
  MenuLink.create(:name=>'poll',:target_controller=>'poll_questions',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'poll-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>collaboration_category.id) unless MenuLink.exists?(:name=>'poll')
end

if FedenaPlugin.plugin_installed?("fedena_data_palette")
  unless Palette.exists?(:name=>"polls")
    p = FedenaDataPalette.create("polls","PollQuestion","fedena_poll","poll-icon") do
      user_roles [:admin,:poll_admin] do
        with do
          all(:conditions=>["DATE(created_at) = ? AND is_active = 1",:cr_date],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:employee] do
        with do
          all(:conditions=>["DATE(created_at) = ? AND is_active = 1 AND id IN (select poll_question_id from poll_members where member_id = ? and member_type = 'EmployeeDepartment')",:cr_date,later(%Q{Authorization.current_user.employee_record.employee_department_id})],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:student] do
        with do
          all(:conditions=>["DATE(created_at) = ? AND is_active = 1 AND id IN (select poll_question_id from poll_members where member_id = ? and member_type = 'Batch')",:cr_date,later(%Q{Authorization.current_user.student_record.batch_id})],:limit=>:lim,:offset=>:off)
        end
      end
    end

    p.save
  end
end

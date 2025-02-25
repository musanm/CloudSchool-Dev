
menu_link_present = MenuLink rescue false
unless menu_link_present == false
  collaboration_category = MenuLinkCategory.find_by_name("collaboration")
  MenuLink.create(:name=>'collaborate_text',:target_controller=>'online_meeting_rooms',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'collaborate-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>collaboration_category.id) unless MenuLink.exists?(:name=>'collaborate_text')
end

if FedenaPlugin.plugin_installed?("fedena_data_palette")
  unless Palette.exists?(:name=>"online_meetings")
    p = FedenaDataPalette.create("online_meetings","OnlineMeetingRoom","fedena_bigbluebutton","collaborate-icon") do
      user_roles [:admin] do
        with do
          all(:conditions=>["DATE(scheduled_on) = ? AND is_active = 1",:cr_date],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:employee,:student] do
        with do
          all(:conditions=>["DATE(scheduled_on) = ? AND is_active = 1 AND id IN (select online_meeting_room_id from online_meeting_members where member_id = ?)",:cr_date,later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
        end
      end
    end

    p.save
  end
end
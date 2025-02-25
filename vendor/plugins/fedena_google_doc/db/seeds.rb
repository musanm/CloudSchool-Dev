menu_link_present = MenuLink rescue false
unless menu_link_present == false
  collaboration_category = MenuLinkCategory.find_by_name("collaboration")

  MenuLink.create(:name=>'google_docs',:target_controller=>'google_docs',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'google-docs-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>collaboration_category.id) unless MenuLink.exists?(:name=>'google_docs')
  higher_link=MenuLink.find_by_name_and_higher_link_id('google_docs',nil)

  MenuLink.create(:name=>'view_all_docs',:target_controller=>'google_docs',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>collaboration_category.id) unless MenuLink.exists?(:name=>'view_all_docs')
  MenuLink.create(:name=>'upload_document',:target_controller=>'google_docs',:target_action=>'upload',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>collaboration_category.id) unless MenuLink.exists?(:name=>'upload_document')
end  
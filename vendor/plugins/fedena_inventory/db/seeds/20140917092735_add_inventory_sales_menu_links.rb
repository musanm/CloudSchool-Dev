cat = MenuLinkCategory.find_by_name("administration")
unless cat.nil?
  menu_link_id = MenuLink.find_by_name("inventory_text").id
  MenuLink.create(:name=>'item_category',:target_controller=>'item_categories',:target_action=>'index',:higher_link_id=>menu_link_id,:icon_class=>'',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'item_category')
  MenuLink.create(:name=>'billing',:target_controller=>'invoices',:target_action=>'index',:higher_link_id=>menu_link_id,:icon_class=>'',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>cat.id) unless MenuLink.exists?(:name=>'billing')
end



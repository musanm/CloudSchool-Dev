FinanceTransactionCategory.find_or_create_by_name(:name => 'Transport', :description => ' ', :is_income => true)
Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "TransportAdmin",:description => 'transport_admin_privilege'
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('TransportAdmin').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>130 )
end
menu_link_present = MenuLink rescue false
unless menu_link_present == false
  administration_category = MenuLinkCategory.find_by_name("administration")

  MenuLink.create(:name=>'transport_label',:target_controller=>'transport',:target_action=>'dash_board',:higher_link_id=>nil,:icon_class=>'transport-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'transport_label',:higher_link_id=>nil)

  higher_link=MenuLink.find_by_name_and_higher_link_id('transport_label',nil)

  MenuLink.create(:name=>'transport.set_routes',:target_controller=>'routes',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'transport.set_routes')
  MenuLink.create(:name=>'vehicles_text',:target_controller=>'vehicles',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'vehicles_text')
  MenuLink.create(:name=>'transport_label',:target_controller=>'transport',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'transport_label',:higher_link_id=>higher_link.id)
  MenuLink.create(:name=>'transport_fee_text',:target_controller=>'transport_fee',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'transport_fee_text')
  MenuLink.create(:name=>'report',:target_controller=>'transport',:target_action=>'vehicle_report',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'report',:higher_link_id=>higher_link.id)
end
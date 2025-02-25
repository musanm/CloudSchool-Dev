#Copyright 2010 Foradian Technologies Private Limited
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing,
#software distributed under the License is distributed on an
#"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#KIND, either express or implied.  See the License for the
#specific language governing permissions and limitations
#under the License.
Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "FormBuilder",:description=>"form_builder_privilege"
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('FormBuilder').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=> 100 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  category = MenuLinkCategory.find_by_name("collaboration")
  MenuLink.create(:name=>'form_builder_text',:target_controller=>'form_builder',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'form_builder-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=> category.id) unless MenuLink.exists?(:name=>'form_builder_text')
  MenuLink.create(:name=>'form_template_create',:target_controller=>'form_templates',:target_action=>'new',:higher_link_id=>MenuLink.find_by_name('form_builder_text').id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>category.id) unless MenuLink.exists?(:name=>'form_template_create')
  MenuLink.create(:name=>'form_templates_index',:target_controller=>'form_templates',:target_action=>'index',:higher_link_id=>MenuLink.find_by_name('form_builder_text').id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>category.id) unless MenuLink.exists?(:name=>'form_templates_index')
  MenuLink.create(:name=>'forms_manage_index',:target_controller=>'forms',:target_action=>'manage',:higher_link_id=>MenuLink.find_by_name('form_builder_text').id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>category.id) unless MenuLink.exists?(:name=>'forms_manage_index')
  MenuLink.create(:name=>'forms_index',:target_controller=>'forms',:target_action=>'index',:higher_link_id=>MenuLink.find_by_name('form_builder_text').id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>category.id) unless MenuLink.exists?(:name=>'forms_index')
  MenuLink.create(:name=>'forms_feedback_index',:target_controller=>'forms',:target_action=>'feedback_forms',:higher_link_id=>MenuLink.find_by_name('form_builder_text').id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>category.id) unless MenuLink.exists?(:name=>'forms_feedback_index')
end
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
authorization do

  role :form_builder do
		has_permission_on [:form_templates],
      :to => [:index, :preview, :new, :edit, :create, :update, :destroy, :add_field, :remove_field, :field_settings, :add_option]

		has_permission_on [:forms],
      :to => [:preview, :publish, :close, :edit, :manage, :manage_filter, :update, :destroy, :to_students, :to_employees, :update_member_list, :to_target_students, :to_target_employees, :update_target_list]

		has_permission_on [:form_submissions],
			:to => [:show, :form_submissions_csv, :analysis, :get_target_analysis, :filter, :consolidated_report]
  end
  
  role :form_basic do
    has_permission_on [:form_builder],
      :to => [:index]

    has_permission_on [:forms],
      :to => [:show, :index, :feedback_forms, :form_submit, :edit_response, :update_response, :new_form_submission]
    
    has_permission_on [:form_submissions],
			:to => [:new, :responses, :download]
  end

  role :admin do
    includes :form_builder
    includes :form_basic
  end

  role :employee do
    includes :form_basic
  end

  role :student do
    includes :form_basic
  end

  role :parent do
    includes :form_basic
  end
end
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
ActionController::Routing::Routes.draw do |map|
  map.resources :form_builder, :only => [:index]
  map.resources :form_submissions, :only => [:new,:show], :member => {
    :analysis => [:post,:get],
    :consolidated_report => [:post,:get],
    :get_target_analysis => [:post,:get],
    :filter => [:get,:post],
    :download => [:post,:get],
    :form_submissions_csv => [:post,:get],
    :responses => [:post,:get],
    :show => [:get,:post]
  }

  map.resources :form_templates, :except=> [:show],:member => {
    :preview => [:get,:post],
    :add_field => [:get],
    :add_option => [:get,:post],
    :field_settings => [:get,:post],
    :remove_field => [:get]
  }

  map.resources :forms, :only => [:index, :show, :edit, :update, :destroy], :collection => {
    :form_submit => [:get,:post],
    :feedback_forms => [:get,:post],
    :manage => [:get,:post],
    :manage_filter => [:get,:post],
    :new_form_submission => [:get,:post],
    :to_employees => [:get,:post],
    :to_students => [:get,:post],
    :to_target_employees => [:get,:post],
    :to_target_students => [:get,:post],
    :update_member_list => [:get,:post],
    :update_target_list => [:get,:post]
  }, :member => {
    :close => [:post],
    :preview => [:get,:post],
    :edit_response => [:get,:post],
    :publish => [:get,:post],
    :update_response => [:get,:post]
  }
end
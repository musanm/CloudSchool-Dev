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
require 'translator'
require 'dispatcher'
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")
require File.join(File.dirname(__FILE__), "lib", "fedena_form_builder")
require File.join(File.dirname(__FILE__), "lib/fedena_form_builder", "form_builder_user")
require File.join(File.dirname(__FILE__), "lib", "field_config")
FedenaPlugin.register = {
  :name=>"fedena_form_builder",
  :description=>"Fedena Form Builder Module",
  :auth_file=>"config/form_builder_auth.rb",
  :icon_class_link=>{:plugin_name=>"fedena_form_builder",:stylesheet_path=>"form_builder/form_builder_icon.css"},  
  :multischool_models=>%w{ Form FormField FormSubmission FormTemplate FormFileAttachment FormFieldOption},
  :multischool_classes=>%w{DelayedFormReminderJob}
}
if RAILS_ENV == 'development'
  ActiveSupport::Dependencies.load_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end

FedenaFormBuilder.attach_overrides

autoload :Searchkick, 'searchkick'

ActiveRecord::Base.send(:extend, Searchkick::Model) if FedenaSetting.elasticsearch_enabled?

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end
field_settings = YAML::load(File.open("#{File.dirname(__FILE__)}/config/fields.yml"))

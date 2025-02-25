require 'translator'
require 'dispatcher'
require File.join(File.dirname(__FILE__), "lib", "fedena_moodle")


FedenaPlugin.register = {
  :name=>"fedena_moodle",
  :description=>"Fedena Moodle Module",
  :auth_file=>"config/moodle_auth.rb",
  :multischool_classes=>%w{MoodleJob}
}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

FedenaMoodle.attach_overrides

if RAILS_ENV == 'development'
  ActiveSupport::Dependencies.load_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end


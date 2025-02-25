require 'translator'
require 'dispatcher'

require File.join(File.dirname(__FILE__), "lib", "fedena_mobile")

FedenaPlugin.register = {
  :name=>"fedena_mobile",
  :description=>"Fedena Mobile",
  :auth_file=>"config/mobile_auth.rb"
}

FedenaMobile.attach_overrides

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end
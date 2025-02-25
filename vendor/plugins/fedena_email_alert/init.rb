require 'translator'
require 'dispatcher'
require 'fedena'
require File.join(File.dirname(__FILE__), "lib", "fedena_email_alert")
require File.join(File.dirname(__FILE__), "lib", 'email_alert','alert_data')
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

FedenaPlugin.register = {
  :name=>"fedena_email_alert",
  :description=>"Fedena Email Alert",
  :auth_file=>"config/email_alert_auth.rb",
  :more_menu=>{:title=>"email_send",:controller=>"email_alerts",:action=>"index",:target_id=>"more-parent"},
  :multischool_models=>%w{EmailAlert EmailSubscription},
  :multischool_classes=>%w{FedenaEmailAlertEmailMaker}

}

FedenaEmailAlert.attach_overrides

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

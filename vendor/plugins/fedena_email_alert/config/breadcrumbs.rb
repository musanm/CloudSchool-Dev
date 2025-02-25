Gretel::Crumbs.layout do
  crumb :email_alerts_index do
    link I18n.t('email_send'), {:controller=>"email_alerts", :action=>"index"}
  end
  crumb :email_alerts_student do
    link I18n.t('send_email_to_students'), {:controller=>"email_alerts", :action=>"show", :recipient => "employee"}
    parent :email_alerts_index
  end
  crumb :email_alerts_employee do
    link I18n.t('send_email_to_employees'), {:controller=>"email_alerts", :action=>"show",:recipient => "employee"}
    parent :email_alerts_index
  end
  crumb :email_alerts_guardians do
    link I18n.t('send_email_to_guardians'), {:controller=>"email_alerts", :action=>"show", :recipient => "employee"}
    parent :email_alerts_index
  end
  crumb :email_alerts_email_alert_settings do
    link I18n.t('email_alert_settings_privilege'), {:controller=>"email_alerts", :action=>"email_alert_settings"}
    parent :email_alerts_index
  end
  crumb :email_alerts_email_unsubscription_list do
    link I18n.t('unsubscription_list'), {:controller=>"email_alerts", :action=>"email_unsubscription_list"}
    parent :email_alerts_index
  end
end

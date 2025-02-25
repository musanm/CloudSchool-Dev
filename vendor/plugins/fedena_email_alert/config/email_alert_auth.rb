authorization do
  
  role :send_email  do
    has_permission_on [:email_alerts],
      :to => [
      :index,
      :create,
      :show_students_list,
      :update_recipient_list,
      :show]
  end
  role :email_alert_settings  do
    has_permission_on [:email_alerts],
      :to => [
      :index,
      :email_alert_settings,
      :email_unsubscription_list
      ]
  end
  role :admin  do
    includes :email_alert_settings
    includes :send_email
  end

end

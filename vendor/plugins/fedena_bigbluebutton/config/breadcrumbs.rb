Gretel::Crumbs.layout do
  crumb :online_meeting_rooms_index do
    link I18n.t('online_meeting_rooms.online_meetings'), {:controller=>"online_meeting_rooms", :action=>"index"}
  end
  crumb :online_meeting_rooms_new do
    link I18n.t('online_meeting_rooms.create_meeting'), {:controller=>"online_meeting_rooms", :action=>"new"}
    parent :online_meeting_rooms_index
  end
  crumb :online_meeting_rooms_create do
    link I18n.t('new_text'), {:controller=>"online_meeting_rooms", :action=>"new"}
    parent :online_meeting_rooms_index
  end
  crumb :online_meeting_rooms_show do |room|
    link room.name_was, {:controller=>"online_meeting_rooms", :action=>"show", :id => room.id }
    parent :online_meeting_rooms_index
  end
  crumb :online_meeting_rooms_edit do |room|
    link I18n.t('edit_text'), {:controller=>"online_meeting_rooms", :action=>"edit", :id => room.id }
    parent :online_meeting_rooms_show, room
  end
  crumb :online_meeting_rooms_update do |room|
    link I18n.t('edit_text'), {:controller=>"online_meeting_rooms", :action=>"edit", :id => room.id }
    parent :online_meeting_rooms_show, room
  end
  crumb :online_meeting_servers_index do
    link I18n.t('online_meeting_rooms.servers'), {:controller=>"online_meeting_servers", :action=>"index"}
    parent :online_meeting_rooms_index
  end
  crumb :online_meeting_servers_new do
    link I18n.t('online_meeting_servers.new_server'), {:controller=>"online_meeting_servers", :action=>"new"}
    parent :online_meeting_servers_index
  end
  crumb :online_meeting_servers_create do
    link I18n.t('online_meeting_servers.new_server'), {:controller=>"online_meeting_servers", :action=>"new"}
    parent :online_meeting_servers_index
  end
  crumb :online_meeting_servers_show do |server|
    link server.name_was, {:controller=>"online_meeting_servers", :action=>"show", :id =>server.id}
    parent :online_meeting_servers_index
  end
  crumb :online_meeting_servers_edit do |server|
    link I18n.t('edit_text'), {:controller=>"online_meeting_servers", :action=>"edit", :id =>server.id}
    parent :online_meeting_servers_show, server
  end
  crumb :online_meeting_servers_update do |server|
    link I18n.t('edit_text'), {:controller=>"online_meeting_servers", :action=>"edit", :id =>server.id}
    parent :online_meeting_servers_show, server
  end
end

class MultiSchoolGroup < SchoolGroup
  has_many :school_group_users, :foreign_key=>:school_group_id, :dependent=>:destroy
  has_many :multi_school_admins, :through => :school_group_users
  accepts_nested_attributes_for :school_group_users
  accepts_nested_attributes_for :multi_school_admins

  after_create :create_default_domain
  before_destroy :delete_schools_and_settings

  attr_accessor :job_mode
  
  def create_default_domain
    self.school_domains.create(:domain=>"group#{self.id}.#{MultiSchool.default_domain}") if (ActsAsSaas rescue false)
  end

  def after_initialize
    if parent_group && !parent_group.whitelabel_enabled?
      self.whitelabel_enabled = false
    end
    unless parent_group
      write_attribute(:license_count,MultiSchool.multischool_settings["max_school_count"])
      write_attribute(:whitelabel_enabled,MultiSchool.multischool_settings["organization_details"]["whitelabel"])
      write_attribute(:school_stats_enabled,MultiSchool.multischool_settings["organization_details"]["school_stats"])
    end unless (ActsAsSaas rescue false)
  end

  def delete_schools_and_settings
    unless self.schools.empty?
      client_group = self.parent_group
      self.schools.each do|school|
        MultiSchool.current_school = school
        school.update_attributes(:creator_id=>nil,:school_group_id=>client_group.id)
        school.soft_delete
      end
    end
    self.multi_school_admins.each do|admin|
      admin.destroy
    end
  end

  def effective_sms_settings
    if inherit_sms_settings?
      parent_group.effective_sms_settings
    else
      (sms_credential && (sms_credential.settings.is_a? Hash))?  sms_credential.settings : nil
    end
  end

  def effective_smtp_settings
    if inherit_smtp_settings?
      parent_group.effective_smtp_settings
    else
      (smtp_setting && (smtp_setting.settings.is_a? Hash))? smtp_setting.settings_to_sym : nil
    end
  end  

  def load_local_settings(school)
    if self.parent_group
      client_settings = self.parent_group.local_setting
      unless client_settings.nil?
        MultiSchool.current_school = school
        Configuration.find_or_create_by_config_key("Locale").update_attributes(:config_value=>client_settings.settings["select"]["language"])
        Configuration.find_or_create_by_config_key("DefaultCountry").update_attributes(:config_value=>client_settings.settings["select"]["country"])
        Configuration.find_or_create_by_config_key("TimeZone").update_attributes(:config_value=>client_settings.settings["select"]["time_zone"])
        Configuration.find_or_create_by_config_key("Color").update_attributes(:config_value=>client_settings.settings["drop_down"]["theme"]) if client_settings.settings["drop_down"].present? and client_settings.settings["drop_down"]["theme"].present?
        Configuration.find_or_create_by_config_key("Font").update_attributes(:config_value=>client_settings.settings["drop_down"]["font"]) if client_settings.settings["drop_down"].present? and client_settings.settings["drop_down"]["font"].present?
        admin_user = User.first( :conditions=>{:admin=>true})
        admin_user.update_attributes(:email=>client_settings.settings["text"]["admin_email"]) if admin_user
        admin_user.employee_record.update_attribute(:email,admin_user.email) if admin_user and admin_user.employee_record
      end
    end
  end

  def perform
    case job_mode
    when "modify_gateways"
      self.modify_child_gateways
    else
      self.modify_child_plugins
    end

    def modify_child_plugins
      own_plugins = self.available_plugin.plugins
      schools = self.schools.active
      schools.each do|school|
        if school.available_plugin
          school_plugins = school.available_plugin.plugins
          allowed_plugins = own_plugins & school_plugins
          school.available_plugin.update_attributes(:plugins=>allowed_plugins)
        end
      end
    end

    def modify_child_gateways
      own_gateways = self.gateway_assignees.collect(&:custom_gateway_id)
      schools = self.schools
      schools.each do|school|
        school_gateways = school.gateway_assignees.all(:conditions=>{:is_owner=>false}).collect(&:custom_gateway_id)
        disallowed_gateways = school_gateways - own_gateways
        unless disallowed_gateways.empty?
          GatewayAssignee.destroy_all(:conditions=>{:custom_gateway_id=>disallowed_gateways,:assignee_id=>school.id,:assignee_type=>"School"})
        end
      end
    end
  end

end

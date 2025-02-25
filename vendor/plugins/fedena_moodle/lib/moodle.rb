module Moodle
  def self.included(base)
    base.alias_method_chain :validate,:moodle_validate
  end

  def validate_with_moodle_validate
    moodle_url = ActiveRecord::Base.connection.tables.include?("configurations") ? ActiveRecord::Base::Configuration.get_config_value("MoodleUrl") : []
    if moodle_url.present? and FedenaPlugin.can_access_plugin?("fedena_moodle") and self.email.blank?
      errors.add('email','cant be blank')
    end
    validate_without_moodle_validate
  end
end
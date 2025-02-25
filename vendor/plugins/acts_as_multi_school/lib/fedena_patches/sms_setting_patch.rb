module FedenaPatches
  module SmsSettingPatch
    def self.included(base)
      base.instance_eval do
        def get_sms_config
          school = MultiSchool.current_school
          return (school ? school.effective_sms_settings : nil)
        end
      end
    end
  end
end
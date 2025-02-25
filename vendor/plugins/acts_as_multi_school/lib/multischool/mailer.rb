module MultiSchool
  module Mailer
    def self.included(base)
      base.class_eval do
        def prepare_settings
          @current_school = MultiSchool.current_school ? MultiSchool.current_school : \
            ((MultiSchool.current_school_group.try(:type) == "MultiSchoolGroup") ? MultiSchool.current_school_group : nil)
          self.class.smtp_settings = SMTP_SETTINGS
          if @current_school
            self.class.delivery_method = :smtp
            self.class.smtp_settings = @current_school.effective_smtp_settings
          end
          @from_address = self.class.smtp_settings[:from_address] if self.class.smtp_settings
        end


        def create_with_school!(method_name, *parameters)
          prepare_settings
          create_without_school!(method_name, *parameters)
          if @current_school.nil? || FedenaSetting.smtp_settings == self.class.smtp_settings
            @from = "'Fedena' <noreply@fedena.com>"
            @headers['return-path'] = 'noreply@fedena.com'
          end
          unless @from_address.blank?
            @from = @from_address
            @headers['return-path'] = @from_address
          end
          @mail = create_mail
        end

        alias_method_chain :create!, :school
        
      end
    end
  end
end

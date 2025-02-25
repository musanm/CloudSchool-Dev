require 'email_alert/fedena_email_alert_msg_parse'
module FedenaEmailAlert
  module EmailAlertOnUpdate

    def self.included(base)
      base.send :before_update,:email_send_on_updation
      base.send :after_update,:email_send_on_updation_verify
      base.send :attr_accessor,:email_alerts_to_send
    end

    include FedenaEmailAlertMsgParse

    def email_send_on_updation
      self.email_alerts_to_send ||= []
      selected_data=FedenaEmailAlert.alert_bodies.find_all_by_model(self.class.name.underscore.to_sym).find{|m| (m.fields.nil? or instance_eval(&m.fields)=="mail_value" or instance_eval(&m.fields)) and changes.keys.include? m.modifications  and EmailAlert.active.collect(&:model_name).include?(m.name.to_s)} and FedenaPlugin.can_access_plugin?("fedena_email_alert")
      if selected_data.present?
        selected_data.mail_to.each do |send_to|
          if EmailAlert.find_by_model_name(selected_data.name.to_s).mail_to.include?(send_to.recipient)
            instance_eval(&send_to.to).uniq.select{|s| s.first.present?}.each do |recp|
              instance_eval(&send_to.stud_name).nil?? a={:recipient_name=>recp.last}:a={:recipient_name=>recp.last,:student_name=>instance_eval(&send_to.stud_name)[recp.first]}
              message_variables= msg_parse(send_to.message)
              message="#{t("#{send_to.recipient.to_s}_#{selected_data.name.to_s}",message_variables.merge!(a))}"
              subject_variables=msg_parse(send_to.subject)
              subject="#{t("#{send_to.recipient.to_s}_subject_#{selected_data.name.to_s}",subject_variables.merge!(a))}"
              sender=""
              footer="#{t("footer",{:school_name=>Configuration.get_config_value('InstitutionName'),:school_details=>msg_parse(send_to.footer).values.first})}"
              email_alerts_to_send.push FedenaEmailAlertEmailMaker.new(sender,subject,message,recp.first,Fedena.hostname,footer,Fedena.rtl,subject_variables)
            end
          end
        end

      end
    end

    def email_send_on_updation_verify
      
      email_alerts_to_send.each do |arr|
        Delayed::Job.enqueue(arr)
      end
      self.email_alerts_to_send = []

    end

  end
end
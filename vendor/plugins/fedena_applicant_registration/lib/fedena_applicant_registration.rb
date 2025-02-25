require 'dispatcher'
require "list"
  
module FedenaApplicantRegistration
  def self.attach_overrides
    ActiveRecord::Base.instance_eval { include ActiveRecord::Acts::List }
    Dispatcher.to_prepare :fedena_applicant_registration do
      ::Course.instance_eval { has_one :registration_course }
      ::Student.instance_eval {
        has_many :student_addl_attachments
        accepts_nested_attributes_for :student_addl_attachments, :allow_destroy => true
      }
      FinanceController.send(:include,FedenaApplicantRegistration::ApplicantRegistrationIncomeDetails)
    end
  end

  def self.csv_export_list
    return ["applicant_registration","search_by_registration"]
  end

  def self.csv_export_data(report_type,params)
    case report_type
    when "applicant_registration"
      data = Applicant.applicant_registration_data(params)
    when "search_by_registration"
      data = Applicant.search_by_registration_data(params)
    end
  end
  
  module ApplicantRegistrationIncomeDetails
    def self.included(base)
      base.alias_method_chain :income_details,:applicant_registration
    end

    def income_details_with_applicant_registration
      if date_format_check
        if FedenaPlugin.can_access_plugin?("fedena_applicant_registration")
          if date_format_check
            if params[:id].present?
              @income_category = FinanceTransactionCategory.find(params[:id])
            else
              @income_category = FinanceTransactionCategory.find_by_name('Applicant Registration')
            end
            @incomes = @income_category.finance_transactions.find(:all, :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'"])
          end
        else
          income_details_without_applicant_registration
        end

      end
    end
  end
end
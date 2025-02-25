# FedenaMoodle
require 'net/http'
require 'dispatcher'

module FedenaMoodle
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_moodle do
      ::Student.instance_eval { include StudentExtension }
      ::Employee.instance_eval { include EmployeeExtension }
      ::User.instance_eval { include UserExtension }
      ::Student.instance_eval { include ::Moodle }
      ::Employee.instance_eval { include ::Moodle }
    end
  end
    
  def self.general_settings_form
    "configuration/moodle"
  end

  def self.moodle_url
    if FedenaPlugin.can_access_plugin?("fedena_moodle")
      Configuration.find_by_config_key("MoodleUrl")
    end
  end

  def self.moodle_link
    if FedenaMoodle.moodle_url.present?
      Configuration.find_by_config_key("MoodleUrl").config_value
    end
  end
  

  class Moodle

    attr_accessor :action,:user_id,:old_username
    attr_accessor :password
    def initialize(action,record_id,old_username="",record_type="student")
      if FedenaMoodle.moodle_link.present?
        @action = action
        if record_type == "student"
          @record =  Student.find_by_id(record_id) unless record_id.blank?
        elsif record_type == "employee"
          @record =  Employee.find_by_id(record_id) unless record_id.blank?
        end
        @old_username = old_username
        @record_type = record_type
      else
        return false
      end
    end

    def load_moodle_url
      moodle_url = FedenaMoodle.moodle_link
      moodle_fedena_url = ""
      unless moodle_url.blank?
        if moodle_url[moodle_url.length-1,1].to_s != "/"
          moodle_url = moodle_url + '/'
        end
        moodle_fedena_url = moodle_url + 'fedena.php'
      end
      moodle_fedena_url
    end

    def send_to_moodle
      unless Rails.env == "test"
        moodle_fedena_url = load_moodle_url
        unless moodle_fedena_url.blank?
          user = Hash.new
          user['username']= (@record_type=="employee") ? @record.employee_number.to_s : @record.admission_no.to_s
          user['firstname']=@record.first_name
          user['lastname']=@record.last_name
          user['email']=@record.email
          user['city'] = (@record_type=="employee") ? @record.home_city : @record.city
          if @record_type=="employee"
            user['country'] = @record.home_country.name unless @record.home_country.nil?
          else
            user['country'] = @record.country.name
          end
          user['idnumber'] = (@record_type=="employee") ? @record.employee_number.to_s : @record.admission_no.to_s
          user['phone1'] = (@record_type=="employee") ? @record.home_phone : @record.phone1
          user['phone2'] = (@record_type=="employee") ? @record.mobile_phone : @record.phone2
          if @record_type=="employee"
            address = @record.home_address_line1.to_s + ", " + @record.home_address_line2.to_s
          else
            address = @record.address_line1.to_s + ", " + @record.address_line2.to_s
          end
          user['address'] = address[0..69]
          if @action.to_s=="CreateAccount"
            user['password'] = (@record_type=="employee") ? "#{@record.employee_number.to_s}123" : "#{@record.admission_no.to_s}123"
          end
          user['oldusername']= @old_username unless @old_username.blank?
          if moodle_fedena_url.present?
            request = "#{moodle_fedena_url}?action=#{@action}&#{user.to_param}"
            send_data(request)
          end
        end
      end
    end

    def change_moodle_account_password
      unless Rails.env == "test"
        moodle_fedena_url = load_moodle_url
        user = Hash.new
        user['username']= @old_username
        user['password'] = self.password
        if moodle_fedena_url.present?
          request = "#{moodle_fedena_url}?action=#{@action}&#{user.to_param}"
          send_data(request)
        end
      end
    end


    def send_data(request)
      response = Net::HTTP.get_response(URI.parse(URI.encode(request)))
      response.body
    end
  end




  module StudentExtension
    def self.included(base)
      base.instance_eval do
        after_create :create_user_account_and_moodle_account
        after_update :update_moodle_account
      end
    end
  
    def create_user_account_and_moodle_account
      if FedenaMoodle.moodle_link.present?
        Delayed::Job.enqueue(MoodleJob.new(
            :action => 'CreateAccount',
            :id => self.id
          ))
      end
    end

    def update_moodle_account
      if self.changed.include?('admission_no')
        admission_no = self.admission_no_was.to_s
      else
        admission_no = self.admission_no.to_s
      end
      if FedenaMoodle.moodle_link.present?
        Delayed::Job.enqueue(MoodleJob.new(
            :action => 'UpdateAccount',
            :id => self.id,
            :username => admission_no
          ))
      end
    end
  
    def check_for_email
      if FedenaMoodle.moodle_url.present?
        if self.email.blank?
          errors.add(:email, "#{t('cant_be_blank')}.")
          return false
        end
      end
      true
    end
  end

  module EmployeeExtension
    def self.included(base)
      base.instance_eval do
        belongs_to  :home_country, :class_name => 'Country'
        after_create :create_user_account_and_moodle_account
        after_update :update_moodle_account
      end
    end

    def create_user_account_and_moodle_account
      if FedenaMoodle.moodle_link.present?
        Delayed::Job.enqueue(MoodleJob.new(
            :action => 'CreateAccount',
            :id => self.id,
            :usertype => 'employee'
          ))
      end
    end
    def update_moodle_account
      if self.changed.include?('employee_number')
        employee_number = self.employee_number_was.to_s
      else
        employee_number = self.employee_number.to_s
      end
      if FedenaMoodle.moodle_link.present?
        Delayed::Job.enqueue(MoodleJob.new(
            :action => 'UpdateAccount',
            :id => self.id,
            :username => employee_number,
            :usertype => 'employee'
          ))
      end
    end
  
    def check_for_email
      if Configuration.get_config_value("MoodleUrl").present? and FedenaPlugin.can_access_plugin?("fedena_moodle")
        if self.email.blank?
          errors.add(:email, "#{t('cant_be_blank')}.")
          return false
        end
      end
      true
    end
  end

  module UserExtension
    def self.included(base)
      base.instance_eval do
        after_update :password_update
      end
    end
    
    def password_update
      unless self.password.blank?
        usertype = (self.student?) ? "student" : "employee"
        if FedenaMoodle.moodle_link.present?
          Delayed::Job.enqueue(MoodleJob.new(
              :action => 'UpdateAccountPassword',
              :username => self.username,
              :password => self.password,
              :usertype => usertype
            ))
        end
      end
    end
  end
end

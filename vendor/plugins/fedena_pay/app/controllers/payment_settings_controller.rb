class PaymentSettingsController < ApplicationController
  require 'will_paginate/array'
  before_filter :login_required, :except=>[:initialize_payment]
  filter_access_to [:index,:transactions,:settings,:show_gateway_fields,:show_transaction_details,:return_to_fedena_pages]

  def index
    
  end

  def transactions
    start_date = params[:start_date]
    start_date ||= Date.today
    end_date = params[:end_date]
    end_date ||= Date.today
    
    @online_payments = Payment.all.select{|p| p.created_at.to_date >= start_date.to_date and p.created_at.to_date <= end_date.to_date}.paginate(:page => params[:page],:per_page => 30)

    respond_to do |format|
      format.html #transctions.html.erb
    end
  end
  
  def settings
    @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
    @gateways = CustomGateway.available_gateways
    #    if @active_gateway == "Webpay" && Country.find(Configuration.find_by_config_key('DefaultCountry').config_value).name != "Nigeria"
    #      @active_gateway = "Paypal"
    #      config = PaymentConfiguration.find_by_config_key('fedena_gateway')
    #      config.update_attributes(:config_value => "")
    #    end
    #    if @active_gateway == "Paypal"
    #      @gateway_fields = FedenaPay::PAYPAL_CONFIG_KEYS
    #    elsif @active_gateway == "Authorize.net"
    #      @gateway_fields = FedenaPay::AUTHORIZENET_CONFIG_KEYS
    #    elsif @active_gateway == "Webpay"
    #      @gateway_fields = FedenaPay::WEBPAY_CONFIG_KEYS
    #    else
    #      @gateway_fields = []
    #    end
    @enabled_fees = PaymentConfiguration.find_by_config_key("enabled_fees").try(:config_value)  
    @enabled_fees ||= Array.new

    if request.post?
      payment_settings = params[:payment_settings]
      payment_settings.each_pair do |key,value|
        configuration = PaymentConfiguration.find_or_initialize_by_config_key(key)
        if configuration.update_attributes(:config_value => value)
          flash[:notice] = "Payment setting has been saved successfully."
        else
          flash[:notice] = "#{configuration.errors.full_messages.join("\n")}"
        end
      end
      unless payment_settings.keys.include? "enabled_fees"
        configuration = PaymentConfiguration.find_or_initialize_by_config_key("enabled_fees")
        configuration.update_attributes(:config_value => Array.new)
      end
      redirect_to settings_online_payments_path
    end
  end

  def show_gateway_fields
    unless params[:gateway] == "custom"
      @active_gateway = params[:gateway]
      if @active_gateway == "Paypal"
        @gateway_fields = FedenaPay::PAYPAL_CONFIG_KEYS
      elsif @active_gateway == "Authorize.net"
        @gateway_fields = FedenaPay::AUTHORIZENET_CONFIG_KEYS
      elsif @active_gateway == "Webpay"
        @gateway_fields = FedenaPay::WEBPAY_CONFIG_KEYS
      end
    else
      @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
      @gateways = CustomGateway.available_gateways
    end
    render :update do |page|
      if @gateway_fields.present?
        page.replace_html 'gateway_fields',:partial => "gateway_fields"
      else
        if @gateways.present?
          page.replace_html 'gateway_fields',:partial => "custom_gateways"
        else
          page.replace_html 'gateway_fields',:text => ""
        end
      end
    end
  end

  def initialize_payment
    active_gateway = PaymentConfiguration.config_value("fedena_gateway")
    @custom_gateway = CustomGateway.find(active_gateway.to_i)
    @payment_params = params[:online_payment]
    render :layout => false
  end

  def show_transaction_details
    @payment = Payment.find(params[:id])
    @gateway_response = @payment.gateway_response
    respond_to do |format|
      format.html { }
      format.js { render :action => 'show_transaction_details' }
    end
  end

  def return_to_fedena_pages
    @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
    if @active_gateway == "Paypal"
      return_url = OnlinePayment.return_url + {:tx => "#{params[:tx]}",:st => "#{params[:st]}",:amt => "#{params[:amt]}"}.to_param
    else
      return_url = URI.parse(OnlinePayment.return_url)
    end
    redirect_to return_url
    OnlinePayment.return_url = nil
  end

end

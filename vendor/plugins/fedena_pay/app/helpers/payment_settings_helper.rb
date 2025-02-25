module PaymentSettingsHelper
  def config_value(key)
    PaymentConfiguration.find_by_config_key(key).try(:config_value)
  end

  def paypal_pay_button(certificate,merchant_id,currency_code,item_name,amount,return_url,paid_fees = Array.new,button_style = String.new)
    @certificate = certificate
    @merchant_id = merchant_id
    @currency_code = currency_code
    @item_name = item_name
    @amount = amount
    @return_url = return_url
    @paid_fees = paid_fees
    @button_style = button_style

    render :partial => "gateway_payments/paypal/paypal_form"
  end

  def authorize_net_pay_button(merchant_id,certificate,amount,item_name,return_url,paid_fees = Array.new,button_style = String.new)
    @merchant_id = merchant_id
    @certificate = certificate
    @amount = amount
    @item_name = item_name
    @return_url = return_url
    @button_style = button_style
    @paid_fees = paid_fees
    @sim_transaction = AuthorizeNet::SIM::Transaction.new(@merchant_id,@certificate, @amount,{:hosted_payment_form => true})
    @sim_transaction.instance_variable_set("@custom_fields",{:x_description => @item_name})
    @sim_transaction.set_hosted_payment_receipt(AuthorizeNet::SIM::HostedReceiptPage.new(:link_method => AuthorizeNet::SIM::HostedReceiptPage::LinkMethod::GET, :link_text => "Back to #{current_school_name}", :link_url => URI.parse(@return_url)))

    render :partial => "gateway_payments/authorize_net/authorize_net_form"
  end

  def custom_gateway_pay_button(active_gateway,amount,item_name,redirect_url,paid_fees = Array.new,button_style = String.new)
    @active_gateway = active_gateway
    @custom_gateway = CustomGateway.find(@active_gateway)
    gateway_params = @custom_gateway.gateway_parameters
    @paid_fees = paid_fees
    @button_style = button_style
    @variable_params = Hash.new
    @variable_params[gateway_params[:variable_fields][:amount].to_sym] = amount if gateway_params[:variable_fields][:amount].present?
    @variable_params[gateway_params[:variable_fields][:redirect_url].to_sym] = redirect_url if gateway_params[:variable_fields][:redirect_url].present?
    @variable_params[gateway_params[:variable_fields][:item_name].to_sym] = item_name if gateway_params[:variable_fields][:item_name].present?
    @variable_params[gateway_params[:variable_fields][:firstname].to_sym] = @current_user.first_name if gateway_params[:variable_fields][:firstname].present?
    @variable_params[gateway_params[:variable_fields][:lastname].to_sym] = @current_user.last_name if gateway_params[:variable_fields][:lastname].present?
    @variable_params[gateway_params[:variable_fields][:email].to_sym] = @current_user.email if gateway_params[:variable_fields][:email].present?
    @variable_params[gateway_params[:variable_fields][:phone].to_sym] = @current_user.student_record.phone2 if (gateway_params[:variable_fields][:phone].present? and @current_user.student?)
    @variable_params[gateway_params[:variable_fields][:phone].to_sym] = @current_user.parent_record.phone2 if (gateway_params[:variable_fields][:phone].present? and @current_user.parent?)

  
    render :partial => "gateway_payments/custom/custom_gateway_form"
  end

  def webpay_pay_button(txn_ref,pdt_id,item_id,amount,return_url,merchant_id,paid_fees = Array.new,button_style = String.new)
    @product_id = pdt_id.strip
    @pay_item_id = item_id.strip
    @currency = '566'
    @site_redirect_url = return_url
    @txn_ref = txn_ref
    @original_amount = amount
    @amount =   "#{(('%.02f' % amount).to_f * 100).to_i}"
    @mac_key = merchant_id.strip
    @hash = sha_hash(string_for_hash_param(@txn_ref,@product_id,@pay_item_id,@amount,@site_redirect_url,@mac_key))
    @button_style = button_style
    @paid_fees = paid_fees
    render :partial => "gateway_payments/webpay/webpay_form"
  end

  def string_for_hash_param(txn_ref,product_id,pay_item_id,amount,site_redirect_url,mac_key)
    txn_ref.to_s + product_id.to_s + pay_item_id.to_s + amount.to_s + site_redirect_url.to_s + mac_key.to_s
  end

  def sha_hash(message)
    Digest::SHA512.hexdigest(message)
  end

  def get_payment_url
    payment_urls = Hash.new
    if File.exists?("#{Rails.root}/vendor/plugins/fedena_pay/config/online_payment_url.yml")
      payment_urls = YAML.load_file(File.join(Rails.root,"vendor/plugins/fedena_pay/config/","online_payment_url.yml"))
    end
    active_gateway = PaymentConfiguration.config_value("fedena_gateway")
    if active_gateway == "Paypal"
      payment_url = payment_urls["paypal_url"]
      payment_url ||= "https://www.sandbox.paypal.com/cgi-bin/webscr"
    elsif active_gateway == "Authorize.net"
      payment_url = eval(payment_urls["authorize_net_url"].to_s)
      payment_url ||= eval("AuthorizeNet::SIM::Transaction::Gateway::TEST")
    elsif active_gateway == "Webpay"
      payment_url = payment_urls["webpay_url"]
      payment_url ||= 'https://stageserv.interswitchng.com/test_paydirect/pay'
    end
    payment_url
  end

  def transaction_details(transaction_ref,amount)
    "Please verify details \nTransaction Reference No : #{transaction_ref}\n Amount : #{amount}\n\n Click OK to continue?"
  end
end

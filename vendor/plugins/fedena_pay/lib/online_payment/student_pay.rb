module OnlinePayment
  class << self; attr_accessor_with_default :return_url,String.new; end
  module StudentPay
    def self.included(base)
      base.alias_method_chain :fee_details,:gateway
    end

    def fee_details_with_gateway
      if FedenaPlugin.can_access_plugin?("fedena_pay")
        if (PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.config_value("enabled_fees").include? "Student Fee")
          @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
          #          if @active_gateway == "Paypal"
          #            @merchant_id = PaymentConfiguration.config_value("paypal_id")
          #            @merchant_id ||= String.new
          #            @currency_code = PaymentConfiguration.config_value("currency_code")
          #            @currency_code ||= String.new
          #            @certificate = PaymentConfiguration.config_value("paypal_certificate")
          #            @certificate ||= String.new
          #          elsif @active_gateway == "Authorize.net"
          #            @merchant_id = PaymentConfiguration.config_value("authorize_net_merchant_id")
          #            @merchant_id ||= String.new
          #            @certificate = PaymentConfiguration.config_value("authorize_net_transaction_password")
          #            @certificate ||= String.new
          #          elsif @active_gateway == "Webpay"
          #            @merchant_id = PaymentConfiguration.config_value("webpay_merchant_id")
          #            @merchant_id ||= String.new
          #            @product_id = PaymentConfiguration.config_value("webpay_product_id")
          #            @product_id ||= String.new
          #            @item_id = PaymentConfiguration.config_value("webpay_item_id")
          #            @item_id ||= String.new
          if @active_gateway.nil?


            fee_details_without_gateway and return
          else
            @custom_gateway = CustomGateway.find(@active_gateway)
#            unless @custom_gateway.nil?
#              @custom_gateway.gateway_parameters[:config_fields].each_pair do|k,v|
#                instance_variable_set("@"+k,v)
#              end
#            else
#              fee_details_without_gateway and return
#            end
          end
          hostname = "#{request.protocol}#{request.host_with_port}"
          current_school_name = Configuration.find_by_config_key('InstitutionName').try(:config_value)
          @date  = FinanceFeeCollection.find(params[:id2])
          @financefee = @student.finance_fee_by_date @date
          @fee_collection = FinanceFeeCollection.find(params[:id2])
          @due_date = @fee_collection.due_date
          @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted IS NOT NULL"])
          @fee_particulars = @date.finance_fee_particulars.all(:conditions => "batch_id=#{@financefee.batch_id}").select { |par| (par.receiver.present?) and (par.receiver==@student or par.receiver==@financefee.student_category or par.receiver==@financefee.batch) }
          @categorized_particulars=@fee_particulars.group_by(&:receiver_type)
          @discounts=@date.fee_discounts.all(:conditions => "batch_id=#{@financefee.batch_id}").select { |par| (par.receiver.present?) and ((par.receiver==@financefee.student or par.receiver==@financefee.student_category or par.receiver==@financefee.batch) and (par.master_receiver_type!='FinanceFeeParticular' or (par.master_receiver_type=='FinanceFeeParticular' and (par.master_receiver.receiver.present? and @fee_particulars.collect(&:id).include? par.master_receiver_id) and  (par.master_receiver.receiver==@financefee.student or par.master_receiver.receiver==@financefee.student_category or par.master_receiver.receiver==@financefee.batch)))) }
          @categorized_discounts=@discounts.group_by(&:master_receiver_type)
          @total_discount = 0
          @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
          @total_discount =@discounts.map { |d| d.master_receiver_type=='FinanceFeeParticular' ? (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) : @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100) }.sum.to_f unless @discounts.nil?
          total_fees = @financefee.balance.to_f+params[:special_fine].to_f
          unless params[:fine].nil?
            total_fees += params[:fine].to_f
          end
          bal=(@total_payable-@total_discount).to_f
          days=(Date.today-@date.due_date.to_date).to_i
          auto_fine=@date.fine
          @fine_amount = 0
          if days > 0 and auto_fine
            @fine_rule=auto_fine.fine_rules.find(:last,:conditions=>["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],:order=>'fine_days ASC')
            @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
          end
          @amount = total_fees + @fine_amount
          @paid_fees = @financefee.finance_transactions
          OnlinePayment.return_url = "http://#{request.host_with_port}/student/fee_details/#{params[:id]}/#{params[:id2]}?create_transaction=1" unless OnlinePayment.return_url.nil?
          total_fees = 0
          total_fees = @fee_collection.student_fee_balance(@student)+params[:special_fine].to_f
          #          if @active_gateway == "Authorize.net"
          #            @sim_transaction = AuthorizeNet::SIM::Transaction.new(@merchant_id,@certificate, total_fees,{:hosted_payment_form => true,:x_description => "Fee-#{@student.admission_no}-#{@fee_collection.name}"})
          #            @sim_transaction.instance_variable_set("@custom_fields",{:x_description => "Fee (#{@student.full_name}-#{@student.admission_no}-#{@fee_collection.name})"})
          #            @sim_transaction.set_hosted_payment_receipt(AuthorizeNet::SIM::HostedReceiptPage.new(:link_method => AuthorizeNet::SIM::HostedReceiptPage::LinkMethod::GET, :link_text => "Back to #{current_school_name}", :link_url => URI.parse("http://#{request.host_with_port}/student/fee_details/#{params[:id]}/#{params[:id2]}?create_transaction=1&only_path=false")))
          #          end
          if params[:create_transaction].present?
            gateway_response = Hash.new
            #            if @active_gateway == "Paypal"
            #              gateway_response = {
            #                :amount => params[:amt],
            #                :status => params[:st],
            #                :transaction_id => params[:tx]
            #              }
            #            elsif @active_gateway == "Authorize.net"
            #              gateway_response = {
            #                :x_response_code => params[:x_response_code],
            #                :x_response_reason_code => params[:x_response_reason_code],
            #                :x_response_reason_text => params[:x_response_reason_text],
            #                :x_avs_code => params[:x_avs_code],
            #                :x_auth_code => params[:x_auth_code],
            #                :x_trans_id => params[:x_trans_id],
            #                :x_method => params[:x_method],
            #                :x_card_type => params[:x_card_type],
            #                :x_account_number => params[:x_account_number],
            #                :x_first_name => params[:x_first_name],
            #                :x_last_name => params[:x_last_name],
            #                :x_company => params[:x_company],
            #                :x_address => params[:x_address],
            #                :x_city => params[:x_city],
            #                :x_state => params[:x_state],
            #                :x_zip => params[:x_zip],
            #                :x_country => params[:x_country],
            #                :x_phone => params[:x_phone],
            #                :x_fax => params[:x_fax],
            #                :x_invoice_num => params[:x_invoice_num],
            #                :x_description => params[:x_description],
            #                :x_type => params[:x_type],
            #                :x_cust_id => params[:x_cust_id],
            #                :x_ship_to_first_name => params[:x_ship_to_first_name],
            #                :x_ship_to_last_name => params[:x_ship_to_last_name],
            #                :x_ship_to_company => params[:x_ship_to_company],
            #                :x_ship_to_address => params[:x_ship_to_address],
            #                :x_ship_to_city => params[:x_ship_to_city],
            #                :x_ship_to_zip => params[:x_ship_to_zip],
            #                :x_ship_to_country => params[:x_ship_to_country],
            #                :x_amount => params[:x_amount],
            #                :x_tax => params[:x_tax],
            #                :x_duty => params[:x_duty],
            #                :x_freight => params[:x_freight],
            #                :x_tax_exempt => params[:x_tax_exempt],
            #                :x_po_num => params[:x_po_num],
            #                :x_cvv2_resp_code => params[:x_cvv2_resp_code],
            #                :x_MD5_hash => params[:x_MD5_hash],
            #                :x_cavv_response => params[:x_cavv_response],
            #                :x_method_available => params[:x_method_available],
            #              }
            #            elsif @active_gateway == "Webpay"
            #              if File.exists?("#{Rails.root}/vendor/plugins/fedena_pay/config/online_payment_url.yml")
            #                response_urls = YAML.load_file(File.join(Rails.root,"vendor/plugins/fedena_pay/config/","online_payment_url.yml"))
            #              end
            #              txnref = params[:txnref] || params[:txnRef] || ""
            #              response_url = response_urls.nil? ? nil : (response_urls["webpay_response_url"].to_s)
            #              response_url ||= "https://stageserv.interswitchng.com/test_paydirect/api/v1/gettransaction.json"
            #              response_url += "?productid=#{@product_id.strip}"
            #              response_url += "&transactionreference=#{txnref}"
            #              response_url += "&amount=#{(('%.02f' % @amount).to_f * 100).to_i}"
            #              uri = URI.parse(response_url)
            #              http = Net::HTTP.new(uri.host, uri.port)
            #              http.use_ssl = true
            #              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            #
            #              request = Net::HTTP::Get.new(uri.request_uri, {'Hash' => Digest::SHA512.hexdigest(@product_id.strip + txnref.to_s  + @merchant_id.strip)})
            #              response = http.request(request)
            #              response_str = JSON.parse response.body
            #              gateway_response = {
            #                :split_accounts => response_str["SplitAccounts"],
            #                :merchant_reference => response_str["MerchantReference"],
            #                :response_code => response_str["ResponseCode"],
            #                :lead_bank_name => response_str["LeadBankName"],
            #                :lead_bank_cbn_code => response_str["LeadBankCbnCode"],
            #                :amount => response_str["Amount"].to_f/ 100,
            #                :card_number => response_str["CardNumber"],
            #                :response_description => response_str["ResponseDescription"],
            #                :transaction_date => response_str["TransactionDate"],
            #                :retrieval_reference_number => response_str["RetrievalReferenceNumber"],
            #                :payment_reference => response_str["PaymentReference"]
            #              }
            if @custom_gateway.present?
              @custom_gateway.gateway_parameters[:response_parameters].each_pair do|k,v|
                unless k.to_s == "success_code"
                  gateway_response[k.to_sym] = params[v.to_sym]
                end
              end
            end
            @gateway_status = false
            #            if @active_gateway == "Paypal"
            #              @gateway_status = true if params[:st] == "Completed"
            #            elsif @active_gateway == "Authorize.net"
            #              @gateway_status = true if gateway_response[:x_response_reason_code] == "1"
            #            elsif @active_gateway == "Webpay"
            #              @gateway_status = true if gateway_response[:response_code] == "00"
            if @custom_gateway.present?
              success_code = @custom_gateway.gateway_parameters[:response_parameters][:success_code]
              @gateway_status = true if gateway_response[:transaction_status] == success_code
            end

            payment = Payment.new(:payee => @student,:payment => @financefee,:gateway_response => gateway_response,:status => @gateway_status, :amount => gateway_response[:amount].to_f, :gateway => @active_gateway)
            payment.fee_collection = @fee_collection
            if payment.save
              trans_id=@financefee.finance_transactions.collect(&:finance_transaction_id).join(",")
              trans_id = 0 if trans_id == ""
              unless @financefee.is_paid?
                amount_from_gateway = 0
                #                if @active_gateway == "Paypal"
                #                  amount_from_gateway = params[:amt]
                #                elsif @active_gateway == "Authorize.net"
                #                  amount_from_gateway = params[:x_amount]
                #                elsif @active_gateway == "Webpay"
                #                  amount_from_gateway = gateway_response[:amount]
                if @custom_gateway.present?
                  amount_from_gateway = gateway_response[:amount]
                end
                unless amount_from_gateway.to_f <= 0.0
                  unless amount_from_gateway.to_f > (FinanceTransaction.total(trans_id,@amount) +@fine_amount).to_f
                    if @gateway_status == true
                      transaction = FinanceTransaction.new
                      transaction.title = "#{t('receipt_no')}. F#{@financefee.id}"
                      transaction.category = FinanceTransactionCategory.find_by_name("Fee")
                      transaction.payee = @student
                      transaction.finance = @financefee
                      #transaction.amount = @financefee.balance.to_f + @fine.to_f + @fine_amount.to_f #amount_from_gateway.to_f
                      transaction.amount = amount_from_gateway.to_f
                      transaction.fine_included = (@fine.to_f + @fine_amount.to_f).zero? ? false : true
                      transaction.fine_amount = @fine.to_f + @fine_amount.to_f
                      transaction.transaction_date = Date.today
                      transaction.payment_mode = "Online Payment"
                      transaction.save
                      payment.update_attributes(:finance_transaction_id => transaction.id)
                      unless @financefee.transaction_id.nil?
                        tid = @financefee.transaction_id.to_s + ",#{transaction.id}"
                      else
                        tid=transaction.id
                      end
                      is_paid = (sprintf("%0.2f",total_fees.to_f+@fine.to_f + @fine_amount.to_f).to_f == amount_from_gateway.to_f) ? true : false
                      @financefee.update_attributes(:transaction_id=>tid, :is_paid=>is_paid)

                      @paid_fees = FinanceTransaction.find(:all,:conditions=>"FIND_IN_SET(id,\"#{tid}\")")


                      status = Payment.payment_status_mapping[:success]
                      payment.update_attributes(:status_description => status)
                      #                      online_transaction_id = payment.gateway_response[:transaction_id]
                      #                      online_transaction_id ||= payment.gateway_response[:x_trans_id]
                      #                      online_transaction_id ||= payment.gateway_response[:payment_reference]
                      online_transaction_id = payment.gateway_response[:transaction_reference]
                      flash[:notice] = "#{t('payment_success')} <br>  #{t('payment_reference')} : #{online_transaction_id}"
                    else
                      status = Payment.payment_status_mapping[:failed]
                      payment.update_attributes(:status_description => status)
                      flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{payment.gateway_response[:reason_code] || 'N/A'} <br> #{t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
                    end
                  else
                    flash[:notice] = "#{t('flash19')}"
                  end
                else
                  status = Payment.payment_status_mapping[:failed]
                  payment.update_attributes(:status_description => status)
                  flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{payment.gateway_response[:reason_code] || 'N/A'} <br> #{t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
                end
              end
              if current_user.parent?
                user = current_user
              else
                user = @student.user
              end
              if @student.is_email_enabled && user.email.present? && @gateway_status
                begin
                  Delayed::Job.enqueue(PaymentMail.new(payment.fee_collection.name,user.email,user.full_name,@custom_gateway.name,payment.amount,online_transaction_id,payment.gateway_response,user.school_details,hostname))
                rescue Exception => e
                  puts "Error------#{e.message}------#{e.backtrace.inspect}"
                  return
                end
              end
            else
              flash[:notice] = "#{t('flash_payed')}"
            end

            redirect_to :controller => 'student', :action => 'fee_details', :id => params[:id], :id2 => params[:id2]
          else
            @fine_amount=0 if (@student.finance_fee_by_date @date).is_paid
            render 'gateway_payments/paypal/fee_details'
          end
          #render 'student/fee_details'
        else
          fee_details_without_gateway
        end
      else
        fee_details_without_gateway
      end
    end
  end

  #URI.parse("http://192.168.1.30:3000/student/fee_details/#{params[:id]}/#{params[:id2]}?create_transaction=1")
  module StudentPayReceipt

    def self.included(base)
      base.alias_method_chain :student_fee_receipt_pdf,:gateway
    end

    def student_fee_receipt_pdf_with_gateway
      if FedenaPlugin.can_access_plugin?("fedena_pay")
        @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
        if @active_gateway.nil?
          student_fee_receipt_pdf_without_gateway and return
        end
        if (PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.config_value("enabled_fees").include? "Student Fee")
          @date = @fee_collection = FinanceFeeCollection.find(params[:id2])
          @student = Student.find(params[:id])
          @financefee = @student.finance_fee_by_date @date
          @due_date = @fee_collection.due_date

          @paid_fees = @financefee.finance_transactions
          @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,:conditions => ["is_deleted = false"])
          @currency_type = currency

          @fee_particulars = @date.finance_fee_particulars.all(:conditions => "batch_id=#{@financefee.batch_id}").select { |par| (par.receiver.present?) and (par.receiver==@student or par.receiver==@financefee.student_category or par.receiver==@financefee.batch) }
          @categorized_particulars=@fee_particulars.group_by(&:receiver_type)
          @discounts=@date.fee_discounts.all(:conditions => "batch_id=#{@financefee.batch_id}").select { |par| (par.receiver.present?) and ((par.receiver==@financefee.student or par.receiver==@financefee.student_category or par.receiver==@financefee.batch) and (par.master_receiver_type!='FinanceFeeParticular' or (par.master_receiver_type=='FinanceFeeParticular' and (par.master_receiver.receiver.present? and @fee_particulars.collect(&:id).include? par.master_receiver_id) and (par.master_receiver.receiver==@financefee.student or par.master_receiver.receiver==@financefee.student_category or par.master_receiver.receiver==@financefee.batch)))) }
          @categorized_discounts=@discounts.group_by(&:master_receiver_type)
          @total_discount = 0
          @total_payable=@fee_particulars.map { |s| s.amount }.sum.to_f
          @total_discount =@discounts.map { |d| d.master_receiver_type=='FinanceFeeParticular' ? (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) : @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100) }.sum.to_f unless @discounts.nil?
          bal=(@total_payable-@total_discount).to_f
          days=(Date.today-@date.due_date.to_date).to_i
          auto_fine=@date.fine
          if days > 0 and auto_fine
            @fine_rule=auto_fine.fine_rules.find(:last,:conditions=>["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],:order=>'fine_days ASC')
            @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
          end
          @fine_amount=0 if @financefee.is_paid
          respond_to do |format|
            format.pdf do
              render :pdf => "student_fee_receipt",
                :template => 'gateway_payments/paypal/student_fee_receipt_pdf'
            end
          end
        else
          student_fee_receipt_pdf_without_gateway
        end
      else
        student_fee_receipt_pdf_without_gateway
      end
    end
  end

  class PaymentMail < Struct.new(:fee_name,:email, :payee, :active_gateway, :amount, :txn_ref, :gateway_response,:school_details,:hostname)
    def perform
      EmailNotifier.deliver_send_transaction_details(fee_name ,email,payee, active_gateway, amount, txn_ref, gateway_response, school_details, hostname)
    end
  end
end

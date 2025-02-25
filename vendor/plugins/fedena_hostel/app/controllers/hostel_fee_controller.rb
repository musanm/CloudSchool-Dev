class HostelFeeController < ApplicationController
  require 'authorize_net'
  helper :authorize_net
  before_filter :login_required
  before_filter :set_precision
  filter_access_to :all
  protect_from_forgery :except => [:student_profile_fee_details]

  def hostel_fee_collection_new
    @hostel_fee_collection = HostelFeeCollection.new
    @batches = Batch.active.reject { |b| !b.room_allocations_present }
  end

  def send_reminder(hostel_fee_collection, recipients)
    subject = "#{t('fees_submission_date')}"
    body = "<p><b>#{t('fee_submission_date_for')} <i>"+ "#{hostel_fee_collection.name}" +"</i> #{t('has_been_published')} </b><br /><br/>
                                #{t('start_date')} : "+hostel_fee_collection.start_date.to_s+" <br />"+
      " #{t('end_date')} : "+hostel_fee_collection.end_date.to_s+" <br /> "+
      " #{t('due_date')} : "+hostel_fee_collection.due_date.to_s+" <br /><br /><br /> "+
      "#{t('regards')}, <br/>" + current_user.full_name.capitalize

    Delayed::Job.enqueue(DelayedReminderJob.new(:sender_id => current_user.id,
        :recipient_ids => recipients,
        :subject => subject,
        :body => body))
  end

  def hostel_fee_collection_create
    @hostel_fee_collection = HostelFeeCollection.new
    @batches = Batch.active.reject { |b| !b.room_allocations_present }
    if request.post?
      unless params[:hostel_fee_collection].nil?
        @batch = params[:hostel_fee_collection][:batch_id]
        @params = params[:hostel_fee_collection]
        @params.delete("batch_id")
        @hostel_fee_collection = HostelFeeCollection.new(@params)
        unless @hostel_fee_collection.valid?
          @error = true
        end
        saved = 0
        allocation = RoomAllocation.find(:all, :conditions => ["is_vacated is false"])
        unless @batch.nil?
          @event=Event.find_by_title('Hostel Fee', :conditions => ["description=?", "'Fee name: #{params[:hostel_fee_collection][:name]}' and start_date='#{params[:hostel_fee_collection][:due_date]}' and end_date='#{params[:hostel_fee_collection][:due_date]}'"])
          @batch.each do |b|
            @params["batch_id"] = b
            @hostel_fee_collection = HostelFeeCollection.new(@params)
            if @hostel_fee_collection.save
              @event= Event.create(:title => "#{t('hostel_fee_text')}", :description => "#{t('fee_name')}: #{params[:hostel_fee_collection][:name]}", :start_date => params[:hostel_fee_collection][:due_date], :end_date => params[:hostel_fee_collection][:due_date], :is_due => true, :origin => @hostel_fee_collection)
              @batch_event = BatchEvent.create(:event_id => @event.id, :batch_id => b)
              recipients = []

              allocation.each do |a|
                unless a.student.nil?
                  if a.student.batch_id == b.to_i
                    @hostel_fee = HostelFee.new()
                    @hostel_fee.student_id = a.student_id
                    @hostel_fee.hostel_fee_collection_id = @hostel_fee_collection.id
                    @hostel_fee.rent = a.room_detail.rent
                    @hostel_fee.save
                    recipients << a.student.user_id
                  end
                end
              end
              saved += 1

              send_reminder(@hostel_fee_collection, recipients)
            else
              @error = true
            end
          end
        else
          @error = true
          @hostel_fee_collection.errors.add_to_base("#{t('no_batch_selected')}")
        end
      end
      if @error.nil?
        if saved == @batch.size
          flash[:notice]="#{t('collection_date_has_been_created')}"
          redirect_to :action => 'hostel_fee_collection_view'
        else
          render :action => 'hostel_fee_collection_new'
        end
      else
        render :action => 'hostel_fee_collection_new'
      end
    else
      redirect_to :action => 'hostel_fee_collection_new'
    end
  end

  def hostel_fee_collection_view
    @batches = Batch.active.all(:include => :course)
  end

  def batchwise_collection_dates
    unless params[:batch_id]==""
      @hostel_fee_collection = HostelFeeCollection.find(:all, :select => 'distinct hostel_fee_collections.*', :joins => {:hostel_fees => :student}, :conditions => "students.batch_id = #{params[:batch_id]} and hostel_fee_collections.is_deleted = false and hostel_fees.is_active=true", :include => {:batch => :course})
      render(:update) do |page|
        page.replace_html 'flash', :text => ""
        page.replace_html "fee-collection-edit", :partial => "fee_collection_edit"
      end
    else
      render(:update) do |page|
        page.replace_html 'flash', :text => ""
        page.replace_html "fee-collection-edit", :text => ""
      end
    end
  end

  def hostel_fee_pay
    @batches=Batch.active.all(:include => :course)
    @hostel_fee_collection = []
  end

  def hostel_fee_collection_edit
    @batch_id=params[:batch_id]
    @hostel_fee_collection = HostelFeeCollection.find params[:id]
  end

  def update_hostel_fee_collection_date
    hostel_fee_collection = HostelFeeCollection.find params[:id]
    render :update do |page|
      if params[:hostel_fee_collection][:due_date].to_date >= params[:hostel_fee_collection][:end_date].to_date
        if hostel_fee_collection.update_attributes(params[:hostel_fee_collection])
          hostel_fee_collection.event.update_attributes(:start_date => hostel_fee_collection.due_date.to_datetime, :end_date => hostel_fee_collection.due_date.to_datetime)
          page.replace_html 'form-errors', :text => ''
          page << "Modalbox.hide();"
          page.replace_html 'flash', :text => "<p class='flash-msg'>#{t('hostel_fee.hostel_flash12')} </p>"
          @hostel_fee_collection = HostelFeeCollection.find(:all, :select => 'distinct hostel_fee_collections.*', :joins => {:hostel_fees => :student}, :conditions => "students.batch_id = #{params[:batch_id]} and hostel_fee_collections.is_deleted = false and hostel_fees.is_active=true", :include => {:batch => :course})
          page.replace_html 'fee-collection-edit', :partial => 'fee_collection_edit', :object => @hostel_fee_collection
        else
          page.replace_html 'flash', :text => ""
          page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => hostel_fee_collection
          page.visual_effect(:highlight, 'form-errors')
        end
      else
        page.replace_html 'form-errors', :text => "<div id='error-box'><ul><li>#{t('hostel_fee.hostel_flash13')}</li></ul></div>"
        flash[:notice]=""
      end
    end
  end

  def update_fee_collection_dates
    # @hostel_fee_collection = HostelFeeCollection.find_all_by_batch_id(params[:batch_id],:conditions=>{:is_deleted => false})
    @hostel_fee_collection=HostelFeeCollection.find(:all, :select => "distinct hostel_fee_collections.*", :joins => [:hostel_fees => :student], :conditions => "students.batch_id='#{params[:batch_id]}' and hostel_fees.is_active=1 and hostel_fee_collections.is_deleted=false")
    render :update do |page|
      page.replace_html "hostel_fee_collection_dates", :partial => 'hostel_fee_collection_dates'
    end
  end

  def hostel_fee_collection_details
    flash[:notice]=nil
    flash[:warn_notice]=nil
    @target_action='hostel_fee_collection_details'
    @fine = params[:fees][:fine] if params[:fees].present?
    @date=HostelFeeCollection.find(params[:date])
    @batch=Batch.find(params[:batch_id])
    @students=Student.find(:all,:joins=>:hostel_fees, :conditions => "hostel_fees.hostel_fee_collection_id='#{@date.id}' and hostel_fees.is_active=1 and students.batch_id='#{@batch.id}'",:order=>"id ASC")
    if params[:student].present?
      @student=Student.find(params[:student])
    else
      @student=@students.first
    end
    @prev_student=@students.select{|student| student.id<@student.id}.last||@students.last
    @next_student=@students.select{|student| student.id>@student.id}.first||@students.first
    @transaction = HostelFee.find_by_student_id_and_hostel_fee_collection_id(@student.id, @date.id)
    @finance_transaction = @transaction.finance_transaction
    render :update do |page|
      page.replace_html "fees_detail", :partial => 'fees_submission_form'
    end
  end

#  def hostel_fee_submission_student
#    @student = params[:id]
#    @transaction = HostelFee.find_by_student_id_and_hostel_fee_collection_id(params[:id], params[:date])
#    @finance_transaction = @transaction.finance_transaction
#    render :update do |page|
#      page.replace_html "hostel_fee_collection_details", :partial => "fees_submission_form"
#    end
#  end
#
#  def update_student_fine_ajax
#    flash[:notice]=nil
#    flash[:warn_notice]=nil
#    @fine = (params[:fine][:fee])
#    @student = params[:fine][:_id]
#    @transaction = HostelFee.find_by_student_id_and_hostel_fee_collection_id(params[:fine][:_id], params[:fine][:hostel_fee_collection])
#    @finance_transaction = @transaction.finance_transaction
#    render :update do |page|
#      page.replace_html "hostel_fee_collection_details", :partial => 'fees_submission_form'
#    end
#  end
#
#  def pay_fees
#    @pay = HostelFee.find params[:id]
#    category_id = FinanceTransactionCategory.find_by_name("Hostel").id
#    transaction = FinanceTransaction.new
#    transaction.title = @pay.hostel_fee_collection.name
#    transaction.category_id = category_id
#    transaction.finance = @pay
#    transaction.amount = @pay.rent
#    transaction.transaction_date = Date.today
#    transaction.payee = @pay.student
#    if transaction.save
#      @pay.update_attribute(:finance_transaction_id, transaction.id)
#    end
#    @hostel_fee = HostelFee.find_all_by_hostel_fee_collection_id(@pay.hostel_fee_collection_id)
#    @hostel_fee.reject! { |x| x.student.nil? }
#    render :update do |page|
#      page.replace_html "hostel_fee_collection_details", :partial => 'hostel_fee_collection_details'
#    end
#  end

  def hostel_fee_defaulters
    @batches=Batch.all(:joins=>{:students=>{:hostel_fees=>:hostel_fee_collection}},:conditions =>["batches.is_deleted=? and batches.is_active=? and hostel_fee_collections.is_deleted=? and hostel_fee_collections.due_date < ? and hostel_fees.rent > ? and hostel_fees.finance_transaction_id IS NULL",false,true,false,Date.today,0.0],:group=>"batches.id")
    @hostel_fee_collection = []
  end

  def update_fee_collection_defaulters_dates
    @hostel_fee_collection=HostelFeeCollection.all(:conditions=>["batches.id=? and hostel_fee_collections.is_deleted=? and hostel_fees.finance_transaction_id IS NULL and hostel_fee_collections.due_date < ? and hostel_fees.rent > ?",params[:batch_id],false,Date.today,0.0],:group =>"hostel_fee_collections.id",:joins=>"INNER JOIN hostel_fees on hostel_fees.hostel_fee_collection_id=hostel_fee_collections.id and hostel_fees.is_active=1 INNER JOIN students on hostel_fees.student_id=students.id INNER JOIN batches on students.batch_id=batches.id")
    render :update do |page|
      page.replace_html "hostel_fee_collection_dates", :partial => 'hostel_fee_collection_defaulters_dates'
    end
  end

  def hostel_fee_collection_defaulters_details
    @target_action='hostel_fee_collection_defaulters_details'
    @fine = params[:fees][:fine] if params[:fees].present?
    @date=HostelFeeCollection.find(params[:date])
    @batch=Batch.find(params[:batch_id])
    @students=Student.find(:all,:joins=>:hostel_fees, :conditions => "hostel_fees.finance_transaction_id is null and hostel_fees.hostel_fee_collection_id='#{@date.id}' and hostel_fees.is_active=1 and students.batch_id='#{@batch.id}'",:order=>"id ASC")
    if params[:student].present?
      @student=Student.find(params[:student])
    else
      @student=@students.first
    end
    @prev_student=@students.select{|student| student.id<@student.id}.last||@students.last
    @next_student=@students.select{|student| student.id>@student.id}.first||@students.first
    @transaction = HostelFee.find_by_student_id_and_hostel_fee_collection_id(@student.id, @date.id)
    @finance_transaction = @transaction.finance_transaction
    flash[:notice]=nil
    render :update do |page|
      page.replace_html "fees_detail", :partial => 'fees_submission_form'
    end
  end

  def pay_defaulters_fees
    category_id = FinanceTransactionCategory.find_by_name("Hostel").id
    @pay = HostelFee.find params[:id]
    transaction = FinanceTransaction.new
    transaction.title = @pay.hostel_fee_collection.name
    transaction.category_id = category_id
    transaction.finance = @pay
    transaction.amount = @pay.rent
    transaction.payee = @pay.student
    transaction.transaction_date = Date.today.to_date

#    if transaction.save
#      @pay.update_attribute(:finance_transaction_id, transaction.id)
#    end
    @hostel_fee = HostelFee.find_all_by_hostel_fee_collection_id(@pay.hostel_fee_collection_id, :conditions => ["finance_transaction_id is null"])
    @hostel_fee.reject! { |x| x.student.nil? }
    render :update do |page|
      page.replace_html "hostel_fee_collection_details", :partial => 'hostel_fee_collection_defaulters_details'
      page.replace_html "pay_msg", :text => "<p class='flash-msg'> #{t('fees_paid')} </p>"
    end
  end

  def search_ajax
    #if params[:query].length >= 3
    #@usnconfig = Configuration.find_by_config_key('EnableUsn')

    #    if @usnconfig.config_value == '1'
    #      @students = Student.usn_no_or_first_name_or_middle_name_or_last_name_or_admission_no_begins_with params[:query].split unless params[:query].empty?
    #      @students.reject! {|s| RoomAllocation.find_all_by_student_id(s.id, :conditions=>["is_vacated is false"]).empty?}
    #    else
    ###########
    #     if params[:query].length > 0
    #      @students = Student.first_name_or_middle_name_or_last_name_or_admission_no_begins_with params[:query].split unless params[:query].empty?
    #      @students.reject! {|s| RoomAllocation.find_all_by_student_id(s.id, :conditions=>["is_vacated is false"]).empty?}
    ##    end
    #    render :partial => "search_ajax"
    #    end
    ############
    if params[:query].length>= 3
      @students = Student.find(:all,
        :conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                            OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) and is_vacated is false",
          "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%",
          "#{params[:query]}", "#{params[:query]}"], :joins => [:room_allocations],
        :order => "batch_id asc,first_name asc", :include => [:batch => :course]).uniq unless params[:query] == ''
    else
      @students = Student.find(:all,
        :conditions => ["first_name = ? OR middle_name = ? OR last_name = ?
                            OR admission_no = ? OR (concat(first_name, \" \", last_name) = ? ) and is_vacated is false",
          "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%",
          "#{params[:query]}", "#{params[:query]}"], :joins => [:room_allocations],
        :order => "batch_id asc,first_name asc", :include => [:batch => :course]).uniq unless params[:query] == ''
    end
    render :partial => "search_ajax"
  end

  def student_hostel_fee
    @student = Student.find_by_id(params[:id])
    @dates = HostelFeeCollection.find(:all, :joins => 'INNER JOIN hostel_fees ON hostel_fee_collections.id = hostel_fees.hostel_fee_collection_id', :conditions => "hostel_fees.student_id = #{@student.id} and hostel_fee_collections.is_deleted = 0 and hostel_fees.is_active=1")
  end

  def fees_submission_student
    flash[:notice]=nil
    flash[:warn_notice]=nil
    @fine=params[:fees][:fine] if params[:fees].present?
    @student = Student.find(params[:student])
    @date=HostelFeeCollection.find(params[:date])
    @transaction = HostelFee.find_by_student_id_and_hostel_fee_collection_id(@student.id, @date.id)
    @finance_transaction = @transaction.finance_transaction
    render :update do |page|
      page.replace_html "hostel_fee_collection_details", :partial => "fees_details"
    end
  end

  def select_payment_mode
    if  params[:payment_mode]=="#{t('others')}"
      render :update do |page|
        page.replace_html "payment_mode", :partial => "select_payment_mode"
      end
    else
      render :update do |page|
        page.replace_html "payment_mode", :text => ""
      end
    end
  end

  def hostel_fee_collection_pay
    @transaction = HostelFee.find(params[:fees][:hostel_fee_id])
    @date=@transaction.hostel_fee_collection
    @student = Student.find(params[:student])
    @batch=@student.batch
    @students=Student.find(:all,:joins=>:hostel_fees, :conditions => "hostel_fees.hostel_fee_collection_id='#{@transaction.hostel_fee_collection_id}' and hostel_fees.is_active=1 and students.batch_id='#{@student.batch_id}'")
    @prev_student=@students.select{|student| student.id<@student.id}.last||@students.last
    @next_student=@students.select{|student| student.id>@student.id}.first||@students.first
    unless params[:fees][:payment_mode].blank?
      transaction = FinanceTransaction.new
      transaction.title = @transaction.hostel_fee_collection.name
      transaction.category_id = FinanceTransactionCategory.find_by_name('Hostel').id
      transaction.finance = @transaction
      transaction.amount = @transaction.rent
      transaction.amount += params[:fees][:fine].to_f unless params[:fees][:fine].blank?
      transaction.fine_amount = params[:fees][:fine].to_f unless params[:fees][:fine].blank?
      transaction.fine_included = true unless params[:fees][:fine].blank?
      transaction.transaction_date = Date.today
      transaction.payment_mode = params[:fees][:payment_mode]
      transaction.payment_note = params[:fees][:payment_note]
      transaction.payee = @transaction.student
      if transaction.save
#        @transaction.update_attributes(:finance_transaction_id => transaction.id)
        flash[:notice]="#{t('fee_paid')}"
        flash[:warn_notice]=nil
      end
      @finance_transaction = @transaction.finance_transaction     
      @fine = params[:fees][:fine] if params[:fees].present?
    else
      flash[:notice]=nil
      flash[:warn_notice]="#{t('select_one_payment_mode')}"
    end
    render :update do |page|
      page.replace_html 'fees_details', :partial => 'fees_details'
    end
  end

  def student_fee_receipt_pdf
    @transaction = HostelFee.find params[:id]
    @finance_transaction = @transaction.finance_transaction
    @fine = @finance_transaction.fine_amount if @finance_transaction.fine_included
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      response = @finance_transaction.try(:payment).try(:gateway_response)
      @online_transaction_id = response.nil? ? nil : response[:transaction_id]
      @online_transaction_id ||= response.nil? ? nil : response[:x_trans_id]
      @online_transaction_id ||= response.nil? ? nil : response[:transaction_reference]
    end
    render :pdf => 'hostel_fee_receipt'
  end

  def delete_fee_collection_date
    transaction = HostelFee.find_by_hostel_fee_collection_id(params[:id])
    hostel_fee_collection=HostelFeeCollection.find params[:id]
    unless transaction.nil?
      if hostel_fee_collection.update_attributes(:is_deleted => true)
        event=hostel_fee_collection.event
        event.destroy
        render :update do |page|
          page.replace_html 'flash', :text => "<p class='flash-msg'>#{t('hostel_fee.deleted_successfully')} </p>"
          @hostel_fee_collection = HostelFeeCollection.find(:all, :select => 'distinct hostel_fee_collections.*', :joins => {:hostel_fees => :student}, :conditions => "students.batch_id = #{params[:batch_id]} and hostel_fee_collections.is_deleted = false and hostel_fees.is_active=true", :include => {:batch => :course})
          page.replace_html 'fee-collection-edit', :partial => 'fee_collection_edit', :object => @hostel_fee_collection
        end
      end
    else
      render :update do |page|
        page.replace_html 'flash', :text => "<div id='errorExplanation' class='errorExplanation'><ul><li>#{t('cant_delete_collection_date_with_transactions')}</li></ul></div>"
        @hostel_fee_collection = HostelFeeCollection.find(:all, :select => 'distinct hostel_fee_collections.*', :joins => {:hostel_fees => :student}, :conditions => "students.batch_id = #{params[:batch_id]} and hostel_fee_collections.is_deleted = false and hostel_fees.is_active=true", :include => {:batch => :course})
        page.replace_html 'fee-collection-edit', :partial => 'fee_collection_edit', :object => @hostel_fee_collection
      end

    end
  end

  def hostel_fees_report
    if date_format_check

      @start_date = params[:start_date]
      @end_date = params[:end_date]
      hostel_id = FinanceTransactionCategory.find_by_name('Hostel').id
      @collection = HostelFeeCollection.find(:all, :joins => "INNER JOIN hostel_fees ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id INNER JOIN finance_transactions ON finance_transactions.finance_id = hostel_fees.id and finance_transactions.finance_type = 'HostelFee' and finance_transactions.transaction_date >= '#{@start_date}' AND finance_transactions.transaction_date <= '#{@end_date}'and finance_transactions.category_id ='#{hostel_id}'", :group => "hostel_fee_collections.id")
    end
  end

  def batch_hostel_fees_report
    if date_format_check

      @start_date = params[:start_date]
      @end_date = params[:end_date]
      @fee_collection = HostelFeeCollection.find(params[:id])
      @batch = @fee_collection.batch
      hostel_id = FinanceTransactionCategory.find_by_name('Hostel').id

      @transaction =[]
      @fee_collection.finance_transaction.each { |f| @transaction<<f if (f.transaction_date.to_s >= @start_date and f.transaction_date.to_s <= @end_date) }
    end
  end

  def student_profile_fee_details
    @student=Student.find(params[:id])
    @fee= HostelFee.find_by_hostel_fee_collection_id_and_student_id(params[:id2], params[:id])
    @amount = @fee.rent
    @paid_fees=@fee.finance_transaction unless @fee.finance_transaction_id.blank?
    @fee_collection = HostelFeeCollection.find(params[:id2])
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      if ((PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.config_value("enabled_fees").include? "Hostel Fee"))
        @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
        #        if @active_gateway == "Paypal"
        #          @merchant_id = PaymentConfiguration.config_value("paypal_id")
        #          @merchant ||= String.new
        #          @certificate = PaymentConfiguration.config_value("paypal_certificate")
        #          @certificate ||= String.new
        #        elsif @active_gateway == "Authorize.net"
        #          @merchant_id = PaymentConfiguration.config_value("authorize_net_merchant_id")
        #          @merchant_id ||= String.new
        #          @certificate = PaymentConfiguration.config_value("authorize_net_transaction_password")
        #          @certificate ||= String.new
        #        elsif @active_gateway == "Webpay"
        #          @merchant_id = PaymentConfiguration.config_value("webpay_merchant_id")
        #          @merchant_id ||= String.new
        #          @product_id = PaymentConfiguration.config_value("webpay_product_id")
        #          @product_id ||= String.new
        #          @item_id = PaymentConfiguration.config_value("webpay_item_id")
        #          @item_id ||= String.new
        @custom_gateway = CustomGateway.find(@active_gateway)
#        @custom_gateway.gateway_parameters[:config_fields].each_pair do|k,v|
#          instance_variable_set("@"+k,v)
#        end
      end
      hostname = "#{request.protocol}#{request.host_with_port}"
      if params[:create_transaction].present?
        gateway_response = Hash.new
        #        if @active_gateway == "Paypal"
        #          gateway_response = {
        #            :amount => params[:amt],
        #            :status => params[:st],
        #            :transaction_id => params[:tx]
        #          }
        #        elsif @active_gateway == "Authorize.net"
        #          gateway_response = {
        #            :x_response_code => params[:x_response_code],
        #            :x_response_reason_code => params[:x_response_reason_code],
        #            :x_response_reason_text => params[:x_response_reason_text],
        #            :x_avs_code => params[:x_avs_code],
        #            :x_auth_code => params[:x_auth_code],
        #            :x_trans_id => params[:x_trans_id],
        #            :x_method => params[:x_method],
        #            :x_card_type => params[:x_card_type],
        #            :x_account_number => params[:x_account_number],
        #            :x_first_name => params[:x_first_name],
        #            :x_last_name => params[:x_last_name],
        #            :x_company => params[:x_company],
        #            :x_address => params[:x_address],
        #            :x_city => params[:x_city],
        #            :x_state => params[:x_state],
        #            :x_zip => params[:x_zip],
        #            :x_country => params[:x_country],
        #            :x_phone => params[:x_phone],
        #            :x_fax => params[:x_fax],
        #            :x_invoice_num => params[:x_invoice_num],
        #            :x_description => params[:x_description],
        #            :x_type => params[:x_type],
        #            :x_cust_id => params[:x_cust_id],
        #            :x_ship_to_first_name => params[:x_ship_to_first_name],
        #            :x_ship_to_last_name => params[:x_ship_to_last_name],
        #            :x_ship_to_company => params[:x_ship_to_company],
        #            :x_ship_to_address => params[:x_ship_to_address],
        #            :x_ship_to_city => params[:x_ship_to_city],
        #            :x_ship_to_zip => params[:x_ship_to_zip],
        #            :x_ship_to_country => params[:x_ship_to_country],
        #            :x_amount => params[:x_amount],
        #            :x_tax => params[:x_tax],
        #            :x_duty => params[:x_duty],
        #            :x_freight => params[:x_freight],
        #            :x_tax_exempt => params[:x_tax_exempt],
        #            :x_po_num => params[:x_po_num],
        #            :x_cvv2_resp_code => params[:x_cvv2_resp_code],
        #            :x_MD5_hash => params[:x_MD5_hash],
        #            :x_cavv_response => params[:x_cavv_response],
        #            :x_method_available => params[:x_method_available],
        #          }
        #        elsif @active_gateway == "Webpay"
        #          # url = "https://stageserv.interswitchng.com/test_paydirect/api/v1/gettransaction.json"
        #          # url += "?productid=#{@product_id}"
        #          # url += "&transactionreference=#{params[:txnref]}"
        #          # url += "&amount=#{(('%.02f' % @amount).to_f * 100).to_i}"
        #          if File.exists?("#{Rails.root}/vendor/plugins/fedena_pay/config/online_payment_url.yml")
        #            response_urls = YAML.load_file(File.join(Rails.root, "vendor/plugins/fedena_pay/config/", "online_payment_url.yml"))
        #          end
        #          txnref = params[:txnref] || params[:txnRef] || ""
        #          response_url = response_urls.nil? ? nil : eval(response_urls["webpay_response_url"].to_s)
        #          response_url ||= "https://stageserv.interswitchng.com/test_paydirect/api/v1/gettransaction.json"
        #          response_url += "?productid=#{@product_id.strip}"
        #          response_url += "&transactionreference=#{txnref}"
        #          response_url += "&amount=#{(('%.02f' % @amount).to_f * 100).to_i}"
        #          uri = URI.parse(response_url)
        #          http = Net::HTTP.new(uri.host, uri.port)
        #          http.use_ssl = true
        #          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        #          request = Net::HTTP::Get.new(uri.request_uri, {'Hash' => Digest::SHA512.hexdigest(@product_id.strip + txnref.to_s + @merchant_id.strip)})
        #          response = http.request(request)
        #          response_str = JSON.parse response.body
        #          gateway_response = {
        #            :split_accounts => response_str["SplitAccounts"],
        #            :merchant_reference => response_str["MerchantReference"],
        #            :response_code => response_str["ResponseCode"],
        #            :lead_bank_name => response_str["LeadBankName"],
        #            :lead_bank_cbn_code => response_str["LeadBankCbnCode"],
        #            :amount => response_str["Amount"].to_f/ 100,
        #            :card_number => response_str["CardNumber"],
        #            :response_description => response_str["ResponseDescription"],
        #            :transaction_date => response_str["TransactionDate"],
        #            :retrieval_reference_number => response_str["RetrievalReferenceNumber"],
        #            :payment_reference => response_str["PaymentReference"]
        #          }
        #        end
        if @custom_gateway.present?
          @custom_gateway.gateway_parameters[:response_parameters].each_pair do|k,v|
            unless k.to_s == "success_code"
              gateway_response[k.to_sym] = params[v.to_sym]
            end
          end
        end
        @gateway_status = false
        #        if @active_gateway == "Paypal"
        #          @gateway_status = true if params[:st] == "Completed"
        #        elsif @active_gateway == "Authorize.net"
        #          @gateway_status = true if gateway_response[:x_response_reason_code] == "1"
        #        elsif @active_gateway == "Webpay"
        #          @gateway_status = true if gateway_response[:response_code] == "00"
        #        end
        if @custom_gateway.present?
          success_code = @custom_gateway.gateway_parameters[:response_parameters][:success_code]
          @gateway_status = true if gateway_response[:transaction_status] == success_code
        end
        payment = Payment.new(:payee => @student, :payment => @fee, :gateway_response => gateway_response, :status => @gateway_status, :amount => gateway_response[:amount].to_f, :gateway => @active_gateway)
        payment.fee_collection = @fee_collection

        if payment.save and @fee.finance_transaction_id.nil?
          #amount_from_gateway = 0
          #          if @active_gateway == "Paypal"
          #            amount_from_gateway = params[:amt]
          #          elsif @active_gateway == "Authorize.net"
          #            amount_from_gateway = params[:x_amount]
          #          elsif @active_gateway == "Webpay"
          #            amount_from_gateway = gateway_response[:amount]
          #          end
          amount_from_gateway = gateway_response[:amount]
          if amount_from_gateway.to_f > 0.0 and payment.status
            transaction = FinanceTransaction.new
            transaction.title = @fee.hostel_fee_collection.name
            transaction.category_id = FinanceTransactionCategory.find_by_name('Hostel').id
            transaction.finance = @fee
            transaction.amount = amount_from_gateway.to_f
            transaction.transaction_date = Date.today
            transaction.payment_mode = "Online payment"
            transaction.payee = @fee.student
            if transaction.save
#              @fee.update_attributes(:finance_transaction_id => transaction.id)
              payment.update_attributes(:finance_transaction_id => transaction.id)
              #              online_transaction_id = payment.gateway_response[:transaction_id]
              #              online_transaction_id ||= payment.gateway_response[:x_trans_id]
              #              online_transaction_id ||= payment.gateway_response[:payment_reference]
              online_transaction_id = payment.gateway_response[:transaction_reference]
              @paid_fees=@fee.finance_transaction unless @fee.finance_transaction_id.blank?
            end
            if @gateway_status
              status = Payment.payment_status_mapping[:success]
              payment.update_attributes(:status_description => status)
              flash[:notice] = "#{t('payment_success')} <br>  #{t('payment_reference')} : #{online_transaction_id}"
              if current_user.parent?
                user = current_user
              else
                user = @student.user
              end
              if @student.is_email_enabled && user.email.present?
                begin
                  Delayed::Job.enqueue(OnlinePayment::PaymentMail.new(payment.fee_collection.name, user.email, user.full_name, @custom_gateway.name, payment.amount, online_transaction_id, payment.gateway_response, user.school_details, hostname))
                rescue Exception => e
                  puts "Error------#{e.message}------#{e.backtrace.inspect}"
                  return
                end
              end
            else
              status = Payment.payment_status_mapping[:failed]
              payment.update_attributes(:status_description => status)
              flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{payment.gateway_response[:reason_code] || 'N/A'} <br> #{t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
            end
          else
            status = Payment.payment_status_mapping[:failed]
            payment.update_attributes(:status_description => status)
            flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{payment.gateway_response[:reason_code] || 'N/A'} <br> #{t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
          end
        else
          flash[:notice] = "#{t('already_paid')}"
        end
        redirect_to :controller => 'hostel_fee', :action => 'student_profile_fee_details', :id => params[:id], :id2 => params[:id2]
      end
    end
  end

  def delete_hostel_fee_transaction
    @financetransaction=FinanceTransaction.find(params[:id])
    @student=@financetransaction.payee
    @transaction=@financetransaction.finance
    @date=@transaction.hostel_fee_collection
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      payment = @financetransaction.payment
      unless payment.nil?
        status = Payment.payment_status_mapping[:reverted]
        payment.update_attributes(:status_description => status)
        payment.save
      end
    end
    if @financetransaction
       @financetransaction.destroy
    end
    render :update do |page|
      page.replace_html "fees_details",:partial=>"fees_details"
    end
#    render :js=> "new Ajax.Request('/hostel_fee/hostel_fee_collection_defaulters_details', {method: 'get',parameters: {student: #{@student.id},batch_id:#{@student.batch_id},date:#{@date.id}}});"
   
  end

  def student_wise_fee_collection_new
    error=false
    HostelFeeCollection.transaction do
      @hostel_fee_collection = HostelFeeCollection.new(params[:hostel_fee_collection])
      if request.post?
        if @hostel_fee_collection.save
          event=Event.new(:title => "#{t('hostel_fee_text')}", :description => "#{t('fee_name')}: #{@hostel_fee_collection.name}", :start_date => @hostel_fee_collection.start_date.to_s, :end_date => @hostel_fee_collection.end_date.to_s, :is_due => true, :origin => @hostel_fee_collection, :user_events_attributes => params["event"])
          error=true unless event.save
          recipients=[]

          params[:event].each { |k, v| recipients<<v["user_id"] }
          send_reminder(@hostel_fee_collection, recipients)
        else
          error=true
        end

        if error
          render :update do |page|
            page.replace_html "collection-details", :partial => 'student_wise_fee_collection_new'
          end
          raise ActiveRecord::Rollback

        else
          flash[:notice]="#{t('collection_date_has_been_created')}"
          render :update do |page|
            page.redirect_to :action => 'collection_creation_and_assign'
          end
        end
      else
        render :update do |page|
          page.replace_html "collection-details", :partial => 'student_wise_fee_collection_new'
        end
      end
    end
  end

  def search_student
    students= Student.active.find(:all, :joins => [{:room_allocations => :room_detail}], :conditions => ["(admission_no LIKE ? OR first_name LIKE ?) and room_allocations.is_vacated=false", "%#{params[:query]}%", "%#{params[:query]}%"]).uniq
    suggestions=students.collect { |s| s.full_name.length+s.admission_no.length > 20 ? s.full_name[0..(18-s.admission_no.length)]+".. "+"(#{s.admission_no})"+" - "+s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.rent.to_s+"(#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.name}-#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.type})" : s.full_name+"(#{s.admission_no})"+" - "+s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.rent.to_s+"(#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.name}-#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.type})" }

    student_datas=students.map { |st| "{'id': #{st.id}, 'rent' : #{st.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.rent},'user_id':#{st.user_id}}" }
    if students.present?
      render :json => {'query' => params["query"], 'suggestions' => suggestions, 'data' => student_datas}
    else
      render :json => {'query' => params["query"], 'suggestions' => ["#{t('no_users')}"], 'data' => ["{'receiver': #{false}}"]}
    end
  end

  def allocate_or_deallocate_fee_collection
    error=false
    @batches = Batch.active
    if request.post?
      HostelFee.transaction do
        params[:fees_list][:collection_ids].present? ? colln_ids=params[:fees_list][:collection_ids] : colln_ids=[0]
        student=Student.find(params[:fees_list][:receiver_id])
        # rent=student.room_allocations.find(:first,:conditions=>"is_vacated=false").room_detail.rent.to_f
        HostelFee.update_all("is_active=false", ["student_id='#{student.id}' and hostel_fee_collection_id not in (?)", colln_ids])
        HostelFee.update_all(["is_active=true"], ["student_id='#{student.id}' and hostel_fee_collection_id in (?)", colln_ids])
        student.send(:attributes=, params[:new_collection_ids])
        student.save(false)
        user_events=UserEvent.create(params[:user_events].values) if params[:user_events].present?

        if (error)
          render :update do |page|
            page.replace_html 'flash-div', :text => "<div id='error-box'><ul><li>#{t('fees_text')} #{t('transport_fee.allocation')} #{t('failed')}</li></ul></div>"
          end
          raise ActiveRecord::Rollback
        else
          render :update do |page|
            page.replace_html 'flash-div', :text => "<p class='flash-msg'>#{t('fee_collections_are_updated_to_the_student_successfully')} </p>"
          end
        end
      end
    end
  end

  def list_students_by_batch
    @students = Student.find(:all, :select => 'distinct students.*', :joins => [:hostel_fees => :hostel_fee_collection], :conditions => "students.batch_id='#{params[:batch_id]}' and hostel_fee_collections.is_deleted=false and hostel_fees.finance_transaction_id is NULL", :order => 'first_name ASC')
    unless @students.blank?
      @student = @students.first
      # @rent=@student.room_allocations.find(:first,:conditions=>"is_vacated=false").room_detail.rent.to_f
      @fee_collection_dates=HostelFeeCollection.find(:all, :select => "distinct hostel_fee_collections.*,hostel_fees.is_active as assigned", :joins => "INNER JOIN `hostel_fees` ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id", :conditions => "hostel_fees.student_id='#{@student.id}' and hostel_fee_collections.is_deleted=false and hostel_fees.finance_transaction_id is NULL")
      # TransportFeeCollection.find(:all,:select=>"transport_fee_collections.*,IF(transport_fees.receiver_id='#{@student.id}',true,false) as assigned",:joins=>"LEFT OUTER JOIN `transport_fees` ON transport_fees.transport_fee_collection_id = transport_fee_collections.id LEFT OUTER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'",:conditions=>"students.batch_id='#{params[:batch_id]}'")
    end
    render :partial => 'students_collections_list'
  end

  def list_fees_for_student
    @student = Student.find_by_id(params[:receiver])
    @fee_collection_dates=HostelFeeCollection.find(:all, :select => "distinct hostel_fee_collections.*,hostel_fees.is_active as assigned", :joins => "INNER JOIN `hostel_fees` ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id", :conditions => "hostel_fees.student_id='#{@student.id}' and hostel_fee_collections.is_deleted=false and hostel_fees.finance_transaction_id is NULL")
    render :update do |page|
      page.replace_html 'fees_list', :partial => 'fees_list'
    end
  end

  def list_fee_collections_for_student
    @student=Student.find(params[:receiver_id])
    params[:collection_ids].present? ? colln_ids=params[:collection_ids] : colln_ids=[0]
    fee_collections= HostelFeeCollection.find(:all, :include => :event, :select => "distinct hostel_fee_collections.*", :joins => :hostel_fees, :conditions => ["(name LIKE ?) and hostel_fee_collections.id not in (?) and  (hostel_fee_collections.batch_id is null or hostel_fee_collections.batch_id='#{params[:batch_id]}')", "%#{params[:query]}%", colln_ids])
    data_values=fee_collections.map { |f| "{'id':#{f.id}, 'event_id' : #{f.event.id}}" }
    render :json => {'query' => params["query"], 'suggestions' => fee_collections.collect { |fc| fc.name.length+fc.start_date.to_s.length > 20 ? fc.name[0..(18-fc.start_date.to_s.length)]+".. "+" - "+fc.start_date.to_s : fc.name+" - "+fc.start_date.to_s }, 'data' => data_values}
  end

  def collection_creation_and_assign
    @batches =Batch.find(:all, :select => "distinct `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name", :joins => "INNER JOIN students on students.batch_id=batches.id INNER JOIN room_allocations on students.id=room_allocations.student_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id", :conditions => "batches.is_active=1 and batches.is_deleted=0" ,:order=>"course_full_name",:include=>:course)
    @dates=[]
  end


  def update_fees_collections
    @dates=HostelFeeCollection.find(:all, :select => "distinct hostel_fee_collections.*", :joins => "INNER JOIN `hostel_fees` ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id INNER JOIN students on students.id=hostel_fees.student_id", :conditions => "students.batch_id='#{params[:batch_id]}' and hostel_fee_collections.is_deleted=false")
    render :update do |page|
      page.replace_html 'fees_collection_dates', :partial => 'fees_collection_dates'
    end
  end

  def render_collection_assign_form
    @hostel_fee_collection=HostelFeeCollection.find(params[:id])
    render :update do |page|
      page.replace_html 'students_selection', :partial => 'students_selection'
    end
  end


  def list_students_for_collection
    @collection=HostelFeeCollection.find(params[:date_id], :include => :hostel_fees)
    student_ids=@collection.hostel_fees.collect(&:student_id)
    student_ids=student_ids.join(',')

    students= Student.active.find(:all, :joins => [:room_allocations => :room_detail], :conditions => ["(admission_no LIKE ? OR first_name LIKE ?) and students.id not in (#{student_ids}) and batch_id='#{params[:batch_id]}' ", "%#{params[:query]}%", "%#{params[:query]}%"]).uniq
    suggestions=students.collect { |s| s.full_name.length+s.admission_no.length > 20 ? s.full_name[0..(18-s.admission_no.length)]+".. "+"(#{s.admission_no})"+" - "+s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.rent.to_s+"(#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.name}-#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.type})" : s.full_name+"(#{s.admission_no})"+" - "+s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.rent.to_s+"(#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.name}-#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.type})" }
    receivers=students.map { |st| "{'receiver': 'Student','id': #{st.id}, 'rent' : #{st.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.rent.to_s},'user_id':#{st.user_id}}" }
    if receivers.present?
      render :json => {'query' => params["query"], 'suggestions' => suggestions, 'data' => receivers}
    else
      render :json => {'query' => params["query"], 'suggestions' => ["#{t('no_users')}"], 'data' => ["{'receiver': #{false}}"]}
    end
  end

  def collection_assign_students
    @hostel_fee_collection=HostelFeeCollection.find(params[:hostel_fee_collection][:id])
    event=@hostel_fee_collection.event
    @hostel_fee_collection.update_attributes(:hostel_fees_attributes => params[:hostel_fee_collection][:hostel_fees_attributes].values)
    if (params[:event].present?)
      recipients=[]
      user_events=event.user_events.create(params[:event].values) if event
      params[:event].each { |k, v| recipients<<v["user_id"] }
      send_reminder(@hostel_fee_collection, recipients)
    end
    flash[:notice]="#{t('collection_date_has_been_created')}"
    redirect_to :action => 'collection_creation_and_assign'
  end

  def choose_collection_and_assign
    @batches =Batch.find(:all, :select => "distinct batches.*", :joins => "INNER JOIN students on students.batch_id=batches.id INNER JOIN room_allocations on students.id=room_allocations.student_id", :conditions => "batches.is_active=1 and batches.is_deleted=0")
    @dates=[]
    render :update do |page|
      page.replace_html "collection-details", :partial => 'choose_collection_and_assign'
    end
  end
end

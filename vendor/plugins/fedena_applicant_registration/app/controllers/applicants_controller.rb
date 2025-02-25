class ApplicantsController < ApplicationController
  require 'authorize_net'
  helper :authorize_net
  layout :choose_layout
  before_filter :login_required,:except=>[:new,:create,:success,:complete,:show_form,:print_application,:show_pin_entry_form,:get_amount,:registration_return]
  before_filter :load_common
  before_filter :load_lang,:only=>[:new,:create,:success,:complete,:show_form,:show_pin_entry_form]
  before_filter :set_precision
  skip_before_filter :verify_authenticity_token, :only => [:registration_return]
  def choose_layout
    return 'application' if action_name == 'edit' or action_name == 'update'
    'applicants'
  end

  def index
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end

  def new
    @courses = RegistrationCourse.active.all(:order => "courses.course_name",:joins => :course)
  end

  def show_pin_entry_form
    if request.xhr?
      render :update do |page|
        @course = RegistrationCourse.find(params[:course_id])
        unless @course.nil?
          if !course_pin_system_registered_for_course(@course.course_id)
            page.replace_html 'pin_entry_form',:partial => 'pin_entry_form'
            page.replace_html 'form',:text => ''
          else
            @countries = Country.all
            @applicant = Applicant.new
            @applicant_guardian = @applicant.build_applicant_guardian
            @selected_value = Configuration.default_country
            @applicant.build_applicant_guardian
            @applicant.build_applicant_previous_data
            @applicant.applicant_addl_attachments.build
            @addl_field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>{:registration_course_id=>params[:course_id],:is_active=>true})
            @subjects = @course.course.batches.active.map(&:all_elective_subjects).flatten.compact.map(&:code).compact.flatten.uniq
            @ele_subjects={}
            subject_amounts=@course.course.subject_amounts
            elective_subject_amounts= subject_amounts.find_all_by_code(@subjects)
            @subjects.each do |sub|
              subject=elective_subject_amounts.find_by_code(sub)
              @ele_subjects.merge!(sub=>subject ? subject.amount.to_f: 0 )
            end
            @selected_subject_ids = @applicant.subject_ids.nil? ? [] : @applicant.subject_ids
            additional_mandatory_fields = StudentAdditionalField.active.all(:conditions => {:is_mandatory => true})
            additional_fields = StudentAdditionalField.find_all_by_id(@course.additional_field_ids).compact
            @additional_fields = (additional_mandatory_fields + additional_fields).uniq.compact.flatten
            @applicant_additional_details = @applicant.applicant_additional_details
            @currency = currency
            if @course.subject_based_fee_colletion == true
              normal_subjects=@course.course.batches.active.map(&:normal_batch_subject).flatten.compact.map(&:code).compact.flatten.uniq
              @normal_subject_amount=subject_amounts.find(:all,:conditions => {:code => normal_subjects}).flatten.compact.map(&:amount).sum
            else
              @normal_subject_amount = @course.amount.to_f
            end
            page.replace_html 'form',:partial => 'form'
            page.replace_html 'pin_entry_form',:text => ''
          end
        else
          page.replace_html 'form',:text => ''
          page.replace_html 'pin_entry_form',:text => ''
        end
      end
    else
      flash[:notice] = t('flash_register')
      redirect_to new_applicant_path
    end
  end

  def show_form
    if request.post?
      pin_no = PinNumber.find_by_number(params[:pin][:pin_number])
      if pin_no.nil?
        flash[:notice] = t('flash5')
        redirect_to new_applicant_path
      else
        if Date.today > pin_no.pin_group.valid_till.to_date or Date.today < pin_no.pin_group.valid_from.to_date
          flash[:notice] = t('flash2')
          redirect_to new_applicant_path
        else
          unless pin_no.is_active?
            flash[:notice] = t('flash3')
            redirect_to new_applicant_path
          else
            if pin_no.is_registered?
              flash[:notice] = t('flash4')
              redirect_to new_applicant_path
            else
              unless pin_no.pin_group.course_ids.include? params[:pin][:course_id]
                flash[:notice] = t('flash5')
                redirect_to new_applicant_path
              else
                @applicant = Applicant.new
                @countries = Country.all
                @course = RegistrationCourse.find(params[:pin][:course_id])
                @subjects = @course.course.batches.active.map(&:all_elective_subjects).flatten.compact.map(&:code).compact.flatten.uniq
                @ele_subjects={}
                subject_amounts=@course.course.subject_amounts
                elective_subject_amounts= subject_amounts.find_all_by_code(@subjects)
                @subjects.each do |sub|
                  subject=elective_subject_amounts.find_by_code(sub)
                  @ele_subjects.merge!(sub=>subject ? subject.amount.to_f: 0 )
                end
                @selected_subject_ids = @applicant.subject_ids.nil? ? [] : @applicant.subject_ids
                @pin_number = params[:pin][:pin_number]
                @applicant_guardian = @applicant.build_applicant_guardian
                @selected_value = Configuration.default_country
                @applicant.build_applicant_guardian
                @applicant.build_applicant_previous_data
                @applicant.applicant_addl_attachments.build
                @addl_field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>{:registration_course_id=>@course.id,:is_active=>true})
                additional_mandatory_fields = StudentAdditionalField.active.all(:conditions => {:is_mandatory => true})
                additional_fields = StudentAdditionalField.find_all_by_id(@course.additional_field_ids).compact
                @additional_fields = (additional_mandatory_fields + additional_fields).uniq.compact.flatten
                @applicant_additional_details = @applicant.applicant_additional_details
                @currency = currency
                if @course.subject_based_fee_colletion == true
                  normal_subjects=@course.course.batches.active.map(&:normal_batch_subject).flatten.compact.map(&:code).compact.flatten.uniq
                  @normal_subject_amount=subject_amounts.find(:all,:conditions => {:code => normal_subjects}).flatten.compact.map(&:amount).sum
                else
                  @normal_subject_amount = @course.amount.to_f
                end
              end
            end
          end
        end
      end
    else
      flash[:notice] = t('flash_register')
      redirect_to new_applicant_path
    end
  end

  def create
    @courses = RegistrationCourse.active
    if params[:applicant][:subject_ids].nil?
      params[:applicant][:subject_ids]=[]
    else
      params[:applicant][:subject_ids].each_with_index do |e,i|
        params[:applicant][:subject_ids][i]=(e.split-e.split.last.to_a).join(" ")
      end
    end
    @course = RegistrationCourse.find(params[:applicant][:registration_course_id])
    @pin_number = params[:applicant][:pin_number]
    @applicant = Applicant.new(params[:applicant])
    @subjects = @course.course.batches.active.map(&:all_elective_subjects).flatten.compact.map(&:code).compact.flatten.uniq
    @ele_subjects={}
    subject_amounts=@course.course.subject_amounts
    elective_subject_amounts= subject_amounts.find_all_by_code(@subjects)
    @subjects.each do |sub|
      subject=elective_subject_amounts.find_by_code(sub)
      @ele_subjects.merge!(sub=>subject ? subject.amount.to_f: 0 )
    end
    @selected_subject_ids = params[:applicant][:subject_ids].nil? ? [] : params[:applicant][:subject_ids]
    @applicant_guardian = @applicant.build_applicant_guardian(params[:applicant_guardian])
    @applicant_previous_data = @applicant.build_applicant_previous_data(params[:applicant_previous_data])
    @addl_field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>{:registration_course_id=>@applicant.registration_course_id,:is_active=>true},\
        :include=>[:applicant_addl_fields=>[:applicant_addl_field_values]])
    additional_mandatory_fields = StudentAdditionalField.active.all(:conditions => {:is_mandatory => true})
    additional_fields = StudentAdditionalField.find_all_by_id(@course.additional_field_ids).compact
    @additional_fields = (additional_mandatory_fields + additional_fields).uniq.compact.flatten
    @applicant_additional_details = @applicant.applicant_additional_details
    @currency = currency
    normal_subjects=@course.course.batches.active.map(&:normal_batch_subject).flatten.compact.map(&:code).compact.flatten.uniq
    if params[:applicant][:subject_ids].present?
      @ele_subject_amount=subject_amounts.find(:all,:conditions => {:code => params[:applicant][:subject_ids]}).flatten.compact.map(&:amount).sum
    else
      @ele_subject_amount=0
    end
    @applicant.normal_subject_ids=normal_subjects
    if @course.subject_based_fee_colletion == true
      @normal_subject_amount=subject_amounts.find(:all,:conditions => {:code => normal_subjects}).flatten.compact.map(&:amount).sum
    else
      @normal_subject_amount=@course.amount.to_f
    end
    @registration_amount = @normal_subject_amount+@ele_subject_amount
    @applicant.amount = @registration_amount.to_f
    if @applicant.amount==0.0
      if @course.enable_approval_system == true
        @applicant.has_paid=true
        @applicant.is_financially_cleared = true
      else
        @applicant.has_paid=true
      end
    end

    
    if @applicant.valid?
      pin_no = PinNumber.find_by_number(@applicant.pin_number)
      unless pin_no.nil?
        unless pin_no.is_registered.present?
          pin_no.update_attributes(:is_registered => true)
        else
          flash[:notice]=t('flash4')
          render :action=>'new' and return
        end
      end
      if @course.include_additional_details == true
        @error=false
        mandatory_fields = StudentAdditionalField.find(:all, :conditions=>{:is_mandatory=>true, :status=>true})
        mandatory_fields.each do|m|
          unless params[:applicant_additional_details][m.id.to_s.to_sym].present?
            @applicant.errors.add_to_base("#{m.name} must contain atleast one selected option.")
            @error=true
          else
            if params[:applicant_additional_details][m.id.to_s.to_sym][:additional_info]==""
              @applicant.errors.add_to_base("#{m.name} cannot be blank.")
              @error=true
            end
          end
        end
        unless @error==true
          if params[:applicant_additional_details].present?
            params[:applicant_additional_details].each_pair do |k, v|
              addl_info = v['additional_info']
              addl_field = StudentAdditionalField.find_by_id(k)
              if addl_field.input_type == "has_many"
                addl_info = addl_info.join(", ")
              end
              addl_detail = @applicant.applicant_additional_details.build(:additional_field_id => k,:additional_info => addl_info)
              addl_detail.valid?
              addl_detail.save if addl_detail.valid?
            end
          end
          @applicant.save
          flash[:notice] = t('flash_success')
          redirect_to :action => "success", :id => @applicant.id
        else
          render "show_form",:course_id => @applicant.registration_course_id
        end
      else
        @applicant.save
        flash[:notice] = t('flash_success')
        redirect_to :action => "success", :id => @applicant.id
      end
    else
      render "show_form",:course_id => @applicant.registration_course_id
    end
  end

  def success
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      if (PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.config_value("enabled_fees").include? "Application Registration")
        @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
        #        if @active_gateway == "Paypal"
        #          @merchant_id = PaymentConfiguration.config_value("paypal_id")
        #          @merchant ||= String.new
        #          @currency_code = PaymentConfiguration.config_value("currency_code")
        #          @currency_code ||= String.new
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
        #        end
        @custom_gateway = CustomGateway.find(@active_gateway)
        
        #        @custom_gateway.gateway_parameters[:config_fields].each_pair do|k,v|
        #          instance_variable_set("@"+k,v)
        #        end
      end
    end
    current_school_name = Configuration.find_by_config_key('InstitutionName').try(:config_value)
    @currency = currency
    @applicant = Applicant.find(params[:id])
  end

  def complete
    @applicant = Applicant.find(params[:applicant])
  end


  def load_common
    @countries = Country.all
  end

  def edit
    @applicant = Applicant.find params[:id]
    @selected_value = Configuration.default_country
    @course = @applicant.registration_course
    @subjects = @course.course.batches.active.map(&:all_elective_subjects).flatten.compact.map(&:code).compact.flatten.uniq
    @ele_subjects={}
    subject_amounts=@course.course.subject_amounts
    elective_subject_amounts= subject_amounts.find_all_by_code(@subjects)
    @subjects.each do |sub|
      subject=elective_subject_amounts.find_by_code(sub)
      @ele_subjects.merge!(sub=>subject ? subject.amount.to_f: 0 )
    end
    @normal_subjects = @course.course.batches.active.map(&:normal_batch_subject).flatten.compact.map(&:code).compact.flatten.uniq
    @selected_subject_ids = @applicant.subject_ids.nil? ? [] : @applicant.subject_ids
    @ele_subject_amount = subject_amounts.find(:all,:conditions => {:code => @selected_subject_ids}).flatten.compact.map(&:amount).sum
    @currency = currency
    @normal_selected_subject_ids = @applicant.normal_subject_ids.nil? ? [] : @applicant.normal_subject_ids
    if @course.subject_based_fee_colletion == true
      @normal_subject_amount=subject_amounts.find(:all,:conditions => {:code => @normal_selected_subject_ids}).flatten.compact.map(&:amount).sum
    else
      @normal_subject_amount=@course.amount.to_f
    end
    @applicant.addl_field_hash
    @applicant_guardian = @applicant.applicant_guardian
    @applicant_previous_data = @applicant.applicant_previous_data
    @addl_field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>{:registration_course_id=> @applicant.registration_course_id, :is_active => true})
    additional_mandatory_fields = StudentAdditionalField.active.all(:conditions => {:is_mandatory => true})
    additional_fields = StudentAdditionalField.find_all_by_id(@course.additional_field_ids).compact
    @additional_fields = (additional_mandatory_fields + additional_fields).uniq.compact.flatten
    @applicant_additional_details = @applicant.applicant_additional_details
  end

  def update
    @applicant = Applicant.find(params[:id])
    @course = @applicant.registration_course
    @subjects = @course.course.batches.active.map(&:all_elective_subjects).flatten.compact.map(&:code).compact.flatten.uniq
    @ele_subjects={}
    subject_amounts=@course.course.subject_amounts
    elective_subject_amounts= subject_amounts.find_all_by_code(@subjects)
    @subjects.each do |sub|
      subject=elective_subject_amounts.find_by_code(sub)
      @ele_subjects.merge!(sub=>subject ? subject.amount.to_f: 0 )
    end
    @normal_subjects = @course.course.batches.active.map(&:normal_batch_subject).flatten.compact.map(&:code).compact.flatten.uniq
    @selected_subject_ids = params[:applicant][:subject_ids].nil? ? [] : params[:applicant][:subject_ids]
    if params[:applicant][:subject_ids].nil?
      params[:applicant][:subject_ids]=[]
    else
      params[:applicant][:subject_ids].each_with_index do |e,i|
        params[:applicant][:subject_ids][i]=(e.split-e.split.last.to_a).join(" ")
      end
    end
    if params[:applicant][:normal_subject_ids].nil?
      params[:applicant][:normal_subject_ids]=[]
    end
    @ele_subject_amount = subject_amounts.find(:all,:conditions => {:code => params[:applicant][:subject_ids]}).flatten.compact.map(&:amount).sum
    @currency = currency
    @normal_selected_subject_ids = params[:applicant][:normal_subject_ids].nil? ? [] : params[:applicant][:normal_subject_ids]
    if @course.subject_based_fee_colletion == true
      @normal_subject_amount=subject_amounts.find(:all,:conditions => {:code => @normal_selected_subject_ids}).flatten.compact.map(&:amount).sum
    else
      @normal_subject_amount=@course.amount.to_f
    end
    @applicant.addl_field_hash
    @applicant_guardian = @applicant.applicant_guardian
    @applicant_previous_data = @applicant.applicant_previous_data
    @addl_field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>{:registration_course_id=> @applicant.registration_course_id, :is_active => true})
    additional_mandatory_fields = StudentAdditionalField.active.all(:conditions => {:is_mandatory => true})
    additional_fields = StudentAdditionalField.find_all_by_id(@course.additional_field_ids).compact
    @additional_fields = (additional_mandatory_fields + additional_fields).uniq.compact.flatten
    @applicant_additional_details = @applicant.applicant_additional_details
    
    if Applicant.new(params[:applicant]).valid?
      if @course.subject_based_fee_colletion == true
        if params[:applicant][:subject_ids].present?
          all_subjects = params[:applicant][:subject_ids]
          all_subjects += params[:applicant][:normal_subject_ids] unless  params[:applicant][:normal_subject_ids].nil?
        else
          all_subjects = params[:applicant][:normal_subject_ids] unless  params[:applicant][:normal_subject_ids].nil?
        end
        total_amount = @course.course.subject_amounts.find(:all,:conditions => {:code => all_subjects}).flatten.compact.map(&:amount).sum
        @applicant.amount = total_amount.to_f
      else
        @applicant.amount = @course.amount.to_f
      end
      if @applicant.applicant_guardian == nil
        @applicant_guardian = @applicant.build_applicant_guardian(params[:applicant_guardian])
        @applicant_previous_data = @applicant.build_applicant_previous_data(params[:applicant_previous_data])
      else
        @applicant_guardian = @applicant.applicant_guardian
        @applicant_guardian.attributes = params[:applicant_guardian]
        @applicant_previous_data = @applicant.applicant_previous_data
        @applicant_previous_data.attributes = params[:applicant_previous_data]
      end
      if @course.include_additional_details == true
        @error=false
        mandatory_fields = StudentAdditionalField.find(:all, :conditions=>{:is_mandatory=>true, :status=>true})
        mandatory_fields.each do|m|
          unless params[:applicant_additional_details][m.id.to_s.to_sym].present?
            @applicant.errors.add_to_base("#{m.name} must contain atleast one selected option.")
            @error=true
            @applicant_guardian = @applicant.applicant_guardian
            @applicant_previous_data = @applicant.applicant_previous_data
            render :edit and return
          else
            if params[:applicant_additional_details][m.id.to_s.to_sym][:additional_info]==""
              @applicant.errors.add_to_base("#{m.name} cannot be blank.")
              @error=true
              @applicant_guardian = @applicant.applicant_guardian
              @applicant_previous_data = @applicant.applicant_previous_data
              render :edit and return
            end
          end
        end
        unless @error==true
          if params[:applicant_additional_details].present?
            params[:applicant_additional_details].each_pair do |k, v|
              addl_info = v['additional_info']
              addl_field = StudentAdditionalField.find_by_id(k)
              if addl_field.input_type == "has_many"
                addl_info = addl_info.join(", ")
              end
              prev_record = @applicant.applicant_additional_details.find_by_additional_field_id(k)
              unless prev_record.nil?
                unless addl_info.present?
                  prev_record.destroy
                else
                  prev_record.update_attributes(:additional_info => addl_info)
                end
              else
                addl_detail = @applicant.applicant_additional_details.build(:additional_field_id => k,:additional_info => addl_info)
                addl_detail.save if addl_detail.valid?
              end
            end
          end
          @applicant_previous_data.errors.each{|attr,msg| @applicant.errors.add(attr.to_sym,"#{msg}")} unless @applicant_previous_data.save
          @applicant_guardian.errors.each{|attr,msg| @applicant.errors.add(attr.to_sym,"#{msg}")} unless (@applicant_guardian.save and @applicant_previous_data.errors.blank?)
          if (@applicant.errors.blank? and @applicant.update_attributes(params[:applicant]))
            redirect_to :controller=>"applicants_admins",:action=>"view_applicant",:id=>@applicant.id and return
          else
            render :edit and return
          end
        end
      else
        @applicant_previous_data.errors.each{|attr,msg| @applicant.errors.add(attr.to_sym,"#{msg}")} unless @applicant_previous_data.save
        @applicant_guardian.errors.each{|attr,msg| @applicant.errors.add(attr.to_sym,"#{msg}")} unless (@applicant_guardian.save and @applicant_previous_data.errors.blank?)
        @applicant_guardian.save
        if (@applicant.errors.blank? and @applicant.update_attributes(params[:applicant]))
          flash[:notice]="#{t('successful_update')}"
          redirect_to :controller=>"applicants_admins",:action=>"view_applicant",:id=>@applicant.id and return
        else
          render :edit
        end
      end
    else
      @applicant.update_attributes(params[:applicant])
      render :edit
    end
  end

  def print_application
    @elective_name=[]
    if params[:token_check].nil?
      @applicant = Applicant.find(params[:id])
    else
      @applicant ||= Applicant.find_by_print_token(params[:token_check][:print_token])
    end
    @electives=@applicant.subject_ids
    @electives.each do |elec|
      @elective_name<<Subject.find_by_code(elec)
    end
    @addl_values = @applicant.applicant_addl_values
    @additional_details = @applicant.applicant_additional_details
    @financetransaction=FinanceTransaction.find_by_title("Applicant Registration - #{@applicant.reg_no} - #{@applicant.full_name}")
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
      if @active_gateway.nil?
        render :pdf => "application",:zoom => 0.90 and return
      end
      if (PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.config_value("enabled_fees").include? "Application Registration")
        online_payment = Payment.find_by_payee_id_and_payee_type(@applicant.id,'Applicant')
        if online_payment.nil?
          @online_transaction_id = @applicant.has_paid == true ? nil : t('fee_not_paid')
        else
          @online_transaction_id = online_payment.gateway_response[:transaction_reference]
#          if online_payment.gateway_response.keys.include? :transaction_id
#            @online_transaction_id = online_payment.gateway_response[:transaction_id]
#          elsif online_payment.gateway_response.include? :x_trans_id
#            @online_transaction_id = online_payment.gateway_response[:x_trans_id]
#          end
        end
      else
        @online_transaction_id = nil
      end
    end
    render :pdf => "application",:zoom => 0.90
  end

  def registration_return
    @currency = currency
    @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
    #    if @active_gateway == "Paypal"
    #      @merchant_id = PaymentConfiguration.config_value("paypal_id")
    #      @currency_code = PaymentConfiguration.config_value("currency_code")
    #      @certificate = PaymentConfiguration.config_value("paypal_certificate")
    #    elsif @active_gateway == "Authorize.net"
    #      @merchant_id = PaymentConfiguration.config_value("authorize_net_merchant_id")
    #      @certificate = PaymentConfiguration.config_value("authorize_net_transaction_password")
    #    elsif @active_gateway == "Webpay"
    #      @merchant_id = PaymentConfiguration.config_value("webpay_merchant_id")
    #      @merchant_id ||= String.new
    #      @product_id = PaymentConfiguration.config_value("webpay_product_id")
    #      @product_id ||= String.new
    #      @item_id = PaymentConfiguration.config_value("webpay_item_id")
    #      @item_id ||= String.new
    #    end
    @custom_gateway = CustomGateway.find(@active_gateway)

    #    @custom_gateway.gateway_parameters[:config_fields].each_pair do|k,v|
    #      instance_variable_set("@"+k,v)
    #    end
    @applicant = Applicant.find(params[:id])
    hostname = "#{request.protocol}#{request.host_with_port}"
    if params[:create_transaction].present?
      gateway_response = Hash.new
      #      if @active_gateway == "Paypal"
      #        gateway_response = {
      #          :amount => params[:amt],
      #          :status => params[:st],
      #          :transaction_id =>params[:tx]
      #        }
      #      elsif @active_gateway == "Authorize.net"
      #        gateway_response = {
      #          :x_response_code => params[:x_response_code],
      #          :x_response_reason_code => params[:x_response_reason_code],
      #          :x_response_reason_text => params[:x_response_reason_text],
      #          :x_avs_code => params[:x_avs_code],
      #          :x_auth_code => params[:x_auth_code],
      #          :x_trans_id => params[:x_trans_id],
      #          :x_method => params[:x_method],
      #          :x_card_type => params[:x_card_type],
      #          :x_account_number => params[:x_account_number],
      #          :x_first_name => params[:x_first_name],
      #          :x_last_name => params[:x_last_name],
      #          :x_company => params[:x_company],
      #          :x_address => params[:x_address],
      #          :x_city => params[:x_city],
      #          :x_state => params[:x_state],
      #          :x_zip => params[:x_zip],
      #          :x_country => params[:x_country],
      #          :x_phone => params[:x_phone],
      #          :x_fax => params[:x_fax],
      #          :x_invoice_num => params[:x_invoice_num],
      #          :x_description => params[:x_description],
      #          :x_type => params[:x_type],
      #          :x_cust_id => params[:x_cust_id],
      #          :x_ship_to_first_name => params[:x_ship_to_first_name],
      #          :x_ship_to_last_name => params[:x_ship_to_last_name],
      #          :x_ship_to_company => params[:x_ship_to_company],
      #          :x_ship_to_address => params[:x_ship_to_address],
      #          :x_ship_to_city => params[:x_ship_to_city],
      #          :x_ship_to_zip => params[:x_ship_to_zip],
      #          :x_ship_to_country => params[:x_ship_to_country],
      #          :x_amount => params[:x_amount],
      #          :x_tax => params[:x_tax],
      #          :x_duty => params[:x_duty],
      #          :x_freight => params[:x_freight],
      #          :x_tax_exempt => params[:x_tax_exempt],
      #          :x_po_num => params[:x_po_num],
      #          :x_cvv2_resp_code => params[:x_cvv2_resp_code],
      #          :x_MD5_hash => params[:x_MD5_hash],
      #          :x_cavv_response => params[:x_cavv_response],
      #          :x_method_available => params[:x_method_available],
      #        }
      #      elsif @active_gateway == "Webpay"
      #        if File.exists?("#{Rails.root}/vendor/plugins/fedena_pay/config/online_payment_url.yml")
      #          response_urls = YAML.load_file(File.join(Rails.root,"vendor/plugins/fedena_pay/config/","online_payment_url.yml"))
      #        end
      #        txnref = params[:txnref] || params[:txnRef] || ""
      #        response_url = response_urls.nil? ? nil : response_urls["webpay_response_url"]
      #        response_url ||= "https://stageserv.interswitchng.com/test_paydirect/api/v1/gettransaction.json"
      #        response_url += "?productid=#{@product_id.strip}"
      #        response_url += "&transactionreference=#{txnref}"
      #        response_url += "&amount=#{(('%.02f' % @applicant.amount).to_f * 100).to_i}"
      #        uri = URI.parse(response_url)
      #        http = Net::HTTP.new(uri.host, uri.port)
      #        http.use_ssl = true
      #        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      #        request = Net::HTTP::Get.new(uri.request_uri, {'Hash' => Digest::SHA512.hexdigest(@product_id.strip + txnref.to_s  + @merchant_id.strip)})
      #        response = http.request(request)
      #        response_str = JSON.parse response.body
      #        #url = "https://stageserv.interswitchng.com/test_paydirect/api/v1/gettransaction.json"
      #        #url += "?productid=#{@product_id}"
      #        #url += "&transactionreference=#{params[:txnref]}"
      #        #url += "&amount=#{(('%.02f' % @applicant.amount).to_f * 100).to_i}"
      #        #uri = URI.parse(url)
      #        #txnref = params[:txnref]
      #        #txnref ||= ""
      #        #http = Net::HTTP.new(uri.host, uri.port)
      #        #http.use_ssl = true
      #        #http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      #        #request = Net::HTTP::Get.new(uri.request_uri, {'Hash' => Digest::SHA512.hexdigest("4220" + "#{txnref}" + PaymentConfiguration.config_value("webpay_merchant_id"))})
      #        #response = http.request(request)
      #        #response_str = JSON.parse response.body
      #        gateway_response = {
      #          :split_accounts => response_str["SplitAccounts"],
      #          :merchant_reference => response_str["MerchantReference"],
      #          :response_code => response_str["ResponseCode"],
      #          :lead_bank_name => response_str["LeadBankName"],
      #          :lead_bank_cbn_code => response_str["LeadBankCbnCode"],
      #          :amount => response_str["Amount"],
      #          :card_number => response_str["CardNumber"],
      #          :response_description => response_str["ResponseDescription"],
      #          :transaction_date => response_str["TransactionDate"],
      #          :retrieval_reference_number => response_str["RetrievalReferenceNumber"],
      #          :payment_reference => response_str["PaymentReference"],
      #        }
      if @custom_gateway.present?
        @custom_gateway.gateway_parameters[:response_parameters].each_pair do|k,v|
          unless k.to_s == "success_code"
            gateway_response[k.to_sym] = params[v.to_sym]
          end
        end
      end
     
      #    amount_from_gateway = 0
      #    if @active_gateway == "Paypal"
      #      amount_from_gateway = params[:amt]
      #    elsif @active_gateway == "Authorize.net"
      #      amount_from_gateway = params[:x_amount]
      #    elsif @active_gateway == "Webpay"
      #      amount_from_gateway = (gateway_response[:amount].to_f) /100
      #    end
      amount_from_gateway = gateway_response[:amount]
    
      #    receipt = String.new
      #    if @active_gateway == "Paypal"
      #      receipt = params[:tx]
      #    elsif @active_gateway == "Authorize.net"
      #      receipt = params[:x_trans_id]
      #    elsif @active_gateway == "Webpay"
      #      receipt = params[:txnref]
      #    end
      receipt = gateway_response[:transaction_reference]
      gateway_status = false
      #    if @active_gateway == "Paypal"
      #      gateway_status = true if gateway_response[:status] == "Completed"
      #    elsif @active_gateway == "Authorize.net"
      #      gateway_status = true if gateway_response[:x_response_reason_code] == "1"
      #    elsif @active_gateway == "Webpay"
      #      gateway_status = true if gateway_response[:response_code] == "00"
      #    end
      if @custom_gateway.present?
        success_code = @custom_gateway.gateway_parameters[:response_parameters][:success_code]
        gateway_status = true if gateway_response[:transaction_status] == success_code
      end
      payment = Payment.new(:payee => @applicant,:payment_type => "Application",:payment_id => ActiveSupport::SecureRandom.hex,:gateway_response => gateway_response, :status => gateway_status, :amount => amount_from_gateway.to_f, :gateway => @active_gateway)
      if payment.save
        if gateway_status.to_s == "true" and @applicant.amount.to_f == amount_from_gateway.to_f
          transaction = @applicant.mark_paid
          payment.update_attributes(:finance_transaction_id => transaction.id)
          #        online_transaction_id = payment.gateway_response[:transaction_id]
          #        online_transaction_id ||= payment.gateway_response[:x_trans_id]
          #        online_transaction_id ||= payment.gateway_response[:payment_reference]
          online_transaction_id = payment.gateway_response[:transaction_reference]
          flash[:notice] = "#{t('payment_success')} <br>  #{t('payment_reference')} : #{online_transaction_id}"
          if @applicant.email.present?
            begin
              Delayed::Job.enqueue(OnlinePayment::PaymentMail.new("Applicant",@applicant.email,@applicant.full_name,@custom_gateway.name,payment.gateway_response[:amount].to_f,online_transaction_id,payment.gateway_response,school_details,hostname))
            rescue Exception => e
              puts "Error------#{e.message}------#{e.backtrace.inspect}"
              return
            end
          end
        else
          flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{payment.gateway_response[:reason_code] || 'N/A'} <br> #{t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
        end
      else
        flash[:notice] = "#{t('already_payed')}"
      end
      redirect_to :action => "registration_return" , :params => {:id => params[:id]}
    end
  end


  def load_lang
    if params[:lang]
      session[:register_lang] = params[:lang]
    else
      session[:register_lang] = "en" unless session[:register_lang]
    end
    institution_type=institution_type=Configuration.find_by_config_key("InstitutionType").try(:config_value).present? ? Configuration.find_by_config_key("InstitutionType").try(:config_value) : 'hd'
    I18n.locale = "#{session[:register_lang]}-#{institution_type}"
  end

  private

  def school_details
    name=Configuration.get_config_value('InstitutionName').present? ? "#{Configuration.get_config_value('InstitutionName')}," :""
    address=Configuration.get_config_value('InstitutionAddress').present? ? "#{Configuration.get_config_value('InstitutionAddress')}," :""
    Configuration.get_config_value('InstitutionPhoneNo').present?? phone="#{' Ph:'}#{Configuration.get_config_value('InstitutionPhoneNo')}" :""
    return (name+"#{' '}#{address}"+"#{phone}").chomp(',')
  end

end

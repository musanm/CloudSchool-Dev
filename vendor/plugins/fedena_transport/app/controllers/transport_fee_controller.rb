class TransportFeeController < ApplicationController
  require 'authorize_net'
  helper :authorize_net
  before_filter :login_required
  filter_access_to :all
  before_filter :set_precision
  protect_from_forgery :except => [:student_profile_fee_details]

  def index

  end

  def transport_fee_collection_new
    @fee_categories = FinanceFeeCategory.find(:all, :conditions => ["is_master = '#{1}' and is_deleted = '#{false}'"])
    @transport_fee_collection = TransportFeeCollection.new
    @batches = Batch.active
    @batches.reject! { |x| x.transports.blank? }
  end

  def send_reminder(transport_fee_collection, recipients)

    subject = "#{t('fees_submission_date')}"
    body = "<p><b>#{t('fee_submission_date_for')} <i>"+ "#{transport_fee_collection.name}" +"</i> #{t('has_been_published')} </b><br /><br/>
                                #{t('start_date')} : "+transport_fee_collection.start_date.to_s+" <br />"+
      " #{t('end_date')} :"+transport_fee_collection.end_date.to_s+" <br /> "+
      " #{t('due_date')} :"+transport_fee_collection.due_date.to_s+" <br /><br /><br /> "+
      "#{t('regards')}, <br/>" + current_user.full_name.capitalize
    Delayed::Job.enqueue(DelayedReminderJob.new(:sender_id => current_user.id,
        :recipient_ids => recipients,
        :subject => subject,
        :body => body))
  end

  def transport_fee_collection_create
    @transport_fee_collection = TransportFeeCollection.new
    @batches = Batch.active
    @batches.reject! { |x| x.transports.blank? }
    if request.post?
      unless params[:transport_fee_collection].nil?
        @batchs = params[:transport_fee_collection][:batch_ids]
        @include_employee = params[:transport_fee_collection][:employee]
        @params = params[:transport_fee_collection]
        @params.delete("batch_ids")
        @params.delete("employee")
        @transport_fee_collection = TransportFeeCollection.new(@params)
        unless @transport_fee_collection.valid?
          @error = true
        end
        unless @batchs.blank? and @include_employee.blank?
          unless @batchs.blank?
            @batchs.each do |b|
              batch = Batch.find(b)
              @params["batch_id"] = b
              @transport_fee_collection = TransportFeeCollection.new(@params)
              if @transport_fee_collection.save
                @event= Event.create(:title => "#{t('transport_fee_text')}", :description => "#{t('fee_name')}: #{params[:transport_fee_collection][:name]}", :start_date => params[:transport_fee_collection][:due_date], :end_date => params[:transport_fee_collection][:due_date], :is_due => true, :origin => @transport_fee_collection)
                recipients = []

                batch.active_transports.each do |t|
                  student = t.receiver
                  unless student.nil?
                    recipients << student.user.id
                    TransportFee.create(:receiver => student, :bus_fare => t.bus_fare, :transport_fee_collection_id => @transport_fee_collection.id)
                    UserEvent.create(:event_id => @event.id, :user_id => student.user.id)
                  end
                end
                send_reminder(@transport_fee_collection, recipients)

              else
                @error = true
              end
            end
          end
          unless @include_employee.blank?
            @params["batch_id"]=nil
            @transport_fee_collection = TransportFeeCollection.new(@params)
            if @transport_fee_collection.save
              recipients = []
              @event=Event.create(:title => "#{t('transport_fee_text')}", :description => "#{t('fee_name')}: #{params[:transport_fee_collection][:name]}", :start_date => params[:transport_fee_collection][:due_date], :end_date => params[:transport_fee_collection][:due_date], :is_due => true, :origin => @transport_fee_collection)
              employee_transport = Transport.find(:all, :include => :vehicle, :conditions => ["receiver_type = 'Employee' AND vehicles.status = ?", "Active"])
              employee_transport.each do |t|
                emp = t.receiver
                unless emp.nil?
                  TransportFee.create(:receiver => emp, :bus_fare => t.bus_fare, :transport_fee_collection_id => @transport_fee_collection.id)
                  UserEvent.create(:event_id => @event.id, :user_id => emp.user.id)
                  recipients << emp.user.id
                end
              end
              send_reminder(@transport_fee_collection, recipients)

            else
              @error = true
            end
          end
        else
          @error = true
          @transport_fee_collection.errors.add_to_base("#{t('please_select_a_batch_or_emp')}")
        end
      end
      if @error.nil?
        flash[:notice]="#{t('collection_date_has_been_created')}"
        redirect_to :action => 'transport_fee_collection_new'
      else
        render :action => 'transport_fee_collection_new'
      end
    else
      redirect_to :action => 'transport_fee_collection_new'
    end
  end

  def transport_fee_collection_view
    #@transport_fee_collection = ''
    #@batches = Batch.active
    @transport_fee_collection = TransportFeeCollection.paginate(:select => "distinct transport_fee_collections.*", :joins => [:transport_fees], :conditions => "transport_fees.receiver_type='Employee' and is_deleted=false", :per_page => 20, :page => params[:page])
  end


  #def transport_fee_collection_details
  # @transport_fee_details = TransportFee.find_by_transport_fee_collection_id(params[:id])
  #render :update do |page|
  # page.replace_html 'transport_fee_collection_details', :partial => 'transport_fee_collection_details'
  #end
  #end

  def transport_fee_collection_date_edit
    @transport_fee_collection = TransportFeeCollection.find params[:id]
  end

  def transport_fee_collection_date_update
    @transport_fee_collection = TransportFeeCollection.find params[:id]
    render :update do |page|
      if @transport_fee_collection.update_attributes(params[:fee_collection])
        @user_type=params[:user_type]
        @transport_fee_collection.event.update_attributes(:start_date => @transport_fee_collection.due_date.to_datetime, :end_date => @transport_fee_collection.due_date.to_datetime)
        if @user_type=='employee'
          #         @transport_fee_collection = TransportFeeCollection.find(:all, :conditions=>'batch_id IS NULL')
          @transport_fee_collection = TransportFeeCollection.paginate(:select => "distinct transport_fee_collections.*", :joins => [:transport_fees], :conditions => "transport_fees.receiver_type='Employee' and is_deleted=false and transport_fees.is_active=true", :per_page => 20, :page => params[:page])
          page << "Modalbox.hide()" unless params[:page]

          @user_type = 'employee'
          page.replace_html 'fee_collection_list', :partial => 'fee_collection_list'
          page.replace_html 'flash-box', :text => "<p class='flash-msg'>#{t('transport_fee.flash1')}</p>"
          page.replace_html 'batch_list', :text => ''
        elsif @user_type=='student'
          #         @transport_fee_collection = TransportFeeCollection.find_all_by_batch_id(params[:batch_id])
          @transport_fee_collection = TransportFeeCollection.paginate(:all, :select => "distinct transport_fee_collections.*", :joins => "INNER JOIN `transport_fees` ON transport_fees.transport_fee_collection_id = transport_fee_collections.id INNER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'", :conditions => "students.batch_id= #{params[:batch_id]} and transport_fees.is_active=true", :per_page => 20, :page => params[:page])

          @user_type = 'student'
          @batches = Batch.active
          page << "Modalbox.hide()" unless params[:page]
          #          page.replace_html 'batch_list', :partial=>'students_batch_list'
          page.replace_html 'fee_collection_list', :partial => 'fee_collection_list'
          page.replace_html 'flash-box', :text => "<p class='flash-msg'>#{t('transport_fee.flash1')}</p>"
        else
          page.replace_html 'batch_list', :text => ''
          page.replace_html 'fee_collection_list', :text => ''
        end
        #        page << "Modalbox.hide()"
      else
        @errors = true
        page.replace_html 'form-errors', :partial => 'transport_fee/errors', :object => @transport_fee_collection
        page.visual_effect(:highlight, 'form-errors')
      end

    end

  end

  def transport_fee_collection_edit
    @transport_fee_collection = TransportFee.find params[:id]
    @batches = Batch.active
    @selected_batches = [1]
  end

  def transport_fee_collection_update
    @transport_fee_collection = TransportFee.find params[:id]
    flash[:notice]="#{t('flash2')}" if @transport_fee_collection.update_attributes(params[:fee_collection]) if request.post?
    @transport_fee_collection_details = TransportFee.find_all_by_name(@transport_fee_collection.name)
  end

  def transport_fee_collection_delete
    @transport_fee_collection = TransportFee.find params[:id]
    @transport_fee_collection.destroy
    flash[:notice] = "#{t('flash3')}"
    redirect_to :controller => 'transport_fee', :action => 'transport_fee_collection_view'
  end

  def transport_fee_pay

    @transport_fee_collection_details = TransportFee.find params[:id]
    category_id = FinanceTransactionCategory.find_by_name("Transport").id
    transaction = FinanceTransaction.new
    transaction.title = @transport_fee_collection_details.transport_fee_collection.name
    transaction.category_id = category_id
    transaction.amount = @transport_fee_collection_details.bus_fare
    transaction.amount += params[:fine].to_f unless params[:fine].nil?
    transaction.fine_included = true unless params[:fine].nil?
    transaction.transaction_date = Date.today
    transaction.payee = @transport_fee_collection_details.receiver
    transaction.finance = @transport_fee_collection_details
    unless transaction.save
#      @transport_fee_collection_details.update_attribute(:transaction_id, transaction.id)
      render :text => transaction.errors.full_messages and return
    end
    @collection_id = params[:collection_id]
    @transport_fee = TransportFee.find_all_by_transport_fee_collection_id(params[:collection_id])
    #    @transport_fee = TransportFee.find_all_by_transport_fee_collection_id(@transport_fee_collection_details.transport_fee_collection_id)
    @user = TransportFee.find_by_transport_fee_collection_id_and_id(params[:collection_id], params[:id]) unless params[:id].nil?
    @user ||= @transport_fee.first
    @next_user = @user.next_user
    @prev_user = @user.previous_user
    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id)
    @transaction = FinanceTransaction.find_by_id(@user.transaction_id)
    render :update do |page|
      page.replace_html 'transport_fee_collection_details', :partial => 'transport_fee_collection_details'
    end
  end

  def transport_fee_defaulters_view
    @transport_fee_collection = ''
    @batches = Batch.all(:joins=>{:students=>{:transport_fees=>:transport_fee_collection}},:conditions =>["batches.is_deleted=? and batches.is_active=? and transport_fee_collections.is_deleted=? and transport_fee_collections.due_date < ? and transport_fees.bus_fare > ? and transport_fees.transaction_id IS NULL and transport_fees.receiver_type='Student'",false,true,false,Date.today,0.0],:group=>"batches.id")
  end
  
  def transport_fee_defaulters_details
    @transport_fee_details = TransportFeeCollection.find_all_by_name(params[:name])
    @transport_defaulters = @transport_fee_details.reject { |u| !u.transaction_id.nil? }
    render :update do |page|
      page.replace_html 'transport_fee_defaulters_details', :partial => 'transport_fee_defaulters_details'
    end
  end

  def transport_defaulters_fee_pay
    @transport_fee_defaulters_details = TransportFee.find params[:id]
    category_id = FinanceTransactionCategory.find_by_name("Transport").id
    transaction = FinanceTransaction.new
    transaction.title = @transport_fee_defaulters_details.transport_fee_collection.name
    transaction.category_id = category_id
    transaction.transaction_date = Date.today
    transaction.amount = @transport_fee_defaulters_details.bus_fare
    transaction.amount += params[:fine].to_f unless params[:fine].nil?
    transaction.fine_included = true unless params[:fine].nil?
    transaction.payee = @transport_fee_defaulters_details.receiver
    transaction.finance = @transport_fee_defaulters_details
#    if transaction.save
#      @transport_fee_defaulters_details.update_attribute(:transaction_id, transaction.id)
#    end
    @transport_defaulters = TransportFee.find_all_by_transport_fee_collection_id(@transport_fee_defaulters_details.transport_fee_collection_id)
    @transport_defaulters = @transport_defaulters.reject { |u| !u.transaction_id.nil? }
    @collection_id = params[:collection_id]
    @transport_fee_collection= TransportFeeCollection.find_by_id(params[:collection_id])
    @transport_fee = TransportFee.find_all_by_transport_fee_collection_id(params[:collection_id])
    #@transport_fee = @transport_fee.reject{|u| !u.transaction_id.nil? }
    @user = TransportFee.find_by_transport_fee_collection_id_and_id(params[:collection_id], params[:id]) unless params[:id].nil?
    @user ||= @transport_fee_collection.transport_fees.first(:conditions => ["transaction_id is null"])
    @next_user = @user.next_default_user unless @user.nil?
    @prev_user = @user.previous_default_user unless @user.nil?
    @transaction = FinanceTransaction.find_by_id(@user.transaction_id) unless @user.nil?
    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id) unless @user.nil?
    render :update do |page|
      page.replace_html 'defaulters_transport_fee_collection_details', :partial => 'defaulters_transport_fee_collection_details'
    end
  end

  def tsearch_logic # transport search fees structure
    @option = params[:option]
    if params[:option] == "student"
      if params[:query].length>= 3
        @students_result = Student.find(:all,
          :conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                            OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ",
            "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%",
            "#{params[:query]}", "#{params[:query]}"],
          :order => "batch_id asc,first_name asc") unless params[:query] == ''
        @students_result.reject! { |s| s.transport.nil? }
      else
        @students_result = Student.find(:all,
          :conditions => ["admission_no = ? ", params[:query]],
          :order => "batch_id asc,first_name asc") unless params[:query] == ''
        @students_result.reject! { |s| s.transport.nil? }
      end if params[:query].present?
    else

      if params[:query].length>= 3
        @employee_result = Employee.find(:all,
          :conditions => ["(first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                       OR employee_number = ? OR (concat(first_name, \" \", last_name) LIKE ? ))",
            "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%",
            "#{params[:query]}", "#{params[:query]}"],
          :order => "employee_department_id asc,first_name asc") unless params[:query] == ''
        @employee_result.reject! { |s| s.transport.nil? }
      else
        @employee_result = Employee.find(:all,
          :conditions => ["(employee_number = ? )", "#{params[:query]}"],
          :order => "employee_department_id asc,first_name asc") unless params[:query] == ''
        @employee_result.reject! { |s| s.transport.nil? }
      end if params[:query].present?
    end
    render :layout => false
  end

  def fees_student_dates
    @student = Student.find(params[:id])
    @transport_fees = @student.transport_fees.active.all(:conditions => ["bus_fare IS NOT NULL"])
    @dates = @transport_fees.map { |t| t.transport_fee_collection }
    @dates.compact!
  end

  def fees_employee_dates
    @employee = Employee.find(params[:id])
    @transport_fees = @employee.transport_fees.active.all(:conditions => ["bus_fare IS NOT NULL"])
    @dates = @transport_fees.map { |t| t.transport_fee_collection }
    @dates.compact!
  end

  def fees_submission_student
    @user = params[:id]
    @student = Student.find(params[:student])
    @fine = params[:fees][:fine] if params[:fees].present?
    unless params[:date].blank?
      @transport_fee = TransportFee.find_by_receiver_id_and_transport_fee_collection_id(params[:student], params[:date], :conditions => "receiver_type = 'Student'")
      @transport_fee_collection = @transport_fee.transport_fee_collection
      @transaction = FinanceTransaction.find(@transport_fee.transaction_id) unless @transport_fee.transaction_id.nil?
    end
    render :update do |page|
      page.replace_html "fee_submission", :partial => "fees_details"
    end
  end

  def fees_submission_employee
    flash.clear
    if params[:date]==""
      render :update do |page|
        page.replace_html "fee_submission", :text => ""
      end
    else
      @fine=params[:fees][:fine] if params[:fees].present?
      @user = params[:id]
      @employee = Employee.find(params[:id])
      @transport_fee = TransportFee.find_by_receiver_id_and_transport_fee_collection_id(params[:id], params[:date], :conditions => "receiver_type = 'Employee'")
      @transport_fee_collection = @transport_fee.transport_fee_collection
      @transaction = FinanceTransaction.find(@transport_fee.transaction_id) unless @transport_fee.transaction_id.nil?
      render :update do |page|
        page.replace_html "fee_submission", :partial => "fees_details"
      end
    end
  end

  def update_fee_collection_dates
    @transport_fee_collections=TransportFeeCollection.all(:joins=>"INNER JOIN transport_fees on transport_fees.transport_fee_collection_id =transport_fee_collections.id INNER JOIN students on transport_fees.receiver_id=students.id and transport_fees.receiver_type='Student' INNER JOIN batches on students.batch_id=batches.id", :conditions =>["batches.id=? and transport_fee_collections.is_deleted=? and transport_fees.transaction_id IS NULL and transport_fees.bus_fare > ?",params[:batch_id],false,0.0], :group =>"transport_fee_collections.id")
    render :update do |page|
      page.replace_html 'fees_collection_dates', :partial => 'transport_fee_collection_dates'
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

  def transport_fee_collection_pay
    @transport_fee = TransportFee.find(params[:fees][:transport_fee_id])
    @date = @transport_fee.transport_fee_collection
    if params[:student].present?
    @student = Student.find(params[:student])
    @batch=@student.batch
    @students=Student.find(:all,:joins=>"inner join transport_fees tf on tf.receiver_id=students.id and tf.receiver_type='Student'", :conditions => "tf.transport_fee_collection_id='#{@date.id}' and tf.is_active=1 and students.batch_id='#{@batch.id}'",:order=>"id ASC")
    @prev_student=@students.select{|student| student.id<@student.id}.last||@students.last
    @next_student=@students.select{|student| student.id>@student.id}.first||@students.first
    end
    category_id = FinanceTransactionCategory.find_by_name("Transport").id
    @transaction = FinanceTransaction.new
    unless params[:fees][:payment_mode].blank?
      @transaction.title = @transport_fee.transport_fee_collection.name
      @transaction.category_id = category_id
      unless params[:fees][:fine].blank?
        @transaction.amount = @transport_fee.bus_fare + params[:fees][:fine].to_f
        @transaction.fine_included = true
        @transaction.fine_amount = params[:fees][:fine]
      else
        @transaction.amount = @transport_fee.bus_fare
      end
      @transaction.payee = @transport_fee.receiver
      @transaction.finance = @transport_fee
      @transaction.transaction_date = Date.today
      @transaction.payment_mode = params[:fees][:payment_mode]
      @transaction.payment_note = params[:fees][:payment_note]
      if @transaction.save
        user_event = UserEvent.first(:conditions => ["user_id = ? AND event_id = ?",@transport_fee.receiver.user_id,@date.event.id])
        user_event.destroy if user_event.present?
#        @transport_fee.update_attributes(:transaction_id => @transaction.id)
        flash[:notice]="#{t('fee_paid')}"
        flash[:warn_notice]=nil
      end
    else
      flash[:notice]=nil
      flash[:warn_notice]="#{t('select_one_payment_mode')}"
    end

    render :update do |page|
      page.replace_html 'fees_details', :partial => 'fees_details'
    end
  end

  def transport_fee_collection_details
    @date=TransportFeeCollection.find(params[:date])
    @batch=Batch.find(params[:batch_id])
    @fine = params[:fees][:fine] if params[:fees].present?
    @students=Student.find(:all,:joins=>"inner join transport_fees tf on tf.receiver_id=students.id and tf.receiver_type='Student'", :conditions => "tf.transport_fee_collection_id='#{@date.id}' and tf.is_active=1 and students.batch_id='#{@batch.id}'",:order=>"id ASC")
    if params[:student].present?
      @student = Student.find(params[:student])
    else
      @student=@students.first
    end
    @prev_student=@students.select{|student| student.id<@student.id}.last||@students.last
    @next_student=@students.select{|student| student.id>@student.id}.first||@students.first
    @transport_fee = TransportFee.active.find_by_receiver_id_and_transport_fee_collection_id(@student.id, @date.id, :conditions => "receiver_type = 'Student'")
    @transport_fee_collection = @transport_fee.transport_fee_collection
    @transaction = FinanceTransaction.find(@transport_fee.transaction_id) unless @transport_fee.transaction_id.nil?
    flash.clear
    render :update do |page|
      page.replace_html "fees_detail", :partial => "fees_submission_form"
    end

  end

  #  def transport_fee_collection_details
  #    @collection_id = params[:collection_id]
  #    @transport_fee_collection= TransportFeeCollection.find_by_id(params[:collection_id])
  #    @transport_fee = TransportFee.find_all_by_transport_fee_collection_id(params[:collection_id])
  #    @user = TransportFee.find_by_transport_fee_collection_id_and_id(params[:collection_id], params[:id]) unless params[:id].nil?
  #    @user ||= @transport_fee_collection.transport_fees.first
  #    @next_user = @user.next_user unless @user.nil?
  #    @prev_user = @user.previous_user unless @user.nil?
  #    @transaction = FinanceTransaction.find_by_id(@user.transaction_id) unless @user.nil?
  #    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id) unless @user.nil?
  #    render :update do |page|
  #      page.replace_html 'transport_fee_collection_details', :partial => 'transport_fee_collection_details'
  #    end
  #  end

  def update_fine_ajax
    @collection_id = params[:fine][:transport_fee_collection]
    @transport_fee = TransportFee.find_all_by_transport_fee_collection_id(params[:fine][:transport_fee_collection])
    @user = TransportFee.find_by_transport_fee_collection_id_and_id(params[:fine][:transport_fee_collection], params[:fine][:_id]) unless params[:fine][:_id].nil?
    @user ||= @transport_fee.first
    @next_user = @user.next_user
    @prev_user = @user.previous_user
    @fine = (params[:fine][:fee])
    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id)
    @transaction = FinanceTransaction.find_by_id(@user.transaction_id)
    render :update do |page|
      page.replace_html 'transport_fee_collection_details', :partial => 'transport_fee_collection_details'
    end
  end

  def update_student_fine_ajax
    @collection_id = params[:fine][:transport_fee_collection]
    @transport_fee = TransportFee.find_by_transport_fee_collection_id_and_receiver_id_and_receiver_type(params[:fine][:transport_fee_collection], params[:fine][:_id], 'Student') unless params[:fine][:_id].nil?
    @transport_fee_collection= TransportFeeCollection.find_by_id(@transport_fee.transport_fee_collection_id)
    @transaction = FinanceTransaction.find_by_id(@transport_fee.transaction_id)
    render :update do |page|
      unless params[:fine][:fee].to_f < 0
        @fine = params[:fine][:fee]
        @student = Student.find(params[:fine][:_id])
        page.replace_html 'fee_submission', :partial => 'fees_submission_form', :with => @student
        page.replace_html 'flash-msg', :text => ""
      else
        @student = Student.find(params[:fine][:_id])
        page.replace_html 'fee_submission', :partial => 'fees_submission_form'
        page.replace_html 'flash-msg', :text => "<p class='flash-msg'>Fine amount cannot be negative</p>"
      end
    end
  end


  #  def employee_transport_fee_collection
  #    @transport_fee_collection =TransportFeeCollection.employee
  #  end
  #
  #  def employee_transport_fee_collection_details
  #    @collection_id = params[:collection_id]
  #    @transport_fee_collection= TransportFeeCollection.find_by_id(params[:collection_id])
  #    @transport_fee = TransportFee.find_all_by_transport_fee_collection_id(params[:collection_id])
  #    @user = TransportFee.find_by_transport_fee_collection_id_and_id(params[:collection_id], params[:id]) unless params[:id].nil?
  #    @user ||= @transport_fee_collection.transport_fees.first
  #    unless @user.nil?
  #      @next_user = @user.next_user
  #      @prev_user = @user.previous_user
  #      @transaction = FinanceTransaction.find_by_id(@user.transaction_id)
  #      @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id)
  #    end
  #    render :update do |page|
  #      page.replace_html 'transport_fee_collection_details', :partial => 'employee_transport_fee_collection_details'
  #    end
  #  end

  def update_employee_fine_ajax
    @collection_id = params[:fine][:transport_fee_collection]
    @transport_fee = TransportFee.active.find_all_by_transport_fee_collection_id(params[:fine][:transport_fee_collection])
    @user = TransportFee.active.find_by_transport_fee_collection_id_and_id(params[:fine][:transport_fee_collection], params[:fine][:_id]) unless params[:fine][:_id].nil?
    @user ||= @transport_fee.first
    @next_user = @user.next_user
    @prev_user = @user.previous_user
    @fine = (params[:fine][:fee])
    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id)
    @transaction = FinanceTransaction.find_by_id(@user.transaction_id)
    render :update do |page|
      page.replace_html 'transport_fee_collection_details', :partial => 'employee_transport_fee_collection_details'
    end
  end

  def update_employee_fine_ajax2
    @collection_id = params[:date]
    @transport_fee = TransportFee.active.find_by_transport_fee_collection_id_and_receiver_id_and_receiver_type(params[:date], params[:emp_id], 'Employee') unless params[:emp_id].nil?
    @transport_fee_collection= TransportFeeCollection.find_by_id(@transport_fee.transport_fee_collection_id)
    @transaction = FinanceTransaction.find_by_id(@transport_fee.transaction_id)
    render :update do |page|
      unless params[:fees][:fine].to_f < 0
        @fine = params[:fees][:fine].to_f
        @employee = Employee.find(params[:emp_id])
        page.replace_html 'fees_details', :partial => 'fees_details'
        page.replace_html 'flash-msg', :text => ""
      else
        @employee = Employee.find(params[:emp_id])
        page.replace_html 'fees_details', :partial => 'fees_details'
        page.replace_html 'flash-msg', :text => "<p class='flash-msg'>Fine amount cannot be negative</p>"
      end
    end
  end

  def defaulters_update_fee_collection_dates
    @transport_fee_collection=TransportFeeCollection.all(:joins=>"INNER JOIN transport_fees on transport_fees.transport_fee_collection_id =transport_fee_collections.id INNER JOIN students on transport_fees.receiver_id=students.id and transport_fees.receiver_type='Student' INNER JOIN batches on students.batch_id=batches.id", :conditions =>["batches.id=? and transport_fee_collections.is_deleted=? and transport_fees.transaction_id IS NULL and transport_fee_collections.due_date < '#{Date.today}' and transport_fees.bus_fare > ?",params[:batch_id],false,0.0], :group =>"transport_fee_collections.id")
    # @transport_fee_collection = TransportFeeCollection.find_all_by_batch_id(params[:batch_id])
    render :update do |page|
      page.replace_html 'fees_collection_dates', :partial => 'defaulters_transport_fee_collection_dates'
    end
  end

  def defaulters_transport_fee_collection_details
    @collection_id = params[:collection_id]
    @transport_fee =TransportFee.active.find(:all, :select => "distinct transport_fees.*", :joins => "INNER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'", :conditions => "transport_fees.transport_fee_collection_id='#{params[:collection_id]}' and  students.batch_id='#{params[:batch_id]}' and transport_fees.transaction_id is null").sort_by { |s| s.receiver.full_name.downcase unless s.receiver.nil? }

    # @transport_fee = TransportFee.active.find_all_by_transport_fee_collection_id(params[:collection_id], :conditions => 'transaction_id IS NULL')
    # @transport_fee.reject! { |x| x.receiver.nil? }
    #   @transaction = FinanceTransaction.find_by_id(@user.transaction_id) unless @user.nil?
    #  @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id) unless @user.nil?
    render :update do |page|
      page.replace_html 'fee_submission', :partial => 'students_list'
    end
  end

  def fees_submission_defaulter_student
    @fine=params[:fees][:fine] if params[:fees].present?
    @user = params[:id]
    @student = Student.find(params[:student])
    @date=TransportFeeCollection.find(params[:date])
    @transport_fee = TransportFee.active.find_by_receiver_id_and_transport_fee_collection_id(@student.id,@date.id, :conditions => "receiver_type = 'Student'")
    @transport_fee_collection = @transport_fee.transport_fee_collection
    @transaction = FinanceTransaction.find(@transport_fee.transaction_id) unless @transport_fee.transaction_id.nil?
    flash.clear
    render :update do |page|
      page.replace_html "fee_submission", :partial => "fees_details"
    end
  end

  def update_defaulters_fine_ajax
    @collection_id = params[:fine][:transport_fee_cofind_all_by_transport_fee_collection_idllection]
    @transport_fee = TransportFee.active.find_all_by_transport_fee_collection_id(params[:fine][:transport_fee_collection])
    @user = TransportFee.active.find_by_transport_fee_collection_id_and_id(params[:fine][:transport_fee_collection], params[:fine][:_id]) unless params[:fine][:_id].nil?
    @user ||= @transport_fee.first
    @next_user = @user.next_user unless @user.nil?
    @prev_user = @user.previous_user unless @user.nil?
    @fine = (params[:fine][:fee])
    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id)
    @transaction = FinanceTransaction.find_by_id(@user.transaction_id)
    render :update do |page|
      page.replace_html 'defaulters_transport_fee_collection_details', :partial => 'defaulters_transport_fee_collection_details'
    end
  end

  def employee_defaulters_transport_fee_collection
    @transport_fee_collection =TransportFeeCollection.employee
  end

  def employee_defaulters_transport_fee_collection_details
    @collection_id = params[:collection_id]
    @transport_fee_collection= TransportFeeCollection.find_by_id(params[:collection_id])
    @transport_fee = TransportFee.active.find_all_by_transport_fee_collection_id(params[:collection_id], :conditions => 'transaction_id IS NULL')
    @transport_fee.reject! { |x| x.receiver.nil? }
    @transaction = FinanceTransaction.find_by_id(@user.transaction_id) unless @user.nil?
    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id) unless @user.nil?
    render :update do |page|
      page.replace_html 'fee_submission', :partial => 'students_list'
    end
  end

  def update_employee_defaulters_fine_ajax
    @collection_id = params[:fine][:transport_fee_collection]
    @transport_fee = TransportFee.active.find_all_by_transport_fee_collection_id(params[:fine][:transport_fee_collection])
    @user = TransportFee.active.find_by_transport_fee_collection_id_and_id(params[:fine][:transport_fee_collection], params[:fine][:_id]) unless params[:fine][:_id].nil?
    @user ||= @transport_fee_collection.transport_fees.first(:conditions => ["transaction_id is null"])
    @next_user = @user.next_default_user unless @user.nil?
    @prev_user = @user.previous_default_user unless @user.nil?
    @transaction = FinanceTransaction.find_by_id(@user.transaction_id) unless @user.nil?
    @fine = (params[:fine][:fee])
    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id)
    render :update do |page|
      page.replace_html 'defaulters_transport_fee_collection_details', :partial => 'employee_defaulters_transport_fee_collection_details'
    end
  end


  def transport_fee_receipt_pdf
    @transaction = FinanceTransaction.find params[:id]
    @transport_fee = @transaction.finance
    @fee_collection = @transport_fee.transport_fee_collection
    @user = @transport_fee.receiver
    @bus_fare = @transaction.fine_included ? ((@transaction.amount.to_f) - (@transaction.fine_amount.to_f)) : @transaction.amount.to_f
    @currency = currency
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      response = @transaction.try(:payment).try(:gateway_response)
      @online_transaction_id = response.nil? ? nil : response[:transaction_id]
      @online_transaction_id ||= response.nil? ? nil : response[:x_trans_id]
      @online_transaction_id ||= response.nil? ? nil : response[:transaction_reference]
    end
    render :pdf => 'transport_fee_receipt', :layout => 'pdf'
  end

  def delete_fee_collection_date
    @transaction = TransportFee.active.find_by_transport_fee_collection_id(params[:id])
    unless @transaction.nil?
      fee_collection=TransportFeeCollection.find params[:id]
      event=fee_collection.event
      event.destroy
      fee_collection.destroy
      flash[:notice]="#{t('flash4')}"
    else
      @error_text=true
      render :update do |page|
        flash[:error]="#{t('flash5')}"
        page.redirect_to :action => 'transport_fee_collection_view'
      end
    end
  end

  def update_user_ajax
    if params[:user_type] == 'employee'
      #@transport_fee_collection = TransportFeeCollection.find(:all, :conditions=>'batch_id IS NULL').paginate(:page => params[:page],:per_page => 30)
      @transport_fee_collection = TransportFeeCollection.paginate(:select => "distinct transport_fee_collections.*", :joins => [:transport_fees], :conditions => "transport_fees.receiver_type='Employee' and is_deleted=false and transport_fees.is_active=true", :per_page => 20, :page => params[:page])
      @user_type = 'employee'
      render :update do |page|
        page.replace_html 'fee_collection_list', :partial => 'fee_collection_list'
        page.replace_html 'batch_list', :text => ''
      end
    elsif params[:user_type] == 'student'
      @user_type = 'student'
      @batches = Batch.active
      render :update do |page|
        page.replace_html 'batch_list', :partial => 'students_batch_list'
        page.replace_html 'fee_collection_list', :text => ''
      end
    else
      render :update do |page|
        page.replace_html 'batch_list', :text => ''
        page.replace_html 'fee_collection_list', :text => ''
      end
    end
  end

  def update_batch_list_ajax
    @transport_fee_collection = TransportFeeCollection.paginate(:all, :select => "distinct transport_fee_collections.*", :joins => "INNER JOIN `transport_fees` ON transport_fees.transport_fee_collection_id = transport_fee_collections.id INNER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'", :conditions => "students.batch_id= #{params[:batch_id]} and transport_fees.is_active=true", :per_page => 20, :page => params[:page])
    @user_type = 'student'
    render :update do |page|
      page.replace_html 'fee_collection_list', :partial => 'fee_collection_list'
    end
  end

  def transport_fees_report
    if date_format_check
      @start_date=@start_date.to_s
      @end_date=@end_date.to_s
      transport_id = FinanceTransactionCategory.find_by_name('Transport').id
      @fees = FinanceTransaction.find(:all, :order => 'created_at desc', :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@last_date}'and category_id ='#{transport_id}'"])
      # @collection = TransportFeeCollection.find(:all, :joins => "INNER JOIN transport_fees ON transport_fees.transport_fee_collection_id = transport_fee_collections.id INNER JOIN finance_transactions ON finance_transactions.finance_id = transport_fees.id and finance_transactions.finance_type = 'TransportFee' and finance_transactions.transaction_date >= '#{@start_date}' AND finance_transactions.transaction_date <= '#{@end_date}'and finance_transactions.category_id ='#{transport_id}'", :group => "transport_fee_collections.id")
      @student_collection = TransportFeeCollection.find(:all, :joins => "INNER JOIN transport_fees ON transport_fees.transport_fee_collection_id = transport_fee_collections.id INNER JOIN finance_transactions ON finance_transactions.finance_id = transport_fees.id and finance_transactions.finance_type = 'TransportFee' and finance_transactions.transaction_date >= '#{@start_date}' AND finance_transactions.transaction_date <= '#{@end_date}'and finance_transactions.category_id ='#{transport_id}' and transport_fees.receiver_type='Student'", :group => "transport_fee_collections.id")
      @employee_collection = TransportFeeCollection.find(:all, :joins => "INNER JOIN transport_fees ON transport_fees.transport_fee_collection_id = transport_fee_collections.id INNER JOIN finance_transactions ON finance_transactions.finance_id = transport_fees.id and finance_transactions.finance_type = 'TransportFee' and finance_transactions.transaction_date >= '#{@start_date}' AND finance_transactions.transaction_date <= '#{@end_date}'and finance_transactions.category_id ='#{transport_id}' and transport_fees.receiver_type='Employee'", :group => "transport_fee_collections.id")
      @employees = Employee.find(:all)
    end
  end

  def batch_transport_fees_report

    if date_format_check
      @start_date=@start_date.to_s
      @end_date=@end_date.to_s
      @fee_collection = TransportFeeCollection.find(params[:id])
      @batch = @fee_collection.batch
      transport_id = FinanceTransactionCategory.find_by_name('Transport').id
      @transaction =[]
      @fee_collection.finance_transaction.each { |f| @transaction<<f if (f.transaction_date.to_s >= @start_date and f.transaction_date.to_s <= @end_date) }
    end
  end

  def employee_transport_fees_report
    if date_format_check
      @start_date=@start_date.to_s
      @end_date=@end_date.to_s
      @fee_collection = TransportFeeCollection.find(params[:id])
      transport_id = FinanceTransactionCategory.find_by_name('Transport').id
      @transaction = @fee_collection.finance_transaction(:conditions => "transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'and category_id ='#{transport_id}'")
    end
  end

  def student_profile_fee_details
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      if ((PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.config_value("enabled_fees").include? "Transport Fee"))
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
        #        end
        @custom_gateway = CustomGateway.find(@active_gateway)
#        @custom_gateway.gateway_parameters[:config_fields].each_pair do|k,v|
#          instance_variable_set("@"+k,v)
#        end
      end
    end

    hostname = "#{request.protocol}#{request.host_with_port}"

    @student=Student.find(params[:id])
    @fee= TransportFee.find_by_transport_fee_collection_id_and_receiver_id(params[:id2], params[:id])
    @fee_collection = TransportFeeCollection.find(params[:id2])
    @amount = @fee.bus_fare
    @paid_fees = @fee.finance_transaction unless @fee.transaction_id.blank?

    if params[:create_transaction].present?
      gateway_response = Hash.new
      #      if @active_gateway == "Paypal"
      #        gateway_response = {
      #          :amount => params[:amt],
      #          :status => params[:st],
      #          :transaction_id => params[:tx]
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
      #
      #      elsif @active_gateway == "Webpay"
      #        if File.exists?("#{Rails.root}/vendor/plugins/fedena_pay/config/online_payment_url.yml")
      #          response_urls = YAML.load_file(File.join(Rails.root, "vendor/plugins/fedena_pay/config/", "online_payment_url.yml"))
      #        end
      #        txnref = params[:txnref] || params[:txnRef] || ""
      #        response_url = response_urls.nil? ? nil : eval(response_urls["webpay_response_url"].to_s)
      #        response_url ||= "https://stageserv.interswitchng.com/test_paydirect/api/v1/gettransaction.json"
      #        response_url += "?productid=#{@product_id.strip}"
      #        response_url += "&transactionreference=#{txnref}"
      #        response_url += "&amount=#{(('%.02f' % @amount).to_f * 100).to_i}"
      #        uri = URI.parse(response_url)
      #        http = Net::HTTP.new(uri.host, uri.port)
      #        http.use_ssl = true
      #        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      #        request = Net::HTTP::Get.new(uri.request_uri, {'Hash' => Digest::SHA512.hexdigest(@product_id.strip + txnref.to_s + @merchant_id.strip)})
      #        response = http.request(request)
      #        response_str = JSON.parse response.body
      #        gateway_response = {
      #          :split_accounts => response_str["SplitAccounts"],
      #          :merchant_reference => response_str["MerchantReference"],
      #          :response_code => response_str["ResponseCode"],
      #          :lead_bank_name => response_str["LeadBankName"],
      #          :lead_bank_cbn_code => response_str["LeadBankCbnCode"],
      #          :amount => response_str["Amount"].to_f/ 100,
      #          :card_number => response_str["CardNumber"],
      #          :response_description => response_str["ResponseDescription"],
      #          :transaction_date => response_str["TransactionDate"],
      #          :retrieval_reference_number => response_str["RetrievalReferenceNumber"],
      #          :payment_reference => response_str["PaymentReference"]
      #        }
      #
      #      end
      if @custom_gateway.present?
        @custom_gateway.gateway_parameters[:response_parameters].each_pair do|k,v|
          unless k.to_s == "success_code"
            gateway_response[k.to_sym] = params[v.to_sym]
          end
        end
      end
      @gateway_status = false
      #      if @active_gateway == "Paypal"
      #        @gateway_status = true if params[:st] == "Completed"
      #      elsif @active_gateway == "Authorize.net"
      #        @gateway_status = true if gateway_response[:x_response_reason_code] == "1"
      #      elsif @active_gateway == "Webpay"
      #        @gateway_status = true if gateway_response[:response_code] == "00"
      #      end
      if @custom_gateway.present?
        success_code = @custom_gateway.gateway_parameters[:response_parameters][:success_code]
        @gateway_status = true if gateway_response[:transaction_status] == success_code
      end
      payment = Payment.new(:payee => @student, :payment => @fee, :gateway_response => gateway_response, :status => @gateway_status, :amount => gateway_response[:amount].to_f, :gateway => @active_gateway)
      payment.fee_collection = @fee_collection
      if payment.save and @fee.transaction_id.nil?
        #        amount_from_gateway = 0
        #        if @active_gateway == "Paypal"
        #          amount_from_gateway = params[:amt]
        #        elsif @active_gateway == "Authorize.net"
        #          amount_from_gateway = params[:x_amount]
        #        elsif @active_gateway == "Webpay"
        #          amount_from_gateway = gateway_response[:amount]
        #        end
        amount_from_gateway = gateway_response[:amount]
        if amount_from_gateway.to_f > 0.0 and payment.status
          transaction = FinanceTransaction.new
          transaction.title = @fee.transport_fee_collection.name
          transaction.category_id = FinanceTransactionCategory.find_by_name('Transport').id
          transaction.finance = @fee
          transaction.amount = amount_from_gateway.to_f
          transaction.transaction_date = Date.today
          transaction.payment_mode = "Online payment"
          transaction.payee = @fee.receiver

          if transaction.save
#            @fee.update_attributes(:transaction_id => transaction.id)
            payment.update_attributes(:finance_transaction_id => transaction.id)
            #            online_transaction_id = payment.gateway_response[:transaction_id]
            #            online_transaction_id ||= payment.gateway_response[:x_trans_id]
            #            online_transaction_id ||= payment.gateway_response[:payment_reference]
            online_transaction_id = payment.gateway_response[:transaction_reference]
            @paid_fees=@fee.finance_transaction unless @fee.transaction_id.blank?
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
                Delayed::Job.enqueue(OnlinePayment::PaymentMail.new(payment.fee_collection.name, user.email, user.full_name, @custom_gateway.name, payment.gateway_response[:amount], online_transaction_id, payment.gateway_response, user.school_details, hostname))
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
        flash[:notice] = "#{t('flash_payed')}"
      end
      redirect_to :controller => 'transport_fee', :action => 'student_profile_fee_details', :id => params[:id], :id2 => params[:id2]
    end
  end

  def delete_transport_transaction
    @transport_fee=TransportFee.find(params[:transaction_id])
    @financetransaction=@transport_fee.finance_transaction
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      payment = @financetransaction.payment
      unless payment.nil?
        status = Payment.payment_status_mapping[:reverted]
        payment.update_attributes(:status_description => status)
        payment.save
      end
    end
    if @financetransaction
      if @financetransaction.destroy
        @transport_fee.reload
        UserEvent.create(:event_id=>@transport_fee.transport_fee_collection.event.id,:user_id=>@transport_fee.receiver.user_id)
      end

    end
    if @transport_fee.receiver_type=="Employee"
      redirect_to :action => 'fees_submission_employee', :id => params[:id], :date => params[:date]
    else
      @student=@transport_fee.receiver
      @transport_fee_collection=@transport_fee.transport_fee_collection
      render :update do |page|
        page.replace_html "fees_details" ,:partial=>"fees_details"
      end
#      render :js=> "new Ajax.Request('/transport_fee/transport_fee_collection_details', {method: 'get',parameters: {student: #{@transport_fee.receiver_id},batch_id:#{@transport_fee.receiver.batch_id},date:#{@transport_fee.transport_fee_collection_id}}});"
    end
    #    render :update do |page|
    #          page.replace_html 'payments_details',:text => ''
    #        end
  end


  def receiver_wise_collection_new
    @transport_fee_collection = TransportFeeCollection.new
    render :update do |page|
      page.replace_html "collection-details", :partial => 'receiver_wise_collection_new'
    end
    # @batches =Batch.find(:all,:select=>"distinct batches.*",:joins=>"INNER JOIN students on students.batch_id=batches.id INNER JOIN transports on students.id=transports.receiver_id and transports.receiver_type='Student'",:conditions=>"batches.is_active=1 and batches.is_deleted=0")
  end


  def collection_creation_and_assign
    @batches =Batch.find(:all, :select => "distinct batches.*", :joins => "INNER JOIN students on students.batch_id=batches.id INNER JOIN transports on students.id=transports.receiver_id and transports.receiver_type='Student'", :conditions => "batches.is_active=1 and batches.is_deleted=0")
    @dates=[]
  end

  def search_student
    students= Student.active.find(:all, :joins => [{:transport => :route}], :conditions => ["(admission_no LIKE ? OR first_name LIKE ?)", "%#{params[:query]}%", "%#{params[:query]}%"]).uniq
    employees= Employee.find(:all, :joins => [{:transport => :route}], :conditions => ["(employee_number LIKE ? OR first_name LIKE ?)", "%#{params[:query]}%", "%#{params[:query]}%"]).uniq
    students_suggestions=students.collect { |s| s.full_name.length+s.admission_no.length > 20 ? s.full_name[0..(18-s.admission_no.length)]+".. "+"(#{s.admission_no})"+" - "+s.transport.bus_fare.to_s+"(#{s.transport.route.destination})" : s.full_name+"(#{s.admission_no})"+" - "+s.transport.bus_fare.to_s+"(#{s.transport.route.destination})" }
    employees_suggestions=employees.collect { |e| e.full_name.length+e.employee_number.length > 20 ? e.full_name[0..(18-e.employee_number.length)]+".. "+"(#{e.employee_number})"+" - "+e.transport.bus_fare.to_s+"(#{e.transport.route.destination})" : e.full_name+"(#{e.employee_number})"+" - "+e.transport.bus_fare.to_s+"(#{e.transport.route.destination})" }
    suggestions=students_suggestions+employees_suggestions
    receivers=students.map { |st| "{'receiver': 'Student','id': #{st.id}, 'bus_fare' : #{st.transport.bus_fare},'user_id':#{st.user_id}}" }+employees.map { |emp| "{'receiver': 'Employee','id': #{emp.id}, 'bus_fare' : #{emp.transport.bus_fare},'user_id':#{emp.user_id}}" }
    if receivers.present?
      render :json => {'query' => params["query"], 'suggestions' => suggestions, 'data' => receivers}
    else
      render :json => {'query' => params["query"], 'suggestions' => ["#{t('no_users')}"], 'data' => ["{'receiver': #{false}}"]}
    end
  end

  def receiver_wise_fee_collection_creation

    error=false
    TransportFeeCollection.transaction do
      if params[:receiver].present?
        params[:receiver].each do |key, values|

          recipients=[]
          fee_collection_attributes=params[:transport_fee_collection].merge!(:transport_fees_attributes => params[:receiver][key])
          @transport_fee_collection=TransportFeeCollection.new(fee_collection_attributes)
          if @transport_fee_collection.save
            event=Event.new(:title => "#{t('transport_fee_text')}", :description => "#{t('fee_name')}: #{@transport_fee_collection.name}", :start_date => @transport_fee_collection.start_date.to_s, :end_date => @transport_fee_collection.end_date.to_s, :is_due => true, :origin => @transport_fee_collection, :user_events_attributes => params["event"][key])
            error=true unless event.save
            params["event"][key].each { |k, v| recipients<<v["user_id"] }
            send_reminder(@transport_fee_collection, recipients)
          else
            error=true
          end
        end
      else
        error=true
        @transport_fee_collection=TransportFeeCollection.new(params[:transport_fee_collection])
      end

      if error

        render :update do |page|
          page.replace_html "collection-details", :partial => 'receiver_wise_collection_new'
        end
        raise ActiveRecord::Rollback

      else
        flash[:notice]="#{t('collection_date_has_been_created')}"
        render :update do |page|
          page.redirect_to :action => 'collection_creation_and_assign'
        end
      end

    end
  end

  def allocate_or_deallocate_fee_collection
    @recepient=params[:recepient]
    if @recepient=='employees'
      receiver_type='Employee'
      @employee_departments=EmployeeDepartment.active

    else
      receiver_type='Student'
      @batches = Batch.active
    end
    if request.post?
      error=false
      TransportFee.transaction do
        params[:fees_list][:collection_ids].present? ? colln_ids= params[:fees_list][:collection_ids] : colln_ids = [0]
        receiver=receiver_type.constantize.find(params[:fees_list][:receiver_id])
        # bus_fare=receiver.transport.bus_fare
        TransportFee.update_all("is_active=false", ["receiver_id='#{receiver.id}' and receiver_type='#{receiver_type}' and transport_fee_collection_id not in (?)", colln_ids])
        TransportFee.update_all(["is_active=true"], ["receiver_id='#{receiver.id}' and receiver_type='#{receiver_type}' and transport_fee_collection_id in (?)", colln_ids])
        receiver.send(:attributes=, params[:new_collection_ids])
        receiver.save(false)
        user_events=UserEvent.create(params[:user_events].values) if params[:user_events].present?

        if (error)
          render :update do |page|
            page.replace_html 'flash-div', :text => "<div id='error-box'><ul><li>#{t('fees_text')} #{t('transport_fee.allocation')} #{t('failed')}</li></ul></div>"
          end
          raise ActiveRecord::Rollback
        else
          render :update do |page|
            if receiver_type=='Student'
              page.replace_html 'flash-div', :text => "<p class='flash-msg'>#{t('fee_collections_are_updated_to_the_student_successfully')} </p>"
            else
              page.replace_html 'flash-div', :text => "<p class='flash-msg'>#{t('transport_fee.fee_collections_are_updated_to_the_employee_successfully')} </p>"
            end
          end
        end
      end
    end
  end

  def list_students_by_batch
    @receivers = Student.find(:all, :select => 'distinct students.*', :joins => [:transport_fees => :transport_fee_collection], :conditions => "students.batch_id='#{params[:batch_id]}' and transport_fees.transaction_id is null and transport_fee_collections.is_deleted=false", :order => 'first_name ASC')
    unless @receivers.blank?
      @receiver = @receivers.first
      # @bus_fare=@receiver.transport.bus_fare.to_f
      @fee_collection_dates=TransportFeeCollection.find(:all, :select => "distinct transport_fee_collections.*,transport_fees.is_active as assigned", :joins => "INNER JOIN `transport_fees` ON transport_fees.transport_fee_collection_id = transport_fee_collections.id", :conditions => "transport_fees.receiver_id='#{@receiver.id}' and transport_fees.receiver_type='Student' and transport_fee_collections.is_deleted=false and transport_fees.transaction_id is NULL")
      # TransportFeeCollection.find(:all,:select=>"transport_fee_collections.*,IF(transport_fees.receiver_id='#{@student.id}',true,false) as assigned",:joins=>"LEFT OUTER JOIN `transport_fees` ON transport_fees.transport_fee_collection_id = transport_fee_collections.id LEFT OUTER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'",:conditions=>"students.batch_id='#{params[:batch_id]}'")
    end
    render :partial => 'receivers_list'
  end

  def list_employees_by_department
    @receivers = Employee.find(:all, :select => 'distinct employees.*', :joins => [:transport_fees => :transport_fee_collection], :conditions => "employees.employee_department_id='#{params[:department_id]}' and transport_fees.transaction_id is null and transport_fee_collections.is_deleted=false", :order => 'first_name ASC')
    unless @receivers.blank?
      @receiver = @receivers.first
      # @bus_fare=@receiver.transport.bus_fare.to_f
      @fee_collection_dates=TransportFeeCollection.find(:all, :select => "distinct transport_fee_collections.*,transport_fees.is_active as assigned", :joins => "INNER JOIN `transport_fees` ON transport_fees.transport_fee_collection_id = transport_fee_collections.id", :conditions => "transport_fees.receiver_id='#{@receiver.id}' and transport_fees.receiver_type='Employee' and transport_fee_collections.is_deleted=false and transport_fees.transaction_id is NULL")
      # TransportFeeCollection.find(:all,:select=>"transport_fee_collections.*,IF(transport_fees.receiver_id='#{@student.id}',true,false) as assigned",:joins=>"LEFT OUTER JOIN `transport_fees` ON transport_fees.transport_fee_collection_id = transport_fee_collections.id LEFT OUTER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'",:conditions=>"students.batch_id='#{params[:batch_id]}'")
    end
    render :partial => 'receivers_list'
  end


  def list_fees_for_student
    @receiver = Student.find_by_id(params[:receiver])
    @fee_collection_dates=TransportFeeCollection.find(:all, :select => "distinct transport_fee_collections.*,transport_fees.is_active as assigned", :joins => "INNER JOIN `transport_fees` ON transport_fees.transport_fee_collection_id = transport_fee_collections.id", :conditions => "transport_fees.receiver_id='#{@receiver.id}' and transport_fees.receiver_type='Student' and transport_fee_collections.is_deleted=false and transport_fees.transaction_id is NULL")
    render :update do |page|
      page.replace_html 'fees_list', :partial => 'fees_list'
    end
  end

  def list_fees_for_employee
    @receiver = Employee.find_by_id(params[:receiver])
    @fee_collection_dates=TransportFeeCollection.find(:all, :select => "distinct transport_fee_collections.*,transport_fees.is_active as assigned", :joins => "INNER JOIN `transport_fees` ON transport_fees.transport_fee_collection_id = transport_fee_collections.id", :conditions => "transport_fees.receiver_id='#{@receiver.id}' and transport_fees.receiver_type='Employee' and transport_fee_collections.is_deleted=false and transport_fees.transaction_id is NULL")
    render :update do |page|
      page.replace_html 'fees_list', :partial => 'fees_list'
    end
  end

  def list_students_for_collection
    @collection=TransportFeeCollection.find(params[:date_id], :include => :transport_fees)
    student_ids=@collection.transport_fees.all(:conditions => {:receiver_type => 'Student'}).collect(&:receiver_id)
    student_ids=student_ids.join(',')

    students= Student.active.find(:all, :joins => [{:transport => :route}], :conditions => ["(admission_no LIKE ? OR first_name LIKE ?) and students.id not in (#{student_ids}) and batch_id='#{params[:batch_id]}' ", "%#{params[:query]}%", "%#{params[:query]}%"]).uniq
    suggestions=students.collect { |s| s.full_name.length+s.admission_no.length > 20 ? s.full_name[0..(18-s.admission_no.length)]+".. "+"(#{s.admission_no})"+" - "+s.transport.bus_fare.to_s+"(#{s.transport.route.destination})" : s.full_name+"(#{s.admission_no})"+" - "+s.transport.bus_fare.to_s+"(#{s.transport.route.destination})" }
    receivers=students.map { |st| "{'receiver': 'Student','id': #{st.id}, 'bus_fare' : #{st.transport.bus_fare},'user_id':#{st.user_id}}" }
    if receivers.present?
      render :json => {'query' => params["query"], 'suggestions' => suggestions, 'data' => receivers}
    else
      render :json => {'query' => params["query"], 'suggestions' => ["#{t('no_users')}"], 'data' => ["{'receiver': #{false}}"]}
    end
  end

  def render_collection_assign_form
    @transport_fee_collection=TransportFeeCollection.find(params[:id])
    render :update do |page|
      page.replace_html 'students_selection', :partial => 'students_selection'
    end
  end


  def list_fee_collections_for_employees
    @receiver=Employee.find(params[:receiver_id])
    params[:collection_ids].present? ? colln_ids=params[:collection_ids] : colln_ids=[0]
    fee_collections= TransportFeeCollection.find(:all, :include => :event, :select => "distinct transport_fee_collections.*", :joins => :transport_fees, :conditions => ["(name LIKE ?) and transport_fee_collections.id not in (?) and  (transport_fee_collections.batch_id is null)", "%#{params[:query]}%", colln_ids])
    data_values=fee_collections.map { |f| "{'id':#{f.id}, 'event_id' : #{f.event.id}}" }
    render :json => {'query' => params["query"], 'suggestions' => fee_collections.collect { |fc| fc.name.length+fc.start_date.to_s.length > 20 ? fc.name[0..(18-fc.start_date.to_s.length)]+".. "+" - "+fc.start_date.to_s : fc.name+" - "+fc.start_date.to_s }, 'data' => data_values}
  end

  def choose_collection_and_assign
    @batches =Batch.find(:all, :select => "distinct batches.*", :joins => "INNER JOIN students on students.batch_id=batches.id INNER JOIN transports on students.id=transports.receiver_id and transports.receiver_type='Student'", :conditions => "batches.is_active=1 and batches.is_deleted=0")
    @dates=[]
    render :update do |page|
      page.replace_html "collection-details", :partial => 'choose_collection_and_assign'
    end
  end


  def update_fees_collections
    @dates=TransportFeeCollection.all(:select=>"DISTINCT transport_fee_collections.*",:joins=>"inner join transport_fees tf on tf.transport_fee_collection_id=transport_fee_collections.id INNER JOIN students on students.id=tf.receiver_id and tf.receiver_type='Student'",:conditions=>["students.batch_id=?",params[:batch_id]])
    render :update do |page|
      page.replace_html 'fees_collection_dates', :partial => 'fees_collection_dates'
    end
  end

  def collection_assign_students
    @transport_fee_collection=TransportFeeCollection.find(params[:transport_fee_collection][:id])
    event=@transport_fee_collection.event
    @transport_fee_collection.update_attributes(:transport_fees_attributes => params[:receiver][:Student].values)
    recipients=[]
    if (params[:event].present? and params[:event][:Student].present?)
      params[:event][:Student].each { |k, v| recipients<<v["user_id"] }
      send_reminder(@transport_fee_collection, recipients)
      user_events=event.user_events.create(params[:event][:Student].values) if event
    end
    flash[:notice]="#{t('collection_date_has_been_created')}"
    redirect_to :action => 'collection_creation_and_assign'
  end

  def show_employee_departments

    @employee_departments=EmployeeDepartment.active.sort_by { |e| e.name.downcase }

    render :update do |page|
      page.replace_html 'batch_or_department', :partial => 'departments'
    end

  end

  def show_student_batches
    @batches = Batch.active

    render :update do |page|
      page.replace_html 'batch_or_department', :partial => 'batches'
    end
  end

  def pay_batch_wise
    @batches=Batch.active.all(:include => :course)
    @transport_fee_collections = []
  end

end

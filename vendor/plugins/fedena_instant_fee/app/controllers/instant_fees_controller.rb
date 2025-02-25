class InstantFeesController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  before_filter :set_precision
  include LinkPrivilege
  helper_method('link_to','link_to_remote','link_present')
  def index
  end

  def manage_fees
    @instant_fee_categories = InstantFeeCategory.all(:conditions => {:is_deleted => false})
  end

  def new_category
    @new_instant_category = InstantFeeCategory.new
    respond_to do |format|
      format.js { render :action => 'new_category' }
    end
  end

  def create_category
    @new_instant_category = InstantFeeCategory.new(params[:instant_fee_category])
    if @new_instant_category.save
      @instant_fee_categories = InstantFeeCategory.all(:conditions => {:is_deleted => false})
    else
      @error = true
    end
    respond_to do |format|
      format.js { render :action => 'create_category' }
    end
  end

  def edit_category
    @instant_category = InstantFeeCategory.find(params[:id])
    respond_to do |format|
      format.js { render :action => 'edit_category' }
    end
  end

  def update_category
    @instant_category = InstantFeeCategory.find(params[:id])
    if @instant_category.update_attributes(params[:instant_fee_category])
      @instant_fee_categories = InstantFeeCategory.all(:conditions => {:is_deleted => false})
    else
      @error = true
    end
    respond_to do |format|
      format.js { render :action => 'update_category' }
    end
  end

  def delete_category
    @instant_category = InstantFeeCategory.find(params[:id])
    @instant_category.update_attributes(:is_deleted => true)
    @instant_category.instant_fee_particulars.each do |particular|
      particular.update_attributes(:is_deleted => true)
    end
    @instant_fee_categories = InstantFeeCategory.all(:conditions => {:is_deleted => false})
    respond_to do |format|
      format.js { render :action => 'delete_category' }
    end
  end


  def new_particular
    @new_instant_particular = InstantFeeParticular.new
    @instant_fee_categories = InstantFeeCategory.all(:conditions => {:is_deleted => false})
    respond_to do |format|
      format.js { render :action => 'new_particular' }
    end
  end

  def new_category_particular
    @instant_category = InstantFeeCategory.find(params[:id],:conditions => {:is_deleted => false})
    @new_instant_particular = @instant_category.instant_fee_particulars.new
    respond_to do |format|
      format.js {render :action =>'new_category_particular'}
    end
  end

  def create_particular
    @instant_category = InstantFeeCategory.find(params[:instant_fee_particular][:instant_fee_category_id])
    @new_instant_particular = @instant_category.instant_fee_particulars.new(params[:instant_fee_particular])
    if @new_instant_particular.save
      @instant_fee_particulars = @instant_category.instant_fee_particulars.all(:conditions=> {:is_deleted => false})
    else
      @error = true
    end
    respond_to do |format|
      format.js { render :action => 'create_particular' }
    end
  end

  def create_category_particular
    @instant_category = InstantFeeCategory.find(params[:id],:conditions => {:is_deleted => false})
    @new_instant_particular = @instant_category.instant_fee_particulars.new(params[:instant_fee_particular])
    if @new_instant_particular.save
      @instant_fee_particulars = @instant_category.instant_fee_particulars.all(:conditions=> {:is_deleted=>false})
    else
      @error = true
    end
    respond_to do |format|
      format.js { render :action => 'create_particular' }
    end
  end

  def edit_particular
    @instant_particular = InstantFeeParticular.find(params[:id])
    @instant_fee_categories = InstantFeeCategory.all(:conditions => {:is_deleted => false})
    respond_to do |format|
      format.js { render :action => 'edit_particular' }
    end
  end

  def update_particular
    @instant_category = InstantFeeCategory.find(params[:instant_fee_particular][:instant_fee_category_id])
    @instant_particular = InstantFeeParticular.find(params[:id])
    if @instant_particular.update_attributes(params[:instant_fee_particular])
      @instant_fee_particulars = @instant_category.instant_fee_particulars.all(:conditions=> {:is_deleted=>false})
    else
      @error = true
    end
    respond_to do |format|
      format.js { render :action => 'update_particular' }
    end
  end

  def delete_particular
    @instant_particular = InstantFeeParticular.find(params[:id])
    @instant_category = @instant_particular.instant_fee_category
    @instant_particular.update_attributes(:is_deleted => true)
    @instant_fee_particulars = @instant_category.instant_fee_particulars.all(:conditions=> {:is_deleted=>false})
    respond_to do |format|
      format.js { render :action => 'delete_particular' }
    end
  end

  def list_particulars
    @instant_fee_category = InstantFeeCategory.find(params[:id])
    @instant_fee_particulars = @instant_fee_category.instant_fee_particulars.all(:conditions=> {:is_deleted => false})
  end

  def new_instant_fees

  end

  def tsearch_logic # transport search fees structure
    @instant_fee_categories = InstantFeeCategory.all(:conditions => {:is_deleted => false})
    @option = params[:option]
    if params[:option] == "student"
      query = params[:query]
      unless query.length <3
        @students_result = Student.first_name_or_last_name_or_admission_no_begins_with query
      else
        @students_result = Student.admission_no_begins_with query
      end if query.present?
    elsif params[:option] == "employee"
      query = params[:query]
      unless query.length <3
        @employee_result = Employee.first_name_or_last_name_or_employee_number_begins_with query
      else
        @employee_result = Employee.employee_number_begins_with query
      end if query.present?
    end
    render :layout => false
  end

  def category_type
    if params[:employee_id].present?
      @employee_id = params[:employee_id]
    elsif params[:student_id].present?
      @student_id = params[:student_id]
    end
    @instant_fee_categories = InstantFeeCategory.all(:conditions => {:is_deleted => false})
    render :update do |page|
      page.replace_html 'partial-content',:text => ''
      page.replace_html 'select-category-type',:partial => 'select_category_type_for_user'
    end
  end

  def handle_category
    unless params[:employee_id].nil?
      @employee_id = params[:employee_id]
      @paid_fees=FinanceTransaction.find_all_by_payee_id_and_title(@employee_id,"Instant Fee")
    else
      @student_id = params[:student_id]
      @paid_fees=FinanceTransaction.find_all_by_payee_id_and_title(@student_id,"Instant Fee")
    end
    p "------------"
    p  "#{t('custom')}"
    p params[:category_id]
    p "---------------"
    if params[:category_id] == "#{t('custom')}"
      render :update do |page|
        page.replace_html 'fee_window',:partial => 'make_fee_from_custom_category'
      end
    else
      unless params[:category_id] ==""
        @instant_category = InstantFeeCategory.find(params[:category_id])
        @instant_fee_particulars = @instant_category.instant_fee_particulars.all(:conditions=> {:is_deleted=>false})
        render :update do |page|
          page.replace_html 'enter_custom_category',:text => ''
          page.replace_html 'fee_window',:partial => 'make_fee'
        end
      else
        render :update do |page|
          page.replace_html 'enter_custom_category',:text => ''
          page.replace_html 'fee_window',:text => ''
        end
      end

    end
  end

  def handle_category_for_guest
    if params[:category_id] == "Custom"
      render :update do |page|
        page.replace_html 'fee_window',:partial => 'make_fee_from_custom_category_for_guest'
      end
    else
      unless params[:category_id] ==""
        @instant_category = InstantFeeCategory.find(params[:category_id])
        @instant_fee_particulars = @instant_category.instant_fee_particulars.all(:conditions=> {:is_deleted=>false})
        render :update do |page|
          page.replace_html 'enter_custom_category',:text => ''
          page.replace_html 'fee_window',:partial => 'make_fee_for_guest'
        end
      else
        render :update do |page|
          page.replace_html 'enter_custom_category',:text => ''
          page.replace_html 'fee_window',:text => ''
        end
      end
    end
  end

  def select_payment_mode
    if  params[:payment_mode]=="#{t('others')}"
      render :update do |page|
        page.replace_html "payment_mode", :partial => "select_payment_mode"
      end
    else
      render :update do |page|
        page.replace_html "payment_mode", :text=>""
      end
    end
  end

  def create_instant_fee
    @instant_fee = InstantFee.new
    unless params[:custom_category_name].blank?
      @instant_fee.custom_category = params[:custom_category_name]
      @instant_fee.custom_description=params[:custom_category_description]
      unless params[:guest_payee].nil?
        @instant_fee.guest_payee = params[:guest_payee]
      else
        unless params[:student_id].nil?
          @student = Student.find(params[:student_id])
          @instant_fee.payee = @student
        end
        unless params[:employee_id].nil?
          @employee = Employee.find(params[:employee_id])
          @instant_fee.payee = @employee
        end
      end
    else
      @instant_fee.instant_fee_category_id = params[:category_id]
      unless params[:guest_payee].nil?
        @instant_fee.guest_payee = params[:guest_payee]
      else
        unless params[:student_id].blank?
          @student = Student.find(params[:student_id])
          @instant_fee.payee = @student
        end
        unless params[:employee_id].blank?
          @employee = Employee.find(params[:employee_id])
          @instant_fee.payee = @employee
        end
      end
    end
    unless params[:fees][:payment_mode].blank?
      name=params[:name].reject{ |c| c.empty? } unless params[:name].nil?
      particular_ids=params[:particular_ids].reject{ |c| c.empty? } unless params[:particular_ids].nil?
      ActiveRecord::Base.transaction do
        @instant_fee.amount = params[:total_fees]
        @instant_fee.pay_date = Time.now
        if @instant_fee.save
          i = 0
          @amounts = params[:amount]
          @discounts = params[:discount]
          @total_fees = params[:total]
          if particular_ids.nil? or particular_ids.empty?
            @flag=1
          else
            particular_ids.each do|particular|
              @instant_fee_details = @instant_fee.instant_fee_details.new
              @instant_fee_details.instant_fee_particular_id = particular
              @instant_fee_details.amount = @amounts[i]
              @instant_fee_details.discount = @discounts[i]
              @instant_fee_details.net_amount = @total_fees[i]
              @instant_fee_details.save
              i = i + 1
              @flag=0
            end
          end
          if name.nil? or name.empty?
            if @flag==1
              @error=true
            end
          else
            @custom_particulars = name
            @custom_particulars.each do |custom_particular|
              @instant_fee_details = @instant_fee.instant_fee_details.new
              @instant_fee_details.custom_particular = custom_particular
              @instant_fee_details.amount = @amounts[i]
              @instant_fee_details.discount = @discounts[i]
              @instant_fee_details.net_amount = @total_fees[i]
              @instant_fee_details.save
              i = i + 1
            end
          end
          unless @error
            category_type = FinanceTransactionCategory.find_by_name("InstantFee")
            @transaction = FinanceTransaction.new
            @transaction.title = "Instant Fee"
            @transaction.description = category_type.description
            @transaction.category_id = category_type.id
            @transaction.finance_fees_id = @instant_fee.id
            @transaction.amount = @instant_fee.amount
            @transaction.payee = @instant_fee.payee
            @transaction.finance = @instant_fee
            @transaction.transaction_date = Date.today
            @transaction.payment_mode = params[:fees][:payment_mode]
            @transaction.payment_note = params[:fees][:payment_note]
            @transaction.save
            flash[:notice] = t('instant_fee_payed')
            redirect_to :action => "instant_fee_created_detail",:id => @instant_fee.id
          end
        else
          @error=true
        end
        if @error==true
          flash[:warn_notice] = "Check the fields before paying"
          redirect_to :action => 'new_instant_fees'
          raise ActiveRecord::Rollback
        end
      end
    else
      flash[:warn_notice] = "Select one payment mode before paying the fees"
      redirect_to :action => 'new_instant_fees'
    end
  end

  def report
    if date_format_check
      @instant_fee_transaction_type = FinanceTransactionCategory.find_by_name("InstantFee")
      @instant_fee_transactions = FinanceTransaction.find(:all,:conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}' and category_id='#{@instant_fee_transaction_type.id}'"])
    end
  end

  def instant_fee_created_detail
    @instant_fee = InstantFee.find(params[:id])
    @instant_fee_details = @instant_fee.instant_fee_details.all
  end

  def print_reciept
    @instant_fee = InstantFee.find(params[:id])
    @instant_fee_details = @instant_fee.instant_fee_details.all
    render :pdf =>'instant_fee_reciept', :show_as_html=>params[:d].present?
  end

  def report_detail
    if date_format_check
      @instant_fee = InstantFee.find(params[:id])
      @instant_fee_details = @instant_fee.instant_fee_details.all
    end
  end
  def delete_transaction_for_instant_fee
    @financetransaction=FinanceTransaction.find(params[:id])
    if @financetransaction
     @financetransaction.destroy
    end
    #@category=InstantFeeCategory.find(params[:category_id])
    @category=params[:category_id]
    #@category=nil if params[:category_id]=='Custom'
    
    unless @category=='Custom'
      @transactions=FinanceTransaction.paginate(:per_page=>10,:page=>params[:page],:order=>'created_at desc',:joins=>"INNER JOIN instant_fees ON instant_fees.id=finance_id LEFT OUTER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id",:conditions=>['finance_type=? AND instant_fees.instant_fee_category_id=?',"InstantFee",@category])

    else
      @transactions=FinanceTransaction.paginate(:per_page=>10,:page=>params[:page],:order=>'created_at desc',:joins=>"INNER JOIN instant_fees ON instant_fees.id=finance_id LEFT OUTER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id",:conditions=>"finance_type='InstantFee' AND instant_fees.instant_fee_category_id is NULL")
    end
    render :update do |page|
      page.replace_html 'show_transactions',:partial => 'show_transactions'
    end
  end
  def show_instant_fee_transactions
    @instant_fee_categories = InstantFeeCategory.all(:conditions => {:is_deleted => false})
    #@transactions=FinanceTransaction.find(:all,:order => 'created_at desc',:conditions=>['finance_type=?',"InstantFee"]).paginate( :page => params[:page], :per_page => 20)
  end
  def list_instant_fee_transactions
    @category=params[:category_id]
    #@category=nil if params[:category_id]=='Custom'
    @page=params[:page]
    #@transactions= FinanceTransaction.paginate(:per_page=>10,:page=>params[:page],:conditions=>{:finance_id=>InstantFeeCategory.find(params[:category_id]).instant_fees.collect(&:id),:finance_type=>"InstantFee"})
    unless @category=='Custom'
      @transactions=FinanceTransaction.paginate(:per_page=>10,:page=>params[:page],:order=>'created_at desc',:joins=>"INNER JOIN instant_fees ON instant_fees.id=finance_id LEFT OUTER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id",:conditions=>['finance_type=? AND instant_fees.instant_fee_category_id=?',"InstantFee",@category])

    else
      @transactions=FinanceTransaction.paginate(:per_page=>10,:page=>params[:page],:order=>'created_at desc',:joins=>"INNER JOIN instant_fees ON instant_fees.id=finance_id LEFT OUTER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id",:conditions=>"finance_type='InstantFee' AND instant_fees.instant_fee_category_id is NULL")
    end
    render :update do |page|
      page.replace_html 'show_transactions',:partial => 'show_transactions'
    end
  end
  def instant_fee_transaction_filter_by_date
    @category=params[:category_id]
    #@category=nil if params[:category_id]=='Custom'
    @start_date=params[:s_date]
    @end_date=params[:e_date]
    unless @category=='Custom'
      @transactions=FinanceTransaction.paginate(:per_page=>10,:page=>params[:page],:order=>'created_at desc',:joins=>"INNER JOIN instant_fees ON instant_fees.id=finance_id INNER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id",:conditions=>["finance_type='InstantFee' AND instant_fees.instant_fee_category_id='#{params[:category_id]}' AND finance_transactions.created_at >= '#{@start_date}' and finance_transactions.created_at < '#{@end_date.to_date+1.day}'"])
    else
      @transactions=FinanceTransaction.paginate(:per_page=>10,:page=>params[:page],:order=>'created_at desc',:joins=>"INNER JOIN instant_fees ON instant_fees.id=finance_id LEFT OUTER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id",:conditions=>"finance_type='InstantFee' AND instant_fees.instant_fee_category_id is NULL AND finance_transactions.created_at >= '#{@start_date}' and finance_transactions.created_at < '#{@end_date.to_date+1.day}'")
    end
    render :update do |page|
      page.replace_html 'show_transactions',:partial => 'show_transactions'
    end
  end
end


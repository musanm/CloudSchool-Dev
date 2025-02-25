class InvoicesController < ApplicationController
  before_filter :login_required
  filter_access_to :all, :except => [:edit, :update, :destroy]
  filter_access_to [:edit, :update, :destroy], :attribute_check=>true

  def index
    @selected_store = (Invoice.last.nil? ? nil : Invoice.last.store.id) || (Store.first.present? ? Store.first.id : "")
  end
  
  def new
    @invoice = Invoice.new
    @stores = Store.find(:all, :joins => :store_items, :conditions => ["store_items.sellable = ? AND stores.is_deleted = ? AND store_items.is_deleted = ?",1, false,false]).uniq
    @sales_user_details = @invoice.sales_user_details.build
    @sold_items = @invoice.sold_items.build
    @discounts = @invoice.discounts.build
    @additional_charges = @invoice.additional_charges.build
    @invoice_no = generate_invoice_no(params[:selected_store])
    @selected_store = params[:selected_store] || (Store.first.present? ? Store.first.id : "")
  end

  def find_invoice_prefix
    invoice_no = generate_invoice_no(params[:id])
    render :json => {'invoice_no' => invoice_no }
  end

  def edit
    @invoice = Invoice.find(params[:id])
    @stores = Store.find(:all, :joins => :store_items, :conditions => ["store_items.sellable = ? AND stores.is_deleted = ? AND store_items.is_deleted = ?",1, false,false]).uniq
    @discounts = @invoice.discounts.build if @invoice.discounts.empty?
    @additional_charges = @invoice.additional_charges.build if @invoice.additional_charges.empty?
    @username = @invoice.sales_user_details.first.user.username if @invoice.sales_user_details.first.user.present?
  end

  def update
    @invoice = Invoice.find(params[:id])
    if @invoice.update_attributes(params[:invoice])
      if @invoice.is_paid
          payee = @invoice.sales_user_details.first.user
          transaction = FinanceTransaction.new
          transaction.title = @invoice.invoice_no
          transaction.category = FinanceTransactionCategory.find_by_name("SalesInventory")
          transaction.finance = @invoice
          transaction.payee = payee
          transaction.transaction_date = Date.today
          transaction.amount = params[:invoice][:grandtotal]
          transaction.save
      end
      flash[:notice] = "#{t('invoice_update_successfuly')}"
      redirect_to :action => "index"
    else
      flash[:notice] = "#{t('invoice__not_updated')}"
      @stores = Store.find(:all, :joins => :store_items, :conditions => ["store_items.sellable = ? AND stores.is_deleted = ? AND store_items.is_deleted = ?",1, false,false]).uniq
      render :action => "edit", :id => @invoice.id
    end
  end
  
  def create
    @invoice = Invoice.new(params[:invoice])
    @stores = Store.find(:all, :joins => :store_items, :conditions => ["store_items.sellable = ? AND stores.is_deleted = ? AND store_items.is_deleted = ?",1, false,false]).uniq
    @selected_store = params[:invoice][:store_id].to_i || (Store.first.present? ? Store.first.id : "")
    if @invoice.save
      flash[:notice] = "#{t('invoice_created')}"
      if @invoice.is_paid
        payee = @invoice.sales_user_details.first.user
        transaction = FinanceTransaction.new
        transaction.title = @invoice.invoice_no
        transaction.category = FinanceTransactionCategory.find_by_name("SalesInventory")
        transaction.finance = @invoice
        transaction.payee = payee
        transaction.transaction_date = @invoice.date
        transaction.amount = params[:invoice][:grandtotal]
        transaction.save
      end
      redirect_to :action => "new", :selected_store => params[:invoice][:store_id]
      flash[:notice] = "Invoice #{@invoice.invoice_no} created successfuly. <a href ='http://#{request.host_with_port}/invoices/invoice_pdf/#{@invoice.id}'>Print</a>"
    else
      @discounts = @invoice.discounts.build if @invoice.discounts.empty?
      @additional_charges = @invoice.additional_charges.build if @invoice.additional_charges.empty?
      render :action => 'new', :selected_store => params[:invoice][:store_id]
    end
  end

  def show
    @invoice = Invoice.find(params[:id])
    @currency = Configuration.find_by_config_key("CurrencyType").config_value
    @start_date = params[:start_date]
    @end_date = params[:end_date]
  end
  
  def destroy
    @invoice = Invoice.find(params[:id])
    @invoice.destroy
    flash[:notice] = "#{t('invoice_deleted_successfully')}"
    respond_to do |format|
      format.html { redirect_to(invoices_url) }
      format.xml  { head :ok }
    end
  end

  def search_code
    item_code = StoreItem.find(:all, :conditions=>[" is_deleted = ? AND code LIKE ? AND store_id = ? AND sellable = ?", false,"%#{params[:query]}%","#{params[:store_id]}", 1])
    render :json=>{'query'=>params["query"],'suggestions'=>item_code.collect{|c| c.code},'data'=>item_code.collect(&:id)  }
  end

  def search_store_item
    unless params[:id].nil?
      store_item = StoreItem.find(params[:id])
      store_item_name = store_item.item_name
      unit_price = store_item.unit_price
      render :json=> {'item_name' => store_item_name, 'unit_price' => unit_price, 'code' => store_item.code}
    else
      store_item = StoreItem.find(:all, :conditions=>[" is_deleted = ? AND item_name LIKE ? AND store_id = ? AND sellable = ?",false, "%#{params[:query]}%","#{params[:store_id]}", 1])
      render :json=> {'query'=>params["query"],'suggestions'=>store_item.collect{|c| c.item_name},'data'=>store_item.collect(&:id)}

    end
    
  end

  def search_username
    user = User.active.find(:all, :conditions=>["username LIKE ?", "%#{params[:query]}%"])
    render :json=>{'query'=>params["query"],'suggestions'=>user.collect{|c| c.username},'data'=>user.collect(&:id)  }
  end

  
  
  def search_user_details
    user = User.find(params[:id])
    first_name = user.first_name
    address = ""
    if user.employee?
      emp = Employee.find_by_user_id(user.id)
      address += emp.home_address_line1 + "\n" unless emp.home_address_line1.nil?
      address += emp.home_address_line2 + "\n" unless emp.home_address_line2.nil?
      address += emp.home_city+ "\n" unless emp.home_city.nil?
      address += emp.home_state + "\n"unless emp.home_state.nil?
      #address += emp.home_country unless emp.home_country_id.nil?
      address += emp.home_pin_code + "\n"unless emp.home_pin_code.nil?
    elsif user.student?
      stud = Student.find_by_user_id(user.id)
      address += stud.address_line1 + "\n" unless stud.address_line1.nil?
      address += stud.address_line2 + "\n" unless stud.address_line2.nil?
      address += stud.city + "\n" unless stud.city.nil?
      address += stud.state + "\n" unless stud.state.nil?
      address += stud.pin_code + "\n" unless stud.pin_code.nil?
      #address += stud.country + "\n" unless stud.country_id.nil?
    end
    render :json => {'name' => first_name, 'address' => address, :user_id => user.id}
  end

  def update_invoice
    @currency = Configuration.find_by_config_key("CurrencyType").config_value
    @invoices = Invoice.paginate(:page => params[:page],:per_page => 10, :conditions => ["invoice_no LIKE ? AND store_id = ? ", "#{params[:query]}%", params[:id] ], :order => 'id desc')  
    render(:update) do|page|
      page.replace_html 'update_invoice', :partial=>'list_invoices'
    end
  end

  def invoice_pdf
    @invoice = Invoice.find(params[:id])
    @store_name = @invoice.store.name
    @user = @invoice.sales_user_details.first.user
    @currency = Configuration.find_by_config_key("CurrencyType").config_value
    if @invoice.is_paid
      transaction = @invoice.finance_transaction
      unless transaction.nil?
        @transaction_date = transaction.transaction_date
        @amount = transaction.amount
        @reciept_no = transaction.receipt_no
      end
    end
    render :pdf => 'invoice_pdf', :show_as_html => false
  end

  def find_item_name
    @store_item = StoreItem.find(params[:id])
    render :json => {:item_name => @store_item.item_name}
  end


  def report
    if date_format_check
      inventory = FinanceTransactionCategory.find_by_name('SalesInventory').id
      @inventory_transactions = FinanceTransaction.find(:all,:conditions=> "transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'and category_id ='#{inventory}'")
    end
  end
  
  private

  def generate_invoice_no(store_id)
    prefix = Store.find(store_id).invoice_prefix || "INV"
    last_invoice = Invoice.last(:conditions=> ["store_id = ? and invoice_no LIKE (?)",store_id,"#{prefix}%"])
    unless last_invoice.nil?
      invoice_suffix = last_invoice.invoice_no.scan(/\d+/).first
      invoice_suffix = invoice_suffix.next unless invoice_suffix.nil?
    end
    suffix =  invoice_suffix || "001"
    return prefix + suffix
  end
end





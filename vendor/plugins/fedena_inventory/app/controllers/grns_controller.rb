class GrnsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  before_filter :set_precision
  
  def index
    @grns = Grn.active.paginate :page => params[:page],:per_page => 20

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @grns }
    end
  end

  def show
    @grn = Grn.active.find(params[:id])
    @user = @grn.purchase_order.indent.user unless @grn.purchase_order.indent.nil?
    @total =0
    @grn.grn_items.each do |i|
      @total  += ( i.quantity *  i.unit_price )+ ( i.quantity *  i.unit_price )* ( i.tax * 0.01) - ( i.quantity *  i.unit_price )* ( i.discount * 0.01)
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @grn }
    end
  end

  def new
    @supplier=[]
    @grn = Grn.new
    @purchase_orders = PurchaseOrder.active.select{|po| po.po_status == "Issued"}
    @last_grn = Grn.last.grn_no unless Grn.last.nil?
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @grn }
    end
  end
  
  def create
    @grn = Grn.new(params[:grn])
    @supplier=[]
    respond_to do |format|
      if @grn.save
        flash[:notice] = "GRN successfully created "
        format.html { redirect_to(@grn) }
        format.xml  { render :xml => @grn, :status => :created, :location => @grn }
      else
        @purchase_orders = PurchaseOrder.active.select{|po| po.po_status == "Issued"}
        @last_grn = Grn.last.grn_no unless Grn.last.nil?
        format.html { render :action => "new" }
        format.xml  { render :xml => @grn.errors, :status => :unprocessable_entity }
      end
    end

  end

  def grn_pdf
    @grn = Grn.find(params[:id])
    @user = @grn.purchase_order.indent.user unless @grn.purchase_order.indent.nil?
    @total =0
    @grn.grn_items.each do |i|
      @total  += ( i.quantity *  i.unit_price )+ ( i.quantity *  i.unit_price )* ( i.tax * 0.01) - ( i.quantity *  i.unit_price )* ( i.discount * 0.01)
    end
    render :pdf=>'grn_pdf'
  end

  def update_po
    unless params[:po_id].to_i==0
      @po  = PurchaseOrder.active.find_by_id(params[:po_id])
      @grn = Grn.new
      @store_items = @po.store.store_items.active
      @po.purchase_items.each do |po|
        @grn.grn_items.build(:store_item_id => po.store_item_id,:quantity => po.quantity, :unit_price => po.price,:tax => po.tax, :discount => po.discount)
      end

      render :update do |page|
        page.replace_html 'update_po_item',:partial => 'grn_item_fields',:locals => {:f =>  ActionView::Helpers::FormBuilder.new(:grn,@grn,@template,{},{})}
      end
    else
      render :update do |page|
        page.replace_html 'update_po_item',:text=> ""
      end
    end
  end

  def report
    if date_format_check
      inventory = FinanceTransactionCategory.find_by_name('Inventory').id
      @inventory_transactions = FinanceTransaction.find(:all,:conditions=> "transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'and category_id ='#{inventory}'")
    end
  end

  def report_detail
    if date_format_check
      @grn_report = Grn.find(params[:id])
      inventory = FinanceTransactionCategory.find_by_name('Inventory').id
      @inventory_transactions = FinanceTransaction.find(:all,:conditions=> "transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'and category_id ='#{inventory}'")
      @user = @grn_report.purchase_order.indent.user unless @grn_report.purchase_order.indent.nil?
      @total =0
      @grn_report.grn_items.each do |i|
        @total  += ( i.quantity *  i.unit_price )+ ( i.quantity *  i.unit_price )* ( i.tax * 0.01) - ( i.quantity *  i.unit_price )* ( i.discount * 0.01)
      end
    end
  end

  #  def destroy
  #    @grn = Grn.active.find(params[:id])
  #    if @grn.can_be_deleted?
  #      if @grn.update_attributes(:is_deleted => true)
  #        flash[:notice] = 'GRN was successfully deleted.'
  #      else
  #        flash[:warn_notice]="<p>GRN is in use and can not be deleted</p>"
  #      end
  #    else
  #      flash[:warn_notice]="<p>GRN is in use and can not be deleted</p>"
  #    end
  #    respond_to do |format|
  #      format.html { redirect_to(grns_url) }
  #      format.xml  { head :ok }
  #    end
  #  end
end


class FinanceExtensionsController < FinanceController

  def pay_fees_in_particular_wise
    @student = Student.find(params[:id])
    @dates=FinanceFeeCollection.find(:all, :joins => "INNER JOIN collection_particulars on collection_particulars.finance_fee_collection_id=finance_fee_collections.id INNER JOIN finance_fee_particulars on finance_fee_particulars.id=collection_particulars.finance_fee_particular_id INNER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id", :conditions => "finance_fees.student_id='#{@student.id}' and finance_fee_collections.is_deleted=#{false} and ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id='#{@student.batch_id}') or (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id='#{@student.id}') or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id='#{@student.student_category_id}'))").uniq
  end

  def particular_wise_fee_payment
    @target_action='particular_wise_fee_payment'
    @target_controller='finance_extensions'
    if params[:date].present?
      @student = Student.find(params[:id])
      @date = @fee_collection = FinanceFeeCollection.find(params[:date], :include => [:fee_category, {:finance_fee_particulars => :particular_payments}, :fee_discounts])
      @financefee =FinanceFee.find_by_fee_collection_id_and_student_id(@date.id, @student.id, :include => [:finance_transactions, {:particular_payments => [:particular_discounts, :finance_fee_particular]}])
      @due_date = @fee_collection.due_date
      @fee_category = @fee_collection.fee_category
      @transaction_category_id=FinanceTransactionCategory.find_by_name("Fee").id
      particular_and_discount_details
      bal=(@total_payable-@total_discount).to_f
      days=(Date.today-@date.due_date.to_date).to_i
      auto_fine=@date.fine
      if days > 0 and auto_fine
        @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
      end
      @paid_fine=@fine_amount
      @fine_amount=0 if @financefee.is_paid
      if request.post?
        transaction=FinanceTransaction.new(params[:fees])
        check_amount=transaction.amount.to_f-transaction.fine_amount.to_f
        unless (FedenaPrecision.set_and_modify_precision(@financefee.balance).to_f+FedenaPrecision.set_and_modify_precision(@fine_amount).to_f) < check_amount
          if transaction.save
            finance_transaction_hsh={"finance_transaction_id" => transaction.id}
            if params[:particular_payment].present?
              params[:particular_payment][:particular_payments_attributes].values.each { |hsh| hsh.merge!(finance_transaction_hsh) }
              @financefee.update_attributes(params[:particular_payment])
            end
            flash[:notice]="#{t('fee_paid')}"
            @error=false
          else
            flash[:notice]="#{t('fee_payment_failed')}"
          end
        else
          flash[:notice] = "#{t('fee_payment_failed')}"
          @error=false
        end
      end
      @financefee.reload
      @paid_fees=@financefee.finance_transactions.all(:include => [{:particular_payments => [:finance_fee_particular, :particular_discounts]}])
      paid_fine=@paid_fees.select { |fine_transaction| fine_transaction.description=='fine_amount_included' }.sum(&:fine_amount).to_f
      @fine_amount=@fine_amount.to_f-paid_fine
      @fine_amount=0 if @financefee.is_paid
      # @fine_amount=@fine_amount
      # @fine_amount=nil unless @financefee.balance <= @fine_amount
      @applied_discount=FedenaPrecision.set_and_modify_precision(ParticularDiscount.find(:all, :joins => [{:particular_payment => :finance_fee}], :conditions => "finance_fees.id=#{@financefee.id}").sum(&:discount)).to_f
    else
      @error=true


    end
  end


  def particular_wise_fee_pay_pdf
    @fine_amount=params[:fine_amount]
    @paid_fine=@fine_amount
    @student = Student.find(params[:id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date], :include => [:fee_category, {:finance_fee_particulars => :particular_payments}, :fee_discounts])
    @financefee =FinanceFee.find_by_fee_collection_id_and_student_id(@date.id, @student.id, :include => [:finance_transactions, {:particular_payments => [:particular_discounts, :finance_fee_particular]}])
    @due_date = @fee_collection.due_date
    @fee_category = @fee_collection.fee_category
    @transaction_category_id=FinanceTransactionCategory.find_by_name("Fee").id
    particular_and_discount_details
    @paid_fees=@financefee.finance_transactions.all(:include => [{:particular_payments => [:finance_fee_particular, :particular_discounts]}])
    @applied_discount=ParticularDiscount.find(:all, :joins => [{:particular_payment => :finance_fee}], :conditions => "finance_fees.id=#{@financefee.id}").sum(&:discount).to_f
    @fine_amount=0 if @financefee.is_paid
    render :pdf => 'particular_wise_fee_pay_pdf'
  end
  def fetch_all_fees
    master_fees_sql="SELECT distinct finance_fee_collections.name as collection_name,finance_fees.is_paid,finance_fees.balance,finance_fees.id as id,'FinanceFee' as fee_type,(finance_fees.balance+(select ifnull(sum(finance_transactions.amount-finance_transactions.fine_amount),0) from finance_transactions where finance_transactions.finance_id=finance_fees.id and finance_transactions.finance_type='FinanceFee')) as actual_amount,(select(fr.fine_amount) from fine_rules fr where fr.id=max(fine_rules.id)) as fine_amount,fine_rules.is_amount FROM `finance_fees` INNER JOIN `finance_fee_collections` ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id INNER JOIN `fee_collection_batches` ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN `collection_particulars` ON (`finance_fee_collections`.`id` = `collection_particulars`.`finance_fee_collection_id`) INNER JOIN `finance_fee_particulars` ON (`finance_fee_particulars`.`id` = `collection_particulars`.`finance_fee_particular_id`) LEFT JOIN `fines` ON `fines`.id = `finance_fee_collections`.fine_id AND fines.is_deleted is false LEFT JOIN `fine_rules` ON fine_rules.fine_id = fines.id and fine_days <= DATEDIFF(CURDATE(),finance_fee_collections.due_date) "
    (FedenaPlugin.can_access_plugin?("fedena_hostel") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "HostelAdmin"))? hostel_fees_sql="UNION ALL (SELECT fc.name as collection_name,if(hf.finance_transaction_id is null,false,true) is_paid,if(hf.finance_transaction_id is null,hf.rent,0) balance,hf.id as id,'HostelFee' as fee_type,hf.rent actual_amount,0 fine_amount,0 is_amount FROM `hostel_fees` hf INNER JOIN `hostel_fee_collections` fc ON `fc`.id = `hf`.hostel_fee_collection_id and fc.is_deleted=0 and hf.student_id='#{@student.id}')" : hostel_fees_sql=''
    (FedenaPlugin.can_access_plugin?("fedena_transport") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "TransportAdmin"))? transport_fees_sql="UNION ALL (SELECT tc.name as collection_name,if(tf.transaction_id is null,false,true) is_paid,if(tf.transaction_id is null,tf.bus_fare,0) balance,tf.id as id,'TransportFee' as fee_type,tf.bus_fare actual_amount,0 fine_amount,0 is_amount FROM `transport_fees` tf INNER JOIN `transport_fee_collections` tc ON `tc`.id = `tf`.transport_fee_collection_id and tc.is_deleted=0 and tf.receiver_id='#{@student.id}' and tf.receiver_type='Student')" : transport_fees_sql=''
    @finance_fees=FinanceFee.find_by_sql("#{master_fees_sql} WHERE (finance_fees.student_id=#{@student.id} and finance_fee_collections.is_deleted=0 and ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=finance_fees.batch_id) or (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id=finance_fees.student_id) or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id=finance_fees.student_category_id))) GROUP BY finance_fees.id  #{transport_fees_sql}  #{hostel_fees_sql}")
  end

  def pay_all_fees
    @student=Student.find(params[:id])
    fetch_all_fees
    #    @finance_fees=FinanceFee.find(:all, :select => "distinct finance_fees.*", :include => [{:finance_fee_collection => [{:fine => :fine_rules}]}], :joins => [{:finance_fee_collection => [:fee_collection_batches, :finance_fee_particulars]}], :conditions => "finance_fees.student_id='#{@student.id}' and finance_fee_collections.is_deleted=0 and ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id='#{@student.batch_id}') or (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id='#{@student.id}') or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id='#{@student.student_category_id}'))")
    @transaction_category_id=FinanceTransactionCategory.find_by_name("Fee").id
    if request.post?
      status=true
      MultiFeesTransaction.transaction do
        multi_fees_transaction= MultiFeesTransaction.create(params[:multi_fees_transaction])
        begin
          finance_transactions=FinanceTransaction.create!(params[:transactions].values)
        rescue Exception => e
          status=false
        end

        if status and (multi_fees_transaction.valid? && finance_transactions.all?(&:valid?))
          multi_fees_transaction.finance_transactions=finance_transactions
          flash[:notice]="#{t('fees_paid')}"
        else
          flash[:notice]="#{t('fee_payment_failed')}"
          raise ActiveRecord::Rollback
        end
      end
      redirect_to :controller => 'finance_extensions', :action => 'pay_all_fees'
    end
    @paid_fees=@student.multi_fees_transactions
    fees="'FinanceFee'"
    (FedenaPlugin.can_access_plugin?("fedena_hostel") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "HostelAdmin"))? fees=fees+",'HostelFee'" : fees
    (FedenaPlugin.can_access_plugin?("fedena_transport") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "TransportAdmin"))? fees=fees+",'TransportFee'" : fees
    @other_transactions=FinanceTransaction.find(:all, :select => "distinct finance_transactions.*", :joins => "LEFT OUTER JOIN `multi_fees_transactions_finance_transactions` ON `multi_fees_transactions_finance_transactions`.finance_transaction_id = `finance_transactions`.id LEFT OUTER JOIN `multi_fees_transactions` ON `multi_fees_transactions`.id = `multi_fees_transactions_finance_transactions`.multi_fees_transaction_id", :conditions => "payee_id='#{@student.id}' and multi_fees_transactions.id is NULL and finance_type in (#{fees})")
  end

  def delete_multi_fees_transaction
    @student=Student.find(params[:id])
    @transaction_category_id=FinanceTransactionCategory.find_by_name("Fee").id
    if params[:type]=='multi_fees_transaction'
      mft=MultiFeesTransaction.find(params[:transaction_id])
      mft.destroy
    else
      ActiveRecord::Base.transaction do
        ft= FinanceTransaction.find(params[:transaction_id])
        if FedenaPlugin.can_access_plugin?("fedena_pay")
          payment = ft.payment
          unless payment.nil?
            status = Payment.payment_status_mapping[:reverted]
            payment.update_attributes(:status_description => status)
            payment.save
          end
        end
        raise ActiveRecord::Rollback unless ft.destroy
      end
    end
    fees="'FinanceFee'"
    (FedenaPlugin.can_access_plugin?("fedena_hostel") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "HostelAdmin"))? fees=fees+",'HostelFee'" : fees
    (FedenaPlugin.can_access_plugin?("fedena_transport") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "TransportAdmin"))? fees=fees+",'TransportFee'" : fees
    @paid_fees=@student.multi_fees_transactions
    @other_transactions=FinanceTransaction.find(:all, :select => "distinct finance_transactions.*", :joins => "LEFT OUTER JOIN `multi_fees_transactions_finance_transactions` ON `multi_fees_transactions_finance_transactions`.finance_transaction_id = `finance_transactions`.id LEFT OUTER JOIN `multi_fees_transactions` ON `multi_fees_transactions`.id = `multi_fees_transactions_finance_transactions`.multi_fees_transaction_id", :conditions => "payee_id='#{@student.id}' and multi_fees_transactions.id is NULL and finance_type in (#{fees})")
    fetch_all_fees
    render :update do |page|
      flash[:notice]="#{t('finance.flash18')}"
      page.replace_html "pay_fees", :partial => 'pay_fees_form'
    end
  end

  def pay_all_fees_receipt_pdf
    @student=Student.find(params[:id])
    fetch_all_fees
    fees="'FinanceFee'"
    (FedenaPlugin.can_access_plugin?("fedena_hostel") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "HostelAdmin"))? fees=fees+",'HostelFee'" : fees
    (FedenaPlugin.can_access_plugin?("fedena_transport") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "TransportAdmin"))? fees=fees+",'TransportFee'" : fees
    @paid_fees=@student.multi_fees_transactions
    @other_transactions=FinanceTransaction.find(:all, :select => "distinct finance_transactions.*", :joins => "LEFT OUTER JOIN `multi_fees_transactions_finance_transactions` ON `multi_fees_transactions_finance_transactions`.finance_transaction_id = `finance_transactions`.id LEFT OUTER JOIN `multi_fees_transactions` ON `multi_fees_transactions`.id = `multi_fees_transactions_finance_transactions`.multi_fees_transaction_id", :conditions => "payee_id='#{@student.id}' and multi_fees_transactions.id is NULL and finance_type in (#{fees})")
    render :pdf => 'pay_all_fees_receipt_pdf'
  end

  def discount_particular_allocation
    @batches=Batch.active
    @dates=[]
  end

  def particulars_with_tabs
    if params[:collection_id].present?
      @finance_fee_collection=FinanceFeeCollection.find(params[:collection_id])
      finance_fee_category=@finance_fee_collection.fee_category
      paid_fees=FinanceFee.find(:all, :joins => :finance_transactions, :conditions => "fee_collection_id='#{@finance_fee_collection.id}'")
      # paid_fees=finance_fee_collection.finance_fees.all(:conditions => "is_paid=true")
      paid_student_ids=(paid_fees.collect(&:student_id)<<0).compact
      paid_student_category_ids=(paid_fees.collect(&:student_category_id)<<0).compact
      @particulars=FinanceFeeParticular.find(:all, :select => "finance_fee_particulars.*,IF(batches.id is null,IF(student_categories.id is NULL,concat(students.first_name,\" (\",students.admission_no,\" )\"),student_categories.name),'') as receiver_name,if(#{paid_fees.present? and params[:type]=='Batch'},true,if(#{paid_fees.present? and params[:type]=='Student'} and finance_fee_particulars.receiver_id in (#{paid_student_ids.join(',')}),true,if(#{paid_fees.present? and params[:type]=='StudentCategory'} and finance_fee_particulars.receiver_id in (#{paid_student_category_ids.join(',')}),true,false))) as disabled", :joins => "LEFT JOIN batches on batches.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='Batch' LEFT JOIN students on students.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='Student' LEFT JOIN student_categories on student_categories.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='StudentCategory'", :conditions => "finance_fee_particulars.is_instant=false and finance_fee_particulars.batch_id='#{params[:batch_id]}' and finance_fee_category_id='#{finance_fee_category.id}' and finance_fee_particulars.receiver_type='#{params[:type]}'")
      @collection_particular_ids=@finance_fee_collection.collection_particulars.collect(&:finance_fee_particular_id)
      @partial='particulars'
      @particular_details=FinanceFeeParticular.find(:all, :select => "count(distinct finance_fee_particulars.id) as total,count(IF(finance_fee_particulars.receiver_type='Student',1,NULL)) as student_wise,count(IF(finance_fee_particulars.receiver_type='StudentCategory',1,NULL)) as category_wise,count(IF(finance_fee_particulars.receiver_type='Batch',1,NULL)) as batch_wise", :joins => :collection_particulars, :conditions => "finance_fee_particulars.is_instant=false and collection_particulars.finance_fee_collection_id='#{@finance_fee_collection.id}' and finance_fee_particulars.batch_id='#{params[:batch_id]}'").first
      render :update do |page|
        page.replace_html "receivers", :partial => 'batches_and_fee_collections'
        page.replace_html "particular-wise-discount", :text => ""

      end
    else
      render :update do |page|
        page.hide "loader_collection"
        page.replace_html "receivers", :text => ''
        page.replace_html "particular-wise-discount", :text => ""

      end
    end
  end

  def show_discounts
    @finance_fee_collection=FinanceFeeCollection.find(params[:collection_id])
    finance_fee_category=@finance_fee_collection.fee_category
    paid_fees=FinanceFee.find(:all, :joins => :finance_transactions, :conditions => "fee_collection_id='#{@finance_fee_collection.id}'")
    # paid_fees=@finance_fee_collection.finance_fees.all(:conditions => "is_paid=true")
    paid_student_ids=(paid_fees.collect(&:student_id)<<0).compact
    paid_student_category_ids=(paid_fees.collect(&:student_category_id)<<0).compact
    @discounts=FeeDiscount.find(:all, :select => "fee_discounts.*,IF(batches.id is null,IF(student_categories.id is NULL,IF(finance_fee_particulars.id is NULL,IF(students.id is NULL,concat(archived_students.first_name,\" (\",archived_students.admission_no,\" )\"),concat(students.first_name,\" (\",students.admission_no,\" )\")),finance_fee_particulars.name),student_categories.name),'') as receiver_name,if(#{paid_fees.present? } and fee_discounts.receiver_type='Batch',true,if(#{paid_fees.present? } and fee_discounts.receiver_type='Student' and fee_discounts.receiver_id in (#{paid_student_ids.join(',')}),true,if(#{paid_fees.present?} and fee_discounts.receiver_type='StudentCategory' and fee_discounts.receiver_id in (#{paid_student_category_ids.join(',')}),true,false))) as disabled", :joins => "LEFT JOIN batches on batches.id=fee_discounts.master_receiver_id and fee_discounts.master_receiver_type='Batch' LEFT JOIN archived_students on archived_students.former_id=fee_discounts.master_receiver_id and fee_discounts.master_receiver_type='Student' LEFT JOIN students on students.id=fee_discounts.master_receiver_id and fee_discounts.master_receiver_type='Student' LEFT JOIN student_categories on student_categories.id=fee_discounts.master_receiver_id and fee_discounts.master_receiver_type='StudentCategory' LEFT JOIN finance_fee_particulars on finance_fee_particulars.id=fee_discounts.master_receiver_id and fee_discounts.master_receiver_type='FinanceFeeParticular'", :conditions => "fee_discounts.is_instant=false and fee_discounts.batch_id='#{params[:batch_id]}' and fee_discounts.finance_fee_category_id='#{finance_fee_category.id}' and fee_discounts.master_receiver_type='#{params[:type]}'")
    # @discounts=finance_fee_category.fee_discounts.all(:conditions => {:batch_id => params[:batch_id], :receiver_type => params[:type]})
    @collection_discount_ids=@finance_fee_collection.collection_discounts.collect(&:fee_discount_id)
    @discount_details=FeeDiscount.find(:all, :select => "count(distinct fee_discounts.id) as total,count(IF(fee_discounts.master_receiver_type='Student',1,NULL)) as student_wise,count(IF(fee_discounts.master_receiver_type='StudentCategory',1,NULL)) as category_wise,count(IF(fee_discounts.master_receiver_type='Batch',1,NULL)) as batch_wise,count(IF(fee_discounts.master_receiver_type='FinanceFeeParticular',1,NULL)) as particular_wise", :joins => :collection_discounts, :conditions => "fee_discounts.is_instant=false and collection_discounts.finance_fee_collection_id='#{@finance_fee_collection.id}' and fee_discounts.batch_id='#{params[:batch_id]}'").first
    render :update do |page|
      page.replace_html "particular-wise-discount", :text => "#{link_to_function t('particular')+'-'+t('wise'), 'select_tab(this);' }"
      page.replace_html "right-panel", :partial => 'discounts'
    end

  end

  def show_particulars
    @finance_fee_collection=FinanceFeeCollection.find(params[:collection_id])
    finance_fee_category=@finance_fee_collection.fee_category
    paid_fees=FinanceFee.find(:all, :joins => :finance_transactions, :conditions => "fee_collection_id='#{@finance_fee_collection.id}'")
    paid_student_ids=(paid_fees.collect(&:student_id)<<0).compact
    paid_student_category_ids=(paid_fees.collect(&:student_category_id)<<0).compact
    @particulars=FinanceFeeParticular.find(:all, :select => "finance_fee_particulars.*,IF(batches.id is null,IF(student_categories.id is NULL,concat(students.first_name,\" (\",students.admission_no,\" )\"),student_categories.name),'') as receiver_name,if(#{paid_fees.present? and params[:type]=='Batch'},true,if(#{paid_fees.present? and params[:type]=='Student'} and finance_fee_particulars.receiver_id in (#{paid_student_ids.join(',')}),true,if(#{paid_fees.present? and params[:type]=='StudentCategory'} and finance_fee_particulars.receiver_id in (#{paid_student_category_ids.join(',')}),true,false))) as disabled", :joins => "LEFT JOIN batches on batches.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='Batch' LEFT JOIN students on students.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='Student' LEFT JOIN student_categories on student_categories.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='StudentCategory'", :conditions => "finance_fee_particulars.is_instant=false and finance_fee_particulars.batch_id='#{params[:batch_id]}' and finance_fee_category_id='#{finance_fee_category.id}' and finance_fee_particulars.receiver_type='#{params[:type]}'")
    # @particulars=FinanceFeeParticular.find(:all,:select=>"finance_fee_particulars.*,IF(batches.id is null,IF(student_categories.id is NULL,concat(students.first_name,\" (\",students.admission_no,\" )\"),student_categories.name),'') as receiver_name",:joins=>"LEFT JOIN batches on batches.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='Batch' LEFT JOIN students on students.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='Student' LEFT JOIN student_categories on student_categories.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='StudentCategory'",:conditions=>"finance_fee_particulars.batch_id='#{params[:batch_id]}' and finance_fee_category_id='#{finance_fee_category.id}' and finance_fee_particulars.receiver_type='#{params[:type]}'")
    # @particulars=finance_fee_category.fee_particulars.all(:conditions => {:batch_id => params[:batch_id], :receiver_type => params[:type]})
    @collection_particular_ids=@finance_fee_collection.collection_particulars.collect(&:finance_fee_particular_id)
    @particular_details=FinanceFeeParticular.find(:all, :select => "count(distinct finance_fee_particulars.id) as total,count(IF(finance_fee_particulars.receiver_type='Student',1,NULL)) as student_wise,count(IF(finance_fee_particulars.receiver_type='StudentCategory',1,NULL)) as category_wise,count(IF(finance_fee_particulars.receiver_type='Batch',1,NULL)) as batch_wise", :joins => :collection_particulars, :conditions => "finance_fee_particulars.is_instant=false and collection_particulars.finance_fee_collection_id='#{@finance_fee_collection.id}' and finance_fee_particulars.batch_id='#{params[:batch_id]}' ").first
    render :update do |page|
      page.replace_html "right-panel", :partial => 'particulars'
      page.replace_html "particular-wise-discount", :text => ''
    end
  end


  def fee_collections_for_batch
    @batch=Batch.find(params[:batch_id])
    @dates=@batch.finance_fee_collections
    render :update do |page|
      page.replace_html "fee_collections", :partial => 'fee_collections'
    end
  end

  def update_collection_discount
    flash_message=''
    finance_fee_collection=FinanceFeeCollection.find(params[:fees_list][:collection_id])
    finance_fee_category=finance_fee_collection.fee_category
    paid_fees=FinanceFee.find(:all, :joins => :finance_transactions, :conditions => "fee_collection_id='#{finance_fee_collection.id}'")
    paid_student_ids=(paid_fees.collect(&:student_id)<<0).compact
    paid_student_category_ids=(paid_fees.collect(&:student_category_id)<<0).compact
    collection_discount_ids=finance_fee_collection.collection_discounts.collect(&:fee_discount_id)
    discounts=FeeDiscount.find(:all, :select => "fee_discounts.*,if(#{paid_fees.present? } and fee_discounts.receiver_type='Batch',true,if(#{paid_fees.present? } and fee_discounts.receiver_type='Student' and fee_discounts.receiver_id in (#{paid_student_ids.join(',')}),true,if(#{paid_fees.present?} and fee_discounts.receiver_type='StudentCategory' and fee_discounts.receiver_id in (#{paid_student_category_ids.join(',')}),true,false))) as disabled", :joins => "LEFT JOIN batches on batches.id=fee_discounts.master_receiver_id and fee_discounts.master_receiver_type='Batch' LEFT JOIN students on students.id=fee_discounts.master_receiver_id and fee_discounts.master_receiver_type='Student' LEFT JOIN student_categories on student_categories.id=fee_discounts.master_receiver_id and fee_discounts.master_receiver_type='StudentCategory' LEFT JOIN finance_fee_particulars on finance_fee_particulars.id=fee_discounts.master_receiver_id and fee_discounts.master_receiver_type='FinanceFeeParticular'", :conditions => "fee_discounts.is_instant=false and fee_discounts.batch_id='#{params[:fees_list][:batch_id]}' and fee_discounts.finance_fee_category_id='#{finance_fee_category.id}' and fee_discounts.master_receiver_type='#{params[:fees_list][:type]}'")
    disabled_discounts=discounts.select { |d| d.disabled? }.collect(&:id)
    disabled_and_assigned=collection_discount_ids&disabled_discounts
    disabled_and_unassigned=disabled_discounts-collection_discount_ids


    existing_discounts=CollectionDiscount.find(:all, :select => "distinct collection_discounts.*", :joins => [:finance_fee_collection, :fee_discount], :include => :fee_discount, :conditions => "fee_discounts.is_instant=false and finance_fee_collections.id='#{params[:fees_list][:collection_id]}' and fee_discounts.batch_id='#{params[:fees_list][:batch_id]}' and fee_discounts.master_receiver_type='#{params[:fees_list][:type]}'")
    existing_discounts_ids=existing_discounts.collect(&:fee_discount_id)
    new_discount_ids=[]
    new_discount_ids=params[:fees_list][:discount_ids].map { |d| d.to_i } if params[:fees_list][:discount_ids].present?
    discounts_to_be_deleted=existing_discounts_ids-new_discount_ids
    discounts_to_be_added=new_discount_ids-existing_discounts_ids


    unless (discounts_to_be_deleted&disabled_and_assigned).present? or (discounts_to_be_added&disabled_and_unassigned).present?

      ActiveRecord::Base.transaction do
        begin
          existing_discounts.select { |ed| discounts_to_be_deleted.include? ed.fee_discount_id }.each do |cd|
            discount=cd.fee_discount
            cd.destroy
            status=add_or_remove_discount(discount, finance_fee_collection, params[:fees_list][:batch_id], '+')
          end

          discounts_to_be_added.each do |discount_id|

            discount=FeeDiscount.find(discount_id)
            status=add_or_remove_discount(discount, finance_fee_collection, params[:fees_list][:batch_id], '-')

            CollectionDiscount.create(:finance_fee_collection_id => finance_fee_collection.id, :fee_discount_id => discount.id)

          end
          flash_message="<p class='flash-msg'>#{t('discounts')} #{t('update').downcase} #{t('succesful')}</p>"
        rescue Exception => e
          flash_message="<p class='flash-msg'>#{t('flash_msg3')}</p>"
          a={"discount" => {"collection-"+finance_fee_collection.id.to_s => e.message}}
          File.open("#{RAILS_ROOT}/log/finance.yml", "a+") { |f| f.write a.to_yaml }
          raise ActiveRecord::Rollback
        end
      end
    else
      flash_message="<div class='errorExplanation'><ul><li>#{t('somebody_has_paid_for_the_collection_already')}. #{t('please_revert_transactions_and_try_again')}</li></ul></div>"
    end
    render :update do |page|
      page.replace_html "flash-div", :text => flash_message
    end
  end

  def update_collection_particular
    flash_message=''
    finance_fee_collection=FinanceFeeCollection.find(params[:fees_list][:collection_id])


    finance_fee_category=finance_fee_collection.fee_category
    paid_fees=FinanceFee.find(:all, :joins => :finance_transactions, :conditions => "fee_collection_id='#{finance_fee_collection.id}'")
    paid_student_ids=(paid_fees.collect(&:student_id)<<0).compact
    paid_student_category_ids=(paid_fees.collect(&:student_category_id)<<0).compact
    collection_particular_ids=finance_fee_collection.collection_particulars.collect(&:finance_fee_particular_id)
    particulars=FinanceFeeParticular.find(:all, :select => "finance_fee_particulars.*,if(#{paid_fees.present? and params[:fees_list][:type]=='Batch'},true,if(#{paid_fees.present? and params[:fees_list][:type]=='Student'} and finance_fee_particulars.receiver_id in (#{paid_student_ids.join(',')}),true,if(#{paid_fees.present? and params[:fees_list][:type]=='StudentCategory'} and finance_fee_particulars.receiver_id in (#{paid_student_category_ids.join(',')}),true,false))) as disabled", :joins => "LEFT JOIN batches on batches.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='Batch' LEFT JOIN students on students.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='Student' LEFT JOIN student_categories on student_categories.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='StudentCategory'", :conditions => "finance_fee_particulars.is_instant=false and finance_fee_particulars.batch_id='#{params[:fees_list][:batch_id]}' and finance_fee_category_id='#{finance_fee_category.id}' and finance_fee_particulars.receiver_type='#{params[:fees_list][:type]}'")
    disabled_particulars=particulars.select { |d| d.disabled? }.collect(&:id)
    disabled_and_assigned=collection_particular_ids&disabled_particulars
    disabled_and_unassigned=disabled_particulars-collection_particular_ids

    existing_particulars=CollectionParticular.find(:all, :select => "distinct collection_particulars.*", :joins => [:finance_fee_collection, :finance_fee_particular], :include => :finance_fee_particular, :conditions => "finance_fee_particulars.is_instant=false and finance_fee_collections.id='#{params[:fees_list][:collection_id]}' and finance_fee_particulars.batch_id='#{params[:fees_list][:batch_id]}' and finance_fee_particulars.receiver_type='#{params[:fees_list][:type]}'")
    existing_particulars_ids=existing_particulars.collect(&:finance_fee_particular_id)
    new_particular_ids=[]
    new_particular_ids=params[:fees_list][:particular_ids].map { |d| d.to_i } if params[:fees_list][:particular_ids].present?
    particulars_to_be_deleted=existing_particulars_ids-new_particular_ids
    particulars_to_be_added=new_particular_ids-existing_particulars_ids


    unless (particulars_to_be_deleted&disabled_and_assigned).present? or (particulars_to_be_added&disabled_and_unassigned).present?

      ActiveRecord::Base.transaction do
        begin

          existing_particulars.select { |ep| particulars_to_be_deleted.include? ep.finance_fee_particular_id }.each do |cp|
            particular=cp.finance_fee_particular
            cp.destroy
            FinanceFeeParticular.add_or_remove_particular_or_discount(particular, finance_fee_collection)
          end

          particulars_to_be_added.each do |particular_id|
            particular=FinanceFeeParticular.find(particular_id)
            CollectionParticular.create(:finance_fee_collection_id => finance_fee_collection.id, :finance_fee_particular_id => particular.id)
            FinanceFeeParticular.add_or_remove_particular_or_discount(particular, finance_fee_collection)

          end
          flash_message="<p class='flash-msg'>#{t('particulars')} #{t('update').downcase} #{t('succesful')}</p>"
        rescue Exception => e
          flash_message="<p class='flash-msg'>#{t('flash_msg3')} </p>"
          a={"particular" => {"collection-"+finance_fee_collection.id.to_s => e.message}}
          File.open("#{RAILS_ROOT}/log/finance.yml", "a+") { |f| f.write a.to_yaml }
          raise ActiveRecord::Rollback
        end
      end
    else
      flash_message="<div class='errorExplanation'><ul><li>#{t('somebody_has_paid_for_the_collection_already')}. #{t('please_revert_transactions_and_try_again')}</li></ul></div>"
    end
    render :update do |page|
      page.replace_html "flash-div", :text => flash_message
    end
  end

  def add_or_remove_discount(discount, finance_fee_collection, batch_id, operation)

    receiver=discount.receiver_type.underscore+"_id"

    if discount.is_amount?
      FinanceFee.update_all(["finance_fees.balance=finance_fees.balance#{operation}#{discount.discount} , finance_fees.is_paid=finance_fees.balance#{operation}#{discount.discount}<=0"], ["finance_fees.#{receiver}=#{discount.receiver_id} and finance_fees.batch_id='#{discount.batch_id}' and finance_fees.fee_collection_id='#{finance_fee_collection.id}'"])

    else
      if discount.master_receiver_type=='FinanceFeeParticular'
        particular=discount.master_receiver
        discount_amount=(particular.amount)*(discount.discount/100)
        sql="UPDATE finance_fees ff SET ff.balance=ff.balance#{operation}#{discount_amount} where ff.fee_collection_id=#{finance_fee_collection.id} and ff.#{receiver}=#{discount.receiver_id} and ff.batch_id=#{discount.batch_id}"
      else
        sql="UPDATE finance_fees ff SET ff.balance=ff.balance#{operation}(select sum(finance_fee_particulars.amount)*(#{discount.discount/100}) from finance_fee_particulars INNER JOIN collection_particulars on collection_particulars.finance_fee_particular_id=finance_fee_particulars.id  where collection_particulars.finance_fee_collection_id=#{finance_fee_collection.id} and finance_fee_particulars.finance_fee_category_id='#{finance_fee_collection.fee_category_id}' and finance_fee_particulars.batch_id='#{batch_id}' and ((finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id=ff.student_id) or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id=ff.student_category_id) or (finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=ff.batch_id))) where ff.fee_collection_id=#{finance_fee_collection.id} and ff.#{receiver}=#{discount.receiver_id} and ff.batch_id=#{discount.batch_id}"
      end

      sql1="UPDATE finance_fees ff SET ff.is_paid=(ff.balance<=0) where ff.fee_collection_id=#{finance_fee_collection.id} and ff.#{receiver}=#{discount.receiver_id} and ff.batch_id=#{discount.batch_id}"
      ActiveRecord::Base.connection.execute(sql)
      ActiveRecord::Base.connection.execute(sql1)

    end

  end


  def new_instant_particular
    @financefee=FinanceFee.find(params[:id])
    @target_action=params[:current_action]
    @target_controller=params[:current_controller]
    @finance_fee_category=@financefee.finance_fee_collection.fee_category
    respond_to do |format|
      format.js { render :action => 'create_instant_particular' }
    end
  end

  def create_instant_particular
    @status=false
    @fee_particular=FinanceFeeParticular.new(params[:finance_fee_particular])
    @financefee=FinanceFee.find(params[:id])
    if @fee_particular.save
      CollectionParticular.create(:finance_fee_particular_id => @fee_particular.id, :finance_fee_collection_id => @financefee.fee_collection_id)
      FinanceFeeParticular.add_or_remove_particular_or_discount(@fee_particular, @financefee.finance_fee_collection)
      @financefee.reload
      @target_action=params[:target_action]
      @target_controller=params[:target_controller]
      @status=true
    end
    respond_to do |format|
      format.js { render :action => 'instant_particular.js.erb'
      }
      format.html
    end
  end

  def delete_student_particular
    @particular=FinanceFeeParticular.find(params[:id])
    @financefee=FinanceFee.find(params[:finance_fee_id])
    @particular.destroy
    DiscountParticularLog.create(:amount => @particular.amount, :is_amount => true, :receiver_type => "FinanceFeeParticular", :finance_fee_id => @financefee.id, :user_id => current_user.id, :name => @particular.name)
    FinanceFeeParticular.add_or_remove_particular_or_discount(@particular, @financefee.finance_fee_collection)
    @target_action=params[:current_action]
    @target_controller=params[:current_controller]
    @financefee.reload
    respond_to do |format|
      format.js { render :action => 'instant_particular_delete.js.erb'
      }
      format.html
    end

  end

  def new_instant_discount
    @financefee=FinanceFee.find(params[:id])
    @target_action=params[:current_action]
    @target_controller=params[:current_controller]
    @finance_fee_category=@financefee.finance_fee_collection.fee_category
    respond_to do |format|
      format.js { render :action => 'create_instant_discount' }
    end
  end

  def create_instant_discount
    @status=false
    @fee_discount=FeeDiscount.new(params[:fee_discount])
    @financefee=FinanceFee.find(params[:id])
    fee_particulars = @financefee.finance_fee_collection.finance_fee_particulars.all(:conditions => "batch_id=#{@financefee.batch_id}").select { |par| (par.receiver.present?) and (par.receiver==@financefee.student or par.receiver==@financefee.student_category or par.receiver==@financefee.batch) }
    total_payable=fee_particulars.map { |s| s.amount }.sum.to_f
    discount_amount=@fee_discount.is_amount? ? (total_payable*(@fee_discount.discount.to_f)/total_payable) : (total_payable*(@fee_discount.discount.to_f)/100)
    unless  (discount_amount.to_f >= @financefee.balance.to_f)
      if @fee_discount.save
        CollectionDiscount.create(:fee_discount_id => @fee_discount.id, :finance_fee_collection_id => @financefee.fee_collection_id)
        FinanceFeeParticular.add_or_remove_particular_or_discount(@fee_discount, @financefee.finance_fee_collection)
        @financefee.reload
        @target_action=params[:target_action]
        @target_controller=params[:target_controller]
        @status=true
      end
    else
      @fee_discount.errors.add_to_base(t('discount_cannot_be_greater_than_total_amount'))
    end

    respond_to do |format|
      format.js { render :action => 'instant_discount.js.erb'
      }
      format.html
    end
  end

  def delete_student_discount
    @fee_discount=FeeDiscount.find(params[:id])
    @financefee=FinanceFee.find(params[:finance_fee_id])
    @fee_discount.destroy
    DiscountParticularLog.create(:amount => @fee_discount.discount, :is_amount => @fee_discount.is_amount, :receiver_type => "FeeDiscount", :finance_fee_id => @financefee.id, :user_id => current_user.id, :name => @fee_discount.name)
    FinanceFeeParticular.add_or_remove_particular_or_discount(@fee_discount, @financefee.finance_fee_collection)
    @target_action=params[:current_action]
    @target_controller=params[:current_controller]
    @financefee.reload
    respond_to do |format|
      format.js { render :action => 'instant_discount_delete.js.erb'
      }
      format.html
    end

  end

end

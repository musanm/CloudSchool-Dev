class FeeImportsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  def import_fees
    @student = Student.find_by_id(params[:id])
    @fee_collection_dates=FinanceFeeCollection.all(:select=>"distinct finance_fee_collections.*",:joins=>"INNER JOIN fee_collection_batches on fee_collection_batches.finance_fee_collection_id=finance_fee_collections.id LEFT OUTER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id INNER JOIN finance_fee_particulars on finance_fee_particulars.finance_fee_category_id=finance_fee_collections.fee_category_id",:conditions=>"(finance_fee_collections.is_deleted=false and (finance_fees.student_id='#{@student.id}' and finance_fees.is_paid=false) or fee_collection_batches.batch_id='#{@student.batch.id}') and ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id='#{@student.batch.id}') or (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id='#{@student.id}') or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id='#{@student.student_category_id}'))")
    if @fee_collection_dates.blank?
      flash[:notice] = t('add_the_additional_details')
      redirect_to :controller => "student", :action => "admission4", :id => @student.id,:imported=>'1'
    end
    if request.post?
      unless params[:fees].nil?
        dates = FinanceFeeCollection.find(params[:fees][:collection_ids])
        unless (@student.has_paid_fees or @student.has_paid_fees_for_batch)
          dates.each do |date|
            FinanceFee.new_student_fee(date,@student)
          end
        end
        flash[:notice] = "#{t('add_the_additional_details')}"
        redirect_to :controller => "student", :action => "admission4", :id => @student.id, :imported=>'1'
      else
        flash[:notice] = "#{t('please_select_fee_collection')}"
        redirect_to :action => 'import_fees', :id=>@student.id
      end
    end
  end

  def select_student
    @batches = Batch.active
    if request.post?
      if params[:fees_list].present?
        @student = Student.find_by_id(params[:fees_list][:student_id])
        @batch_selected=@student.batch
        collection_dates
        @finance_fees = FinanceFee.find_all_by_student_id(@student.id)
        @student_fees = @finance_fees.map{|s| s.fee_collection_id}
        #@payed_fees = @finance_fees.map{|s| s.fee_collection_id unless s.transaction_id.nil? }.compact
        @payed_fees=FinanceFee.find(:all,:joins=>"INNER JOIN fee_transactions on fee_transactions.finance_fee_id=finance_fees.id INNER JOIN finance_fee_collections on finance_fee_collections.id=finance_fees.fee_collection_id",:conditions=>"finance_fees.student_id=#{@student.id}",:select=>"finance_fees.fee_collection_id").map{|s| s.fee_collection_id}
        @payed_fees ||= []
        dates = []
        dates = params[:fees_list][:collection_ids].to_a unless params[:fees_list].nil?
        @fee_collection_dates.each do |date|
          if @student_fees.include?(date.id)
            unless dates.include?(date.id.to_s)
              fee = FinanceFee.find_by_student_id_and_fee_collection_id(@student.id, date.id)
              fee.destroy if fee.finance_transactions.empty?
              flash[:notice]="#{t('fee_collections_are_updated_to_the_student_successfully')}"
            end
          else

            if dates.include?(date.id.to_s)
              FinanceFee.new_student_fee(date,@student)
              flash[:notice]="#{t('fee_collections_are_updated_to_the_student_successfully')}"
            end

          end
        end
        flash[:notice]="#{t('no_changes_are_done')}" if flash[:notice].nil?
        flash.discard(:notice)
        @students = Student.find_all_by_batch_id(@student.batch_id, :order => 'first_name ASC')
        @finance_fees = FinanceFee.find_all_by_student_id(@student.id)
        @student_fees = @finance_fees.map{|s| s.fee_collection_id}
        @payed_fees=FinanceFee.find(:all,:joins=>"INNER JOIN fee_transactions on fee_transactions.finance_fee_id=finance_fees.id INNER JOIN finance_fee_collections on finance_fee_collections.id=finance_fees.fee_collection_id",:conditions=>"finance_fees.student_id=#{@student.id}",:select=>"finance_fees.fee_collection_id").map{|s| s.fee_collection_id}
        @payed_fees ||= []
      end
    end
  end

  def list_students_by_batch
    @students = Student.find_all_by_batch_id(params[:batch_id],:conditions=>"has_paid_fees=#{false} and has_paid_fees_for_batch=false", :order => 'first_name ASC')
    unless @students.blank?
      @student = @students.first
      collection_dates
      @fee_collection_dates=@fee_collection_dates.uniq
      @finance_fees = FinanceFee.find_all_by_student_id(@student.id)
      @student_fees = @finance_fees.map{|s| s.fee_collection_id}
      @payed_fees=FinanceFee.find(:all,:joins=>"INNER JOIN fee_transactions on fee_transactions.finance_fee_id=finance_fees.id INNER JOIN finance_fee_collections on finance_fee_collections.id=finance_fees.fee_collection_id",:conditions=>"finance_fees.student_id=#{@student.id} ",:select=>"finance_fees.fee_collection_id").map{|s| s.fee_collection_id}
      @payed_fees ||= []
    end
    render :partial => 'batch_student_list'
  end

  def list_fees_for_student
    @student = Student.find_by_id(params[:student])
    collection_dates
    @finance_fees = FinanceFee.find_all_by_student_id(@student.id)
    @student_fees = @finance_fees.map{|s| s.fee_collection_id}
    @payed_fees=FinanceFee.find(:all,:joins=>"INNER JOIN fee_transactions on fee_transactions.finance_fee_id=finance_fees.id INNER JOIN finance_fee_collections on finance_fee_collections.id=finance_fees.fee_collection_id",:conditions=>"finance_fees.student_id=#{@student.id}",:select=>"finance_fees.fee_collection_id").map{|s| s.fee_collection_id}
    # @payed_fees = @finance_fees.map{|s| s.fee_collection_id unless s.transaction_id.nil? }.compact
    @payed_fees ||= []
    render :update do |page|
      page.replace_html 'fees_list', :partial => 'fees_list'
    end
  end
  def collection_dates
    @fee_collection_dates=[]
    @fee_collection_dates+=FinanceFeeCollection.all(:select=>"distinct finance_fee_collections.*",:joins=>"INNER JOIN fee_collection_batches on fee_collection_batches.finance_fee_collection_id=finance_fee_collections.id LEFT OUTER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id INNER JOIN finance_fee_particulars on finance_fee_particulars.finance_fee_category_id=finance_fee_collections.fee_category_id",:conditions=>"(finance_fee_collections.is_deleted=false and (finance_fees.student_id='#{@student.id}' and finance_fees.is_paid=false) or fee_collection_batches.batch_id='#{@student.batch.id}') and ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id='#{@student.batch.id}') or (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id='#{@student.id}') or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id='#{@student.student_category_id}'))")
    @fee_collection_dates+=@fee_collection_date=FinanceFeeCollection.all(:select=>"distinct finance_fee_collections.*",:joins=>"INNER JOIN fee_collection_batches on fee_collection_batches.finance_fee_collection_id=finance_fee_collections.id LEFT OUTER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id INNER JOIN finance_fee_particulars on finance_fee_particulars.finance_fee_category_id=finance_fee_collections.fee_category_id",:conditions=>"(finance_fee_collections.is_deleted=false and (finance_fees.student_id='#{@student.id}' and finance_fees.is_paid=false) ) and finance_fees.student_id='#{@student.id}'")
    @fee_collection_dates.uniq!
  end
end

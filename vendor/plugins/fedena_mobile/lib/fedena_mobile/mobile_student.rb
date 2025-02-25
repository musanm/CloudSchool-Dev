module FedenaMobile
  module MobileStudent

    def self.included(base)
      base.instance_eval do
        before_filter :is_mobile_user?
      end
    end

    def mobile_fee
      @student=Student.find(params[:id])
      @dates = FinanceFeeCollection.find(:all,:joins=>"INNER JOIN fee_collection_batches on fee_collection_batches.finance_fee_collection_id=finance_fee_collections.id INNER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id",:conditions=>"finance_fees.student_id='#{@student.id}'  and finance_fee_collections.is_deleted=#{false} and ((finance_fees.balance > 0 and finance_fees.batch_id<>#{@student.batch_id}) or (finance_fees.batch_id=#{@student.batch_id}) )").uniq
      @page_title=t('fee_status')
      render :layout =>"mobile"
    end

    private

    def is_mobile_user?
      unless FedenaPlugin.can_access_plugin?("fedena_mobile")
        if FedenaMobile::MobileStudent.instance_methods.include?(action_name)
          flash[:notice]=t('flash_msg4')
          redirect_to :controller => 'user', :action => 'dashboard'
        end
      end
    end

  end
end

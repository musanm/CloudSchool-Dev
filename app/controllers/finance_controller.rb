#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class FinanceController < ApplicationController
  before_filter :login_required, :configuration_settings_for_finance
  before_filter :set_precision
  filter_access_to :all
  include LinkPrivilege
  helper_method('link_to', 'link_to_remote', 'link_present')


  def index
    @hr = Configuration.find_by_config_value("HR")
  end

  

  def donation
    @donation = FinanceDonation.new(params[:donation])
    @donation_additional_details = DonationAdditionalDetail.find_all_by_finance_donation_id(@donation.id)
    @additional_fields = DonationAdditionalField.find(:all, :conditions=> "status = true", :order=>"priority ASC")
    if request.post? && @donation.valid?
      @error=false
      mandatory_fields = DonationAdditionalField.find(:all, :conditions=>{:is_mandatory=>true, :status=>true})
      mandatory_fields.each do|m|
        unless params[:donation_additional_details][m.id.to_s.to_sym].present?
          @donation.errors.add_to_base("#{m.name} must contain atleast one selected option.")
          @error=true
        else
          if params[:donation_additional_details][m.id.to_s.to_sym][:additional_info]==""
            @donation.errors.add_to_base("#{m.name} cannot be blank.")
            @error=true
          end
        end
      end
      unless @error==true
        @donation.save
        additional_field_ids_posted = []
        additional_field_ids = @additional_fields.map(&:id)
        if params[:donation_additional_details].present?
          params[:donation_additional_details].each_pair do |k, v|
            addl_info = v['additional_info']
            additional_field_ids_posted << k.to_i
            addl_field = DonationAdditionalField.find_by_id(k)
            if addl_field.input_type == "has_many"
              addl_info = addl_info.join(", ")
            end
            prev_record = DonationAdditionalDetail.find_by_finance_donation_id_and_additional_field_id(params[:id], k)
            unless prev_record.nil?
              unless addl_info.present?
                prev_record.destroy
              else
                prev_record.update_attributes(:additional_info => addl_info)
              end
            else
              addl_detail = DonationAdditionalDetail.new(:finance_donation_id => @donation.id,
                :additional_field_id => k,:additional_info => addl_info)
              addl_detail.save if addl_detail.valid?
            end
          end
        end
        if additional_field_ids.present?
          DonationAdditionalDetail.find_all_by_finance_donation_id_and_additional_field_id(params[:id],(additional_field_ids - additional_field_ids_posted)).each do |additional_info|
            additional_info.destroy unless additional_info.donation_additional_field.is_mandatory == true
          end
        end
        flash[:notice] = "#{t('flash1')}"
        redirect_to :action => 'donation_receipt', :id => @donation.id
      end
    end
  end

  def donation_receipt
    @donation = FinanceDonation.find(params[:id])
    @additional_details = @donation.donation_additional_details.find(:all,:include => [:donation_additional_field],:conditions => ["donation_additional_fields.status = true"],:order => "donation_additional_fields.priority ASC")
    @additional_fields_count = DonationAdditionalField.count(:conditions => "status = true")
  end

  #  def donation_edit
  #    @donation = FinanceDonation.find(params[:id])
  #    @transaction = FinanceTransaction.find(@donation.transaction_id)
  #    @donation_additional_details = DonationAdditionalDetail.find_all_by_finance_donation_id(@donation.id)
  #    @additional_fields = DonationAdditionalField.find(:all, :conditions=> "status = true", :order=>"priority ASC")
  #    if request.post?
  #      @donation.attributes=params[:donation]
  #      if @donation.valid?
  #        @error=false
  #        mandatory_fields = DonationAdditionalField.find(:all, :conditions=>{:is_mandatory=>true, :status=>true})
  #        mandatory_fields.each do|m|
  #          unless params[:donation_additional_details][m.id.to_s.to_sym].present?
  #            @donation.errors.add_to_base("#{m.name} must contain atleast one selected option.")
  #            @error=true
  #          else
  #            if params[:donation_additional_details][m.id.to_s.to_sym][:additional_info]==""
  #              @donation.errors.add_to_base("#{m.name} cannot be blank.")
  #              @error=true
  #            end
  #          end
  #        end
  #        unless @error==true
  #          @donation.save
  #          additional_field_ids_posted = []
  #          additional_field_ids = @additional_fields.map(&:id)
  #          if params[:donation_additional_details].present?
  #            params[:donation_additional_details].each_pair do |k, v|
  #              addl_info = v['additional_info']
  #              additional_field_ids_posted << k.to_i
  #              addl_field = DonationAdditionalField.find_by_id(k)
  #              if addl_field.input_type == "has_many"
  #                addl_info = addl_info.join(", ")
  #              end
  #              prev_record = DonationAdditionalDetail.find_by_finance_donation_id_and_additional_field_id(params[:id], k)
  #              unless prev_record.nil?
  #                unless addl_info.present?
  #                  prev_record.destroy
  #                else
  #                  prev_record.update_attributes(:additional_info => addl_info)
  #                end
  #              else
  #                addl_detail = DonationAdditionalDetail.new(:finance_donation_id => @donation.id,
  #                  :additional_field_id => k,:additional_info => addl_info)
  #                addl_detail.save if addl_detail.valid?
  #              end
  #            end
  #          end
  #          if additional_field_ids.present?
  #            DonationAdditionalDetail.find_all_by_finance_donation_id_and_additional_field_id(params[:id],(additional_field_ids - additional_field_ids_posted)).each do |additional_info|
  #              additional_info.destroy unless additional_info.donation_additional_field.is_mandatory == true
  #            end
  #          end
  #          donor = "#{t('flash15')} #{params[:donation][:donor]}"
  #          FinanceTransaction.update(@transaction.id, :description => params[:donation][:description], :title => donor, :amount => params[:donation][:amount], :transaction_date => @donation.transaction_date)
  #          redirect_to :action => 'donations'
  #          flash[:notice] = "#{t('flash16')}"
  #        end
  #      end
  #    end
  #  end

  def donation_delete
    @donation = FinanceDonation.find(params[:id])
    @transaction = FinanceTransaction.find(@donation.transaction_id)
    if  @transaction.destroy
      redirect_to :action => 'donations'
      flash[:notice] = "#{t('flash25')}"
    end
  end

  def donation_receipt_pdf
    @donation = FinanceDonation.find(params[:id])
    @additional_details = @donation.donation_additional_details.find(:all,:include => [:donation_additional_field],:conditions => ["donation_additional_fields.status = true"],:order => "donation_additional_fields.priority ASC")
    @additional_fields_count = DonationAdditionalField.count(:conditions => "status = true")
    @currency_type = currency
    render :pdf => 'donation_receipt_pdf'

  end

  # def donors
  #   @donations = FinanceDonation.find(:all, :order => 'transaction_date desc')
  # end
  def donations
    @donations=FinanceDonation.paginate( :conditions => {:transaction_date => 1.month.ago.beginning_of_day..Date.today.end_of_day},:per_page => 20, :page => params[:page], :order => 'created_at ASC')
  end
  def donors_list
    unless params[:donors_list].nil?
      @donations=FinanceDonation.paginate(:conditions => {:transaction_date => params[:donors_list][:from].to_date.beginning_of_day..params[:donors_list][:to].to_date.end_of_day}, :per_page => 20, :page => params[:page], :order => 'created_at ASC')
    else
      @donations=FinanceDonation.paginate( :conditions => {:transaction_date => 1.month.ago.beginning_of_day..Date.today.end_of_day},:per_page => 20, :page => params[:page], :order => 'created_at ASC')
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "donors_list", :partial => "donors_list"
      end
    end
  end
  # def donors_list_pdf
  #   unless params[:donors_list].nil?
  #     @donations=FinanceDonation.paginate(:conditions => {:created_at => params[:donors_list][:from].to_date.beginning_of_day..params[:donors_list][:to].to_date.end_of_day}, :per_page => 20, :page => params[:page], :order => 'created_at ASC')
  #   else
  #     @donations=FinanceDonation.paginate( :conditions => {:created_at => 1.month.ago.beginning_of_day..Date.today.end_of_day},:per_page => 20, :page => params[:page], :order => 'created_at ASC')
  #   end
  #   render :pdf => "donors_list_pdf"
  # end
  def change_field_priority_for_donation
    @additional_field = DonationAdditionalField.find(params[:id])
    priority = @additional_field.priority
    @additional_fields = DonationAdditionalField.find(:all, :conditions=>{:status=>true}, :order=> "priority ASC").map{|b| b.priority.to_i}
    position = @additional_fields.index(priority)
    if params[:order]=="up"
      prev_field = DonationAdditionalField.find_by_priority(@additional_fields[position - 1])
    else
      prev_field = DonationAdditionalField.find_by_priority(@additional_fields[position + 1])
    end
    @additional_field.update_attributes(:priority=>prev_field.priority)
    prev_field.update_attributes(:priority=>priority.to_i)
    @additional_field = DonationAdditionalField.new
    @additional_details = DonationAdditionalField.find(:all, :conditions=>{:status=>true},:order=>"priority ASC")
    @inactive_additional_details = DonationAdditionalField.find(:all, :conditions=>{:status=>false},:order=>"priority ASC")
    render(:update) do|page|
      page.replace_html "category-list", :partial=>"additional_fields_for_donation"
    end
  end
  def expense_create
    @finance_transaction = FinanceTransaction.new
    @categories = FinanceTransactionCategory.expense_categories
    if @categories.empty?
      flash[:notice] = "#{t('flash2')}"
    end
    if request.post?
      @finance_transaction = FinanceTransaction.new(params[:finance_transaction])
      if @finance_transaction.save
        flash[:notice] = "#{t('flash3')}"
        redirect_to :action => "expense_create"
      else
        render :action => "expense_create"
      end
    end
  end

  

  def expense_list
  end

  def expense_list_update
    if params[:start_date].to_date > params[:end_date].to_date
      flash[:warn_notice] = "#{t('flash17')}"
      redirect_to :action => 'expense_list'
    end
    @start_date = (params[:start_date]).to_date
    @end_date = (params[:end_date]).to_date
    @expenses = FinanceTransaction.expenses(@start_date, @end_date)
  end

  def expense_list_pdf
    if date_format_check
      @currency_type = currency
      @expenses = FinanceTransaction.expenses(@start_date, @end_date)
      render :pdf => 'expense_list_pdf'
    end
  end

  def income_create
    @finance_transaction = FinanceTransaction.new()
    @categories = FinanceTransactionCategory.income_categories
    if @categories.empty?
      flash[:notice] = "#{t('flash5')}"
    end
    if request.post?
      @finance_transaction = FinanceTransaction.new(params[:finance_transaction])
      if @finance_transaction.save
        flash[:notice] = "#{t('flash6')}"
        redirect_to :action => "income_create"
      else
        render :action => "income_create"
      end
    end
  end

  def monthly_income

  end


  def income_list
  end

  def delete_transaction
    @transaction = FinanceTransaction.find_by_id(params[:id])
    income = @transaction.category.is_income?
    if income
      auto_transactions = FinanceTransaction.find_all_by_master_transaction_id(params[:id])
      auto_transactions.each { |a| a.destroy } unless auto_transactions.nil?
    end
    @transaction.destroy
    flash[:notice]="#{t('flash18')}"
    if income
      redirect_to :action => 'income_list'
    else
      redirect_to :action => 'expense_list'
    end


  end

  def income_list_update
    @start_date = (params[:start_date]).to_date
    @end_date = (params[:end_date]).to_date
    @incomes = FinanceTransaction.incomes(@start_date, @end_date)
  end

  def income_details
    if date_format_check
      if params[:id].present?
        @income_category = FinanceTransactionCategory.find(params[:id])
      end
      @incomes = @income_category.finance_transactions.find(:all, :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'"])

    end
  end

  def income_list_pdf
    if date_format_check
      @currency_type = currency
      @incomes = FinanceTransaction.incomes(@start_date, @end_date)
      render :pdf => 'income_list_pdf', :zoom => 0.68 #, :show_as_html=>true
    end
  end

  def income_details_pdf
    if date_format_check
      @income_category = FinanceTransactionCategory.find(params[:id])
      @incomes = @income_category.finance_transactions.find(:all, :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'"])
      render :pdf => 'income_details_pdf'
    end
  end

  def categories
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false}, :order => 'name asc')
    @fixed_categories = @categories.reject { |c| !c.is_fixed }
    @other_categories = @categories.reject { |c| c.is_fixed }
  end

  def category_new
    @finance_transaction_category = FinanceTransactionCategory.new
  end

  def category_create
    @finance_category = FinanceTransactionCategory.new(params[:finance_category])
    render :update do |page|
      if @finance_category.save
        @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false}, :order => 'name asc')
        @fixed_categories = @categories.reject { |c| !c.is_fixed }
        @other_categories = @categories.reject { |c| c.is_fixed }
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'category-list', :partial => 'category_list'
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg35')}</p>"

      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_category
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  def category_delete
    @finance_category = FinanceTransactionCategory.find(params[:id])
    @finance_category.update_attributes(:deleted => true)
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false}, :order => 'name asc')
    @fixed_categories = @categories.reject { |c| !c.is_fixed }
    @other_categories = @categories.reject { |c| c.is_fixed }
  end

  def category_edit
    @finance_category = FinanceTransactionCategory.find(params[:id])
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false})
  end

  def category_update
    @finance_category = FinanceTransactionCategory.find(params[:id])
    unless  @finance_category.update_attributes(params[:finance_category])
      @errors=true
    end
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false}, :order => 'name asc')
    @fixed_categories = @categories.reject { |c| !c.is_fixed }
    @other_categories = @categories.reject { |c| c.is_fixed }
  end

  

  #transaction-----------------------


  def update_monthly_report

    fixed_category_name
    @hr = Configuration.find_by_config_value("HR")
    if date_format_check
      unless @start_date > @end_date
        @transactions = FinanceTransaction.find(:all, :order => 'transaction_date desc', :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'"])
        @other_transaction_categories = FinanceTransactionCategory.find(:all, :conditions => ["finance_transactions.transaction_date >= '#{@start_date}' and finance_transactions.transaction_date <= '#{@end_date}'and finance_transaction_categories.id NOT IN (#{@fixed_cat_ids.join(",")})"], :joins => [:finance_transactions]).uniq
        @transactions_fees = FinanceTransaction.total_fees(@start_date, @end_date).map { |t| t.transaction_total.to_f }.sum
        @salary = FinanceTransaction.sum('amount', :conditions => {:title => "Monthly Salary", :transaction_date => @start_date..@end_date}).to_f
        @donations_total = FinanceTransaction.donations_triggers(@start_date, @end_date)
        @grand_total = FinanceTransaction.grand_total(@start_date, @end_date)
        @category_transaction_totals = {}
        @expenses = FinanceTransaction.expenses(@start_date, @end_date)
        FedenaPlugin::FINANCE_CATEGORY.each do |category|
          @category_transaction_totals["#{category[:category_name]}"] = FinanceTransaction.total_transaction_amount(category[:category_name], @start_date, @end_date)
        end
        @graph = open_flash_chart_object(960, 500, "graph_for_update_monthly_report?start_date=#{@start_date}&end_date=#{@end_date}")
      else
        flash[:warn_notice] = "#{t('flash17')}"
        redirect_to :action => :monthly_report
      end
    end
  end


  def transaction_pdf
    @data_hash = FinanceTransaction.fetch_finance_transaction_data(params)
    render :pdf => 'transaction_pdf'
  end


  def salary_department
    if date_format_check
      archived_employee_salary=FinanceTransaction.all(:select => "sum(finance_transactions.amount) as amount,employee_departments.id,employee_departments.name", :conditions => {:title => "Monthly Salary", :transaction_date => @start_date..@end_date}, :joins => "INNER JOIN archived_employees on archived_employees.former_id= finance_transactions.payee_id INNER JOIN employee_departments on employee_departments.id= archived_employees.employee_department_id", :group => "employee_departments.id", :order => "employee_departments.name").group_by(&:id)
      employee_salary=FinanceTransaction.all(:select => "sum(finance_transactions.amount) as amount,employee_departments.id,employee_departments.name", :conditions => {:title => "Monthly Salary", :transaction_date => @start_date..@end_date}, :joins => "INNER JOIN employees on employees.id= finance_transactions.payee_id LEFT OUTER JOIN employee_departments on employee_departments.id= employees.employee_department_id", :group => "employee_departments.id", :order => "employee_departments.name").group_by(&:id)
      @departments=EmployeeDepartment.ordered(:select => "id, name")
      @departments.each do |d|
        total=0.0
        total+=archived_employee_salary[d.id].nil? ? 0 : archived_employee_salary[d.id][0].amount.to_f
        total+=employee_salary[d.id].nil? ? 0 : employee_salary[d.id][0].amount.to_f
        d['amount']=total
      end
    end
  end


  def salary_employee
    if date_format_check
      employee_salary=FinanceTransaction.all(:select => "amount,employees.first_name ,employees.middle_name,employees.last_name,employees.id as employee_id ,finance_transactions.id", :conditions => {:title => "Monthly Salary", :transaction_date => @start_date..@end_date, :employees => {:employee_department_id => params[:id]}}, :joins => "INNER JOIN employees on employees.id= finance_transactions.payee_id", :include => :monthly_payslips)
      archived_employee_salary=FinanceTransaction.all(:select => "amount,archived_employees.first_name ,archived_employees.middle_name,archived_employees.last_name,archived_employees.id as employee_id ,finance_transactions.id", :conditions => {:title => "Monthly Salary", :transaction_date => @start_date..@end_date, :archived_employees => {:employee_department_id => params[:id]}}, :joins => "INNER JOIN archived_employees on archived_employees.former_id= finance_transactions.payee_id", :include => :monthly_payslips)
      @employees_salary=archived_employee_salary+employee_salary
      @employees_salary.each { |employee| employee['salary_date']= employee.monthly_payslips.first.salary_date }
      @employees_salary=@employees_salary.sort_by { |salary| salary.salary_date }
      @department = EmployeeDepartment.find(params[:id])
    end
  end

  def employee_payslip_monthly_report
    if date_format(params[:salary_date]).nil?
      flash[:notice]="#{t('bad_request')}"
      return redirect_to :action => :monthly_report
    end
    @employee = Employee.find_in_active_or_archived(params[:employee_id])
    @currency_type = currency
    ft=FinanceTransaction.find(params[:finance_transaction_id])
    @monthly_payslips=MonthlyPayslip.find(:all, :conditions => {:finance_transaction_id => ft.id}, :include => :payroll_category) if ft
    @individual_payslips = IndividualPayslipCategory.find(:all, :conditions => ["employee_id=? AND salary_date = ?", params[:employee_id], params[:salary_date]])
    @salary = Employee.calculate_salary(@monthly_payslips, @individual_payslips)
  end

  def donations_report
    if date_format_check
      category_id = FinanceTransactionCategory.find_by_name("Donation").id
      @donations = FinanceTransaction.find(:all, :order => 'transaction_date desc', :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'and category_id ='#{category_id}'"])
    end

  end

  def fees_report
    month_date
    @batches= FinanceTransaction.total_fees(@start_date, @end_date)
    #fees_id = FinanceTransactionCategory.find_by_name('Fee').id
    #@fee_collections = FinanceFeeCollection.find(:all,:joins=>"INNER JOIN finance_fees ON finance_fees.fee_collection_id = finance_fee_collections.id INNER JOIN finance_transactions ON finance_transactions.finance_id = finance_fees.id AND finance_transactions.transaction_date >= '#{@start_date}' AND finance_transactions.transaction_date <= '#{@end_date}' AND finance_transactions.category_id = #{fees_id}",:group=>"finance_fee_collections.id")

  end

  def batch_fees_report
    month_date
    @fee_collection = FinanceFeeCollection.find(params[:id])
    @batch = Batch.find(params[:batch_id])
    @transaction = FinanceTransaction.find(:all, :joins => "INNER JOIN fee_transactions on fee_transactions.finance_transaction_id=finance_transactions.id INNER JOIN finance_fees on finance_fees.id=fee_transactions.finance_fee_id", :conditions => ["finance_fees.fee_collection_id='#{@fee_collection.id}' and finance_transactions.batch_id='#{@batch.id}' and finance_transactions.transaction_date >= '#{@start_date}' and finance_transactions.transaction_date <= '#{@end_date}'"])
  end

  def student_fees_structure

    month_date
    @student = Student.find(params[:id])
    @components = @student.get_fee_strucure_elements

  end

  # approve montly payslip ----------------------

  def approve_monthly_payslip
    @salary_dates = MonthlyPayslip.find(:all, :select => "distinct salary_date")

  end

  def one_click_approve
    @dates = MonthlyPayslip.find_all_by_salary_date(params[:salary_date], :conditions => ["is_rejected is false and is_approved = false"])
    @salary_date = params[:salary_date]
    render :update do |page|
      page.replace_html "approve", :partial => "one_click_approve"
    end
  end

  def one_click_approve_submit
    dates = MonthlyPayslip.find_all_by_salary_date(Date.parse(params[:date]), :conditions => ["is_rejected is false and is_approved is false"])
    unless dates.blank?
      dates.each do |d|
        d.approve(current_user.id, "Approved")
      end

      emp_ids = dates.map { |date| date.employee_id }.uniq.join(',')
      Delayed::Job.enqueue(PayslipTransactionJob.new(
          :current_user => current_user,
          :salary_date => params[:date],
          :employee_id => emp_ids
        ))

      flash[:notice] = "#{t('flash8')}"
      redirect_to :action => "payslip_index"
    else
      redirect_to :action => "payslip_index"
    end

  end

  def employee_payslip_approve
    dates = MonthlyPayslip.find_all_by_salary_date_and_employee_id(Date.parse(params[:id2]), params[:id], :conditions => ["is_rejected is false and is_approved is false"])
    unless dates.blank?
      dates.each do |d|
        d.approve(current_user.id, params[:payslip_accept][:remark])
      end
      Delayed::Job.enqueue(PayslipTransactionJob.new(
          :current_user => current_user,
          :salary_date => params[:id2],
          :employee_id => params[:id]
        ))
      flash[:notice] = "#{t('flash8')}"
      render :update do |page|
        page.reload
      end
    else
      render :update do |page|
        page.reload
      end
    end
  end

  def employee_payslip_reject
    dates = MonthlyPayslip.find_all_by_salary_date_and_employee_id(Date.parse(params[:id2]), params[:id])
    employee = Employee.find(params[:id])

    dates.each do |d|
      d.reject(current_user.id, params[:payslip_reject][:reason])
    end
    privilege = Privilege.find_by_name("PayslipPowers")
    hr_ids = privilege.user_ids
    subject = "#{t('payslip_rejected')}"
    body = "#{t('payslip_rejected_for')} "+ employee.first_name+" "+ employee.last_name+ " (#{t('employee_number')} : #{employee.employee_number})" +" #{t('for_the_month')} #{params[:id2].to_date.strftime("%B %Y")}"
    Delayed::Job.enqueue(DelayedReminderJob.new(:sender_id => current_user.id,
        :recipient_ids => hr_ids,
        :subject => subject,
        :body => body))
    render :update do |page|
      page.reload
    end
  end

  def employee_payslip_accept_form
    @id1 = params[:id]
    @id2 = params[:id2]
    respond_to do |format|
      format.js { render :action => 'accept' }
    end
  end

  def employee_payslip_reject_form
    @id1 = params[:id]
    @id2 = params[:id2]
    respond_to do |format|
      format.js { render :action => 'reject' }
    end
  end

  #view monthly payslip -------------------------------
  def view_monthly_payslip

    @departments = EmployeeDepartment.active_and_ordered
    @salary_dates = MonthlyPayslip.find(:all, :select => "distinct salary_date")
    if request.post?
      post_data = params[:payslip]
      unless post_data.blank?
        if post_data[:salary_date].present? and post_data[:department_id].present?
          @payslips = MonthlyPayslip.find_and_filter_by_department(post_data[:salary_date], post_data[:department_id])
        else
          flash[:notice] = "#{t('select_salary_date')}"
          redirect_to :action => "view_monthly_payslip"
        end
      end
    end
  end

  def view_monthly_payslip_pdf
    @data_hash = FinanceTransaction.fetch_finance_payslip_data(params)
    @currency_type= currency
    render :pdf => 'view_monthly_payslip_pdf'
  end


  def view_employee_payslip
    @is_present_employee=true
    @is_present_employee=false if (Employee.find_by_id(params[:id]).nil?)
    @monthly_payslips = MonthlyPayslip.find(:all, :conditions => ["employee_id=? AND salary_date = ?", params[:id], params[:salary_date]], :include => :payroll_category)
    @individual_payslips = IndividualPayslipCategory.find(:all, :conditions => ["employee_id=? AND salary_date = ?", params[:id], params[:salary_date]])
    @salary = Employee.calculate_salary(@monthly_payslips, @individual_payslips)
    @currency_type= currency
    if @monthly_payslips.blank?
      flash[:notice] = "No paylips found for this employee"
      redirect_to :controller => "finance", :action => "view_monthly_payslip"
    end
  end


  def search_ajax
    other_conditions = ""
    other_conditions += " AND employee_department_id = '#{params[:employee_department_id]}'" unless params[:employee_department_id] == ""
    other_conditions += " AND employee_category_id = '#{params[:employee_category_id]}'" unless params[:employee_category_id] == ""
    other_conditions += " AND employee_position_id = '#{params[:employee_position_id]}'" unless params[:employee_position_id] == ""
    other_conditions += " AND employee_grade_id = '#{params[:employee_grade_id]}'" unless params[:employee_grade_id] == ""
    if params[:query].length>= 3
      @employee = Employee.find(:all,
        :conditions => ["(first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                       OR employee_number LIKE ? OR (concat(first_name, \" \", last_name) LIKE ?))" + other_conditions,
          "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%",
          "#{params[:query]}", "#{params[:query]}"],
        :order => "first_name asc") unless params[:query] == ''
    else
      @employee = Employee.find(:all,
        :conditions => ["(employee_number LIKE ?)" + other_conditions, "#{params[:query]}%"],
        :order => "first_name asc") unless params[:query] == ''
    end
    render :layout => false
  end

  #asset-liability-----------

  def create_liability
    @liability = Liability.new(params[:liability])
    render :update do |page|
      if @liability.save
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg23')}</p>"
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @liability
        page.visual_effect(:highlight, 'form-errors')
      end
    end

  end

  def edit_liability
    @liability = Liability.find(params[:id])
  end

  def update_liability
    @liability = Liability.find(params[:id])
    @currency_type = currency

    render :update do |page|
      if @liability.update_attributes(params[:liability])
        @liabilities = Liability.find(:all, :conditions => 'is_deleted = 0')
        page.replace_html "liability_list", :partial => "liability_list"
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg24')}</p>"
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @liability
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  def view_liability
    @liabilities = Liability.find(:all, :conditions => 'is_deleted = 0')
    @currency_type = currency
  end

  def liability_pdf
    @liabilities = Liability.find(:all, :conditions => 'is_deleted = 0')
    @currency_type = currency
    render :pdf => 'liability_report_pdf'
  end

  def delete_liability
    @liability = Liability.find(params[:id])
    @liability.update_attributes(:is_deleted => true)
    @liabilities = Liability.find(:all, :conditions => 'is_deleted = 0')
    @currency_type = currency
    render :update do |page|
      page.replace_html "liability_list", :partial => "liability_list"
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg25')}</p>"
    end
  end

  def each_liability_view
    @liability = Liability.find(params[:id])
    @currency_type = currency
  end

  def create_asset
    @asset = Asset.new(params[:asset])
    render :update do |page|
      if @asset.save
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg20')}</p>"

      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @asset
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  def view_asset
    @assets = Asset.find(:all, :conditions => 'is_deleted = 0')
    @currency_type = currency
  end

  def asset_pdf
    @assets = Asset.find(:all, :conditions => 'is_deleted = 0')
    @currency_type = currency
    render :pdf => 'asset_report_pdf'
  end

  def edit_asset
    @asset = Asset.find(params[:id])
  end

  def update_asset
    @asset = Asset.find(params[:id])
    @currency_type = currency

    render :update do |page|
      if @asset.update_attributes(params[:asset])
        @assets = Asset.find(:all, :conditions => 'is_deleted = 0')
        page.replace_html "asset_list", :partial => "asset_list"
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg21')}</p>"
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @asset
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  def delete_asset
    @asset = Asset.find(params[:id])
    @asset.update_attributes(:is_deleted => true)
    @assets = Asset.all(:conditions => 'is_deleted = 0')
    @currency_type = currency
    render :update do |page|
      page.replace_html "asset_list", :partial => "asset_list"
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg22')}</p>"
    end
  end

  def each_asset_view
    @asset = Asset.find(params[:id])
    @currency_type = currency
  end

  #fees ----------------

  def master_fees
    @finance_fee_category = FinanceFeeCategory.new
    @finance_fee_particular = FinanceFeeParticular.new
    @batchs = Batch.active
    @master_categories = FinanceFeeCategory.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = 1 and batch_id=?", params[:batch_id]]) unless params[:batch_id].blank?
    @student_categories = StudentCategory.active
  end

  def master_category_new
    @finance_fee_category = FinanceFeeCategory.new
    @batches = Batch.active
    respond_to do |format|
      format.js { render :action => 'master_category_new' }
    end
  end

  def master_category_create
    if request.post?

      if params[:finance_fee_category][:category_batches_attributes].present?
        FinanceFeeCategory.transaction do
          name=params[:finance_fee_category][:name]
          @finance_fee_category = FinanceFeeCategory.find_or_create_by_name_and_description_and_is_deleted(name, params[:finance_fee_category][:description], false)


          @finance_fee_category.is_master = true
          if @finance_fee_category.update_attributes(params[:finance_fee_category]) and @finance_fee_category.check_name_uniqueness

          else
            @batch_error=true if params[:finance_fee_category][:category_batches_attributes].nil?
            @error = true
            raise ActiveRecord::Rollback
          end
        end
      else
        @batch_error=true
        @finance_fee_category = FinanceFeeCategory.new(params[:finance_fee_category])
        @finance_fee_category.valid?
        @error = true
      end
      @master_categories = FinanceFeeCategory.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = 1"])
      respond_to do |format|
        format.js { render :action => 'master_category_create' }
      end
    end
  end

  def master_category_edit
    @batch=Batch.find(params[:batch_id])
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    respond_to do |format|
      format.js { render :action => 'master_category_edit' }
    end
  end

  def master_category_update
    @batches=Batch.find(params[:batch_id])
    finance_fee_category = FinanceFeeCategory.find(params[:id])
    params[:finance_fee_category][:name]=params[:finance_fee_category][:name]
    if (params[:finance_fee_category][:name]==finance_fee_category.name) and (params[:finance_fee_category][:description]==finance_fee_category.description)
      render :update do |page|
        @master_categories = @batches.finance_fee_categories.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = 1 "])
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'categories', :partial => 'master_category_list'
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg13')}</p>"
        @error=false
      end
    else
      attributes=finance_fee_category.attributes
      attributes.delete_if { |key, value| ["id", "name", "description", "created_at"].include? key }
      #@finance_fee_category=FinanceFeeCategory.new(attributes)
      @error=true
      render :update do |page|
        FinanceFeeCategory.transaction do
          @finance_fee_category=FinanceFeeCategory.find_or_create_by_name_and_description_and_is_deleted(params[:finance_fee_category][:name], params[:finance_fee_category][:description], false)
          if CategoryBatch.find_by_finance_fee_category_id_and_batch_id(@finance_fee_category.id, @batches.id).present?
            @error=true
            @finance_fee_category.errors.add_to_base(t('name_already_taken'))
          else
            if @finance_fee_category.update_attributes(attributes)
              @finance_fee_category.create_associates(finance_fee_category.id, @batches.id)
              cat_batch=CategoryBatch.find_by_finance_fee_category_id_and_batch_id(finance_fee_category.id, @batches.id)
              cat_batch.destroy if cat_batch
              finance_fee_category.update_attributes(:is_deleted => true) unless finance_fee_category.category_batches.present?
              @master_categories = @batches.finance_fee_categories.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = 1 "])

              if @finance_fee_category.check_category_name_exists(@batches)
                page.replace_html 'form-errors', :text => ''
                page << "Modalbox.hide();"
                page.replace_html 'categories', :partial => 'master_category_list'
                page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg13')}</p>"
                @error=false
              else
                @error=true
                @finance_fee_category.errors.add_to_base(t('name_already_taken'))
              end
            end
          end
          if @error
            page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_fee_category

            page.visual_effect(:highlight, 'form-errors')
            raise ActiveRecord::Rollback
          end


        end
      end

    end
  end


  def master_category_particulars
    @batch=Batch.find(params[:batch_id])
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    #categories=FinanceFeeCategory.find(:all,:include=>:category_batches,:conditions=>"name=@finance_fee_category.name and description=@finance_fee_category.description and is_deleted=#{false}").map{|d| d if d.category_batches.empty?}.compact
    #    categories=FinanceFeeCategory.find(:all,:include=>:category_batches,:conditions=>"name='#{@finance_fee_category.name}' and description='#{@finance_fee_category.description}' and is_deleted=#{false}").uniq.map{|d| d if d.batch_id==@batch.id}.compact
    #    if categories.present?
    #      @finance_fee_category = FinanceFeeCategory.find_by_name_and_batch_id_and_is_deleted(@finance_fee_category.name,@batch.id,false)
    #    end
    #@particulars = FinanceFeeParticular.paginate(:page => params[:page],:joins=>"INNER JOIN finance_fee_categories on finance_fee_categories.id=finance_fee_particulars.finance_fee_category_id",:conditions => ["finance_fee_particulars.is_deleted = '#{false}' and finance_fee_categories.name = '#{@finance_fee_category.name}' and finance_fee_categories.description = '#{@finance_fee_category.description}' and finance_fee_particulars.batch_id='#{@batch.id}' "])
    @particulars = FinanceFeeParticular.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@finance_fee_category.id}' and batch_id='#{@batch.id}' "])

  end

  def master_category_particulars_edit
    @finance_fee_particular= FinanceFeeParticular.find(params[:id])
    @student_categories = StudentCategory.active
    unless @finance_fee_particular.student_category.present? and @student_categories.collect(&:name).include?(@finance_fee_particular.student_category.name)
      current_student_category=@finance_fee_particular.student_category
      @student_categories << current_student_category if current_student_category.present?
    end
    respond_to do |format|
      format.js { render :action => 'master_category_particulars_edit' }
    end
  end

  def master_category_particulars_update
    @feeparticulars = FinanceFeeParticular.find(params[:id])
    render :update do |page|
      #params[:finance_fee_particular][:student_category_id]="" if params[:finance_fee_particular][:student_category_id].nil?
      if @feeparticulars.collection_exist
        if @feeparticulars.update_attributes(params[:finance_fee_particular])
          @finance_fee_category = FinanceFeeCategory.find(@feeparticulars.finance_fee_category_id)
          @particulars = FinanceFeeParticular.paginate(:page => params[:page], :conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@finance_fee_category.id}' and batch_id='#{@feeparticulars.batch_id}'"])
          page.replace_html 'form-errors', :text => ''
          page << "Modalbox.hide();"
          page.replace_html 'categories', :partial => 'master_particulars_list'
          page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg14')}</p>"
        else
          page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @feeparticulars
          page.visual_effect(:highlight, 'form-errors')
        end
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @feeparticulars
        page.visual_effect(:highlight, 'form-errors')
      end
    end
    #    respond_to do |format|
    #      format.js { render :action => 'master_category_particulars' }
    #    end
  end

  def master_category_particulars_delete
    @feeparticular = FinanceFeeParticular.find(params[:id])
    @batch=@feeparticular.batch
    #discounts=@feeparticular.finance_fee_category.fee_discounts.all(:conditions=>"batch_id=#{@feeparticular.batch_id}")
    @error=true unless @feeparticular.delete_particular
    @finance_fee_category = FinanceFeeCategory.find(@feeparticular.finance_fee_category_id)
    @particulars = FinanceFeeParticular.paginate(:page => params[:page], :conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@finance_fee_category.id}' and batch_id='#{@feeparticular.batch_id}' "])

  end

  def master_category_delete
    @error=false
    @batches=Batch.find(params[:batch_id])
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @catbatch=CategoryBatch.find_by_finance_fee_category_id_and_batch_id(params[:id], params[:batch_id])
    unless @catbatch.destroy
      @catbatch.errors.add_to_base(t('fee_collection_exists_cant_delete_this_category'))
      @error=true
    end
    @finance_fee_category.update_attributes(:is_deleted => true) unless @finance_fee_category.category_batches.present?
    #@finance_fee_category.delete_particulars
    @master_categories = @batches.finance_fee_categories.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = 1 "])
    respond_to do |format|
      format.js { render :action => 'master_category_delete' }
    end
  end

  def show_master_categories_list
    unless params[:id].empty?
      @finance_fee_category = FinanceFeeCategory.new
      @finance_fee_particular = FinanceFeeParticular.new
      @batches = Batch.find params[:id] unless params[:id] == ""
      @master_categories =@batches.finance_fee_categories.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = 1 "])
      #@master_categories = FinanceFeeCategory.find(:all,:conditions=> ["is_deleted = '#{false}' and is_master = 1 and batch_id=?",params[:id]])
      @student_categories = StudentCategory.active

      render :update do |page|
        page.replace_html 'categories', :partial => 'master_category_list'
      end
    else
      render :update do |page|
        page.replace_html 'categories', :text => ""
      end
    end
  end

  def fees_particulars_new
    @finance_fee_particular =FinanceFeeParticular.new()
    @fees_categories =FinanceFeeCategory.all(:select => "DISTINCT finance_fee_categories.*", :joins => "INNER JOIN category_batches ON category_batches.finance_fee_category_id = finance_fee_categories.id INNER JOIN batches ON batches.id = category_batches.batch_id AND batches.is_active = true AND batches.is_deleted =  false", :conditions => "finance_fee_categories.is_deleted=0 AND finance_fee_categories.is_master=1", :order => "name ASC")
    #@fees_categories = FinanceFeeCategory.find(:all,:group=>'concat(name,description)',:conditions=> "is_deleted = 0 and is_master = 1")
    #@fees_categories.reject!{|f|f.batch.is_deleted or !f.batch.is_active }
    @student_categories = StudentCategory.active
    @all=true
    @student=false
    @category=false
  end

  def list_category_batch
    fee_category=FinanceFeeCategory.find(params[:category_id])
    #@batches= Batch.find(:all,:joins=>"INNER JOIN `category_batches` ON `batches`.id = `category_batches`.batch_id INNER JOIN finance_fee_categories on finance_fee_categories.id=category_batches.finance_fee_category_id INNER JOIN courses on courses.id=batches.course_id",:conditions=>"finance_fee_categories.name = '#{fee_category.name}' and finance_fee_categories.description = '#{fee_category.description}'",:order=>"courses.code ASC")
    @batches=Batch.active.find(:all, :joins => [{:category_batches => :finance_fee_category}, :course], :conditions => "finance_fee_categories.id =#{fee_category.id}", :order => "courses.code ASC").uniq
    #@batches=fee_category.batches.all(:order=>"name ASC")
    render :update do |page|
      page.replace_html 'list-category-batch', :partial => 'list_category_batch'
    end
  end

  def fees_particulars_create
    if request.get?
      redirect_to :action => "fees_particulars_new"
    else
      @finance_category=FinanceFeeCategory.find_by_id(params[:finance_fee_particular][:finance_fee_category_id])
      @batches= Batch.find(:all, :joins => "INNER JOIN `category_batches` ON `batches`.id = `category_batches`.batch_id INNER JOIN finance_fee_categories on finance_fee_categories.id=category_batches.finance_fee_category_id INNER JOIN courses on courses.id=batches.course_id", :conditions => ["finance_fee_categories.name = ? and finance_fee_categories.description = ?", "#{@finance_category.name}", "#{@finance_category.description}"], :order => "courses.code ASC") if  @finance_category
      if params[:particular] and params[:particular][:batch_ids]
        batches=Batch.find(params[:particular][:batch_ids])
        @cat_ids=params[:particular][:batch_ids]
        if params[:particular][:receiver_id].present?
          all_admission_no = admission_no=params[:particular][:receiver_id].split(',')
          all_students = batches.map { |b| b.students.map { |stu| stu.admission_no } }.flatten
          rejected_admission_no = admission_no.select { |adm| !all_students.include? adm }
          unless (rejected_admission_no.empty?)
            @error = true
            @finance_fee_particular = FinanceFeeParticular.new(params[:finance_fee_particular])
            @finance_fee_particular.batch_id=1
            @finance_fee_particular.save
            @finance_fee_particular.errors.add_to_base("#{rejected_admission_no.join(',')} #{t('does_not_belong_to_batch')} #{batches.map { |batch| batch.full_name }.join(',')}")
          end

          selected_admission_no = all_admission_no.select { |adm| all_students.include? adm }
          selected_admission_no.each do |a|
            s = Student.first(:conditions => ["admission_no LIKE BINARY(?)", a])
            if s.nil?
              @error = true
              @finance_fee_particular = FinanceFeeParticular.new(params[:finance_fee_particular])
              @finance_fee_particular.save
              @finance_fee_particular.errors.add_to_base("#{a} #{t('does_not_exist')}")
            end
          end
          unless @error

            selected_admission_no.each do |a|
              s = Student.first(:conditions => ["admission_no LIKE BINARY(?)", a])
              batch=s.batch
              @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
              @finance_fee_particular.receiver_id=s.id
              @error = true unless @finance_fee_particular.save
            end
          end
        else
          batches.each do |batch|
            if params[:finance_fee_particular][:receiver_type]=="Batch"

              @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
              @finance_fee_particular.receiver_id=batch.id
              @error = true unless @finance_fee_particular.save
            elsif params[:finance_fee_particular][:receiver_type]=="StudentCategory"
              @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
              @error = true unless @finance_fee_particular.save
              @finance_fee_particular.errors.add_to_base("#{t('category_cant_be_blank')}") if params[:finance_fee_particular][:receiver_id]==""
            else

              @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
              @error = true unless @finance_fee_particular.save
              @finance_fee_particular.errors.add_to_base("#{t('admission_no_cant_be_blank')}")
            end

          end
        end
      else
        @error=true
        @finance_fee_particular =FinanceFeeParticular.new(params[:finance_fee_particular])
        @finance_fee_particular.save
      end

      if @error
        @fees_categories = FinanceFeeCategory.find(:all, :group => :name, :conditions => "is_deleted = 0 and is_master = 1")
        @student_categories = StudentCategory.active

        @render=true
        if params[:finance_fee_particular][:receiver_type]=="Student"
          @student=true
        elsif params[:finance_fee_particular][:receiver_type]=="StudentCategory"
          @category=true
        else
          @all=true
        end

        render :action => 'fees_particulars_new'
      else
        flash[:notice]="#{t('particulars_created_successfully')}"
        redirect_to :action => "fees_particulars_new"
      end
    end
  end

  def fees_particulars_new2
    @batch=Batch.find(params[:batch_id])
    @fees_category = FinanceFeeCategory.find(params[:category_id])
    @student_categories = StudentCategory.active
    respond_to do |format|
      format.js { render :action => 'fees_particulars_new2' }
    end
  end

  def fees_particulars_create2
    batch=Batch.find(params[:finance_fee_particular][:batch_id])
    if params[:particular] and params[:particular][:receiver_id]

      all_admission_no = admission_no=params[:particular][:receiver_id].split(',')
      all_students = batch.students.map { |stu| stu.admission_no }.flatten
      rejected_admission_no = admission_no.select { |adm| !all_students.include? adm }
      unless (rejected_admission_no.empty?)
        @error = true
        @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
        @finance_fee_particular.save
        @finance_fee_particular.errors.add_to_base("#{rejected_admission_no.join(',')} #{t('does_not_belong_to_batch')} #{batch.full_name}")
      end

      selected_admission_no = all_admission_no.select { |adm| all_students.include? adm }
      selected_admission_no.each do |a|
        s = Student.first(:conditions => ["admission_no LIKE BINARY(?)", a])
        if s.nil?
          @error = true
          @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
          @finance_fee_particular.save
          @finance_fee_particular.errors.add_to_base("#{a} #{t('does_not_exist')}")
        end
      end
      unless @error
        unless selected_admission_no.present?
          @finance_fee_particular=batch.finance_fee_particulars.new(params[:finance_fee_particular])
          @finance_fee_particular.save
          @finance_fee_particular.errors.add_to_base("#{t('admission_no_cant_be_blank')}")
          @error = true
        else
          selected_admission_no.each do |a|
            s = Student.first(:conditions => ["admission_no LIKE BINARY(?)", a])
            @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
            @finance_fee_particular.receiver_id=s.id
            @error = true unless @finance_fee_particular.save
          end
        end
      end
    elsif params[:finance_fee_particular][:receiver_type]=="Batch"

      @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
      @finance_fee_particular.receiver_id=batch.id
      @error = true unless @finance_fee_particular.save
    else
      @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
      @error = true unless @finance_fee_particular.save
      @finance_fee_particular.errors.add_to_base("#{t('category_cant_be_blank')}") if params[:finance_fee_particular][:receiver_id]==""
    end
    @batch=batch
    @finance_fee_category = FinanceFeeCategory.find(params[:finance_fee_particular][:finance_fee_category_id])
    @particulars = FinanceFeeParticular.paginate(:page => params[:page], :conditions => ["is_deleted = '#{false}' and finance_fee_category_id = '#{@finance_fee_category.id}' and batch_id='#{@batch.id}' "])

  end

  def additional_fees_create_form
    @batches = Batch.active
    @student_categories = StudentCategory.active
  end

  def additional_fees_create

    batch = params[:additional_fees][:batch_id] unless params[:additional_fees][:batch_id].nil?
    # batch ||=[]
    @batches = Batch.active
    @user = current_user
    @students = Student.find_all_by_batch_id(batch) unless batch.nil?
    @additional_category = FinanceFeeCategory.new(
      :name => params[:additional_fees][:name],
      :description => params[:additional_fees][:description],
      :batch_id => params[:additional_fees][:batch_id]
    )
    if params[:additional_fees][:due_date].to_date >= params[:additional_fees][:end_date].to_date
      if @additional_category.save && params[:additional_fees][:start_date].strip.length!=0 && params[:additional_fees][:due_date].strip.length!=0 && params[:additional_fees][:end_date].strip.length!=0
        @collection_date = FinanceFeeCollection.create(
          :name => @additional_category.name,
          :start_date => params[:additional_fees][:start_date],
          :end_date => params[:additional_fees][:end_date],
          :due_date => params[:additional_fees][:due_date],
          :batch_id => params[:additional_fees][:batch_id],
          :fee_category_id => @additional_category.id
        )
        body = "<p>#{t('fee_submission_date_for')} "+@additional_category.name+" #{t('has_been_published')} <br />
                               #{t('fees_submiting_date_starts_on')}< br />
                               #{t('start_date')} : "+format_date(@collection_date.start_date)+" <br />"+
          "#{t('end_date')} : "+format_date(@collection_date.end_date)+" <br />"+
          "#{t('due_date')} : "+format_date(@collection_date.due_date)
        subject = "#{t('fees_submission_date')}"
        @due_date = @collection_date.due_date.strftime("%Y-%b-%d") + " 00:00:00"
        unless batch.empty?
          @students.each do |s|
            FinanceFee.create(:student_id => s.id, :fee_collection_id => @collection_date.id)
            Reminder.create(:sender => @user.id, :recipient => s.id, :subject => subject,
              :body => body, :is_read => false, :is_deleted_by_sender => false, :is_deleted_by_recipient => false)
          end
          Event.create(:title => "#{t('fees_due')}", :description => @additional_category.name, :start_date => @due_date.to_datetime, :end_date => @due_date.to_datetime, :is_due => true, :origin => @collection_date)
        else
          @batches.each do |b|
            @students = Student.find_all_by_batch_id(b.id)
            @students.each do |s|
              FinanceFee.create(:student_id => s.id, :fee_collection_id => @collection_date.id)
              Reminder.create(:sender => @user.id, :recipient => s.user.id, :subject => subject,
                :body => body, :is_read => false, :is_deleted_by_sender => false, :is_deleted_by_recipient => false)
            end
          end
          Event.create(:title => "#{t('fees_due')}", :description => @additional_category.name, :start_date => @due_date.to_datetime, :end_date => @due_date.to_datetime, :is_due => true, :origin => @collection_date)
        end
        flash[:notice] = "#{t('flash9')}"
        redirect_to(:action => "add_particulars", :id => @collection_date.id)
      else
        flash[:notice] = "#{t('flash10')}"
        redirect_to :action => "additional_fees_create_form"
      end
    else
      flash[:notice] = "#{t('flash11')}"
      redirect_to :action => "additional_fees_create_form"
    end
  end

  def additional_fees_edit
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @collection_date = FinanceFeeCollection.find_by_fee_category_id(@finance_fee_category.id)
    respond_to do |format|
      format.js { render :action => 'additional_fees_edit' }
    end
    flash[:notice] = "#{t('flash26')}"
  end

  def additional_fees_update
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @collection_date = FinanceFeeCollection.find_by_fee_category_id(@finance_fee_category.id)
    #    render :update do |page|

    if @finance_fee_category.update_attributes(:name => params[:finance_fee_category][:name], :description => params[:finance_fee_category][:description])
      if @collection_date.update_attributes(:start_date => params[:additional_fees][:start_date], :end_date => params[:additional_fees][:end_date], :due_date => params[:additional_fees][:due_date])
        @collection_date.event.update_attributes(:start_date => @collection_date.due_date.to_datetime, :end_date => @collection_date.due_date.to_datetime)
        @additional_categories = FinanceFeeCategory.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = '#{false}' and batch_id = '#{@finance_fee_category.batch_id}'"])
        #        page.replace_html 'form-errors', :text => ''
        #        page << "Modalbox.hide();"
        #        page.replace_html 'particulars', :partial => 'additional_fees_list'
        #        end
      else
        @error = true
      end
    else
      #        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_fee_category
      #        page.visual_effect(:highlight, 'form-errors')
      @error = true
    end
    #    end
  end

  def additional_fees_delete
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @finance_fee_category.update_attributes(:is_deleted => true)
    @finance_fee_collection = FinanceFeeCollection.find_by_fee_category_id(params[:id])
    @finance_fee_collection.update_attributes(:is_deleted => true)
    @finance_fee_category.delete_particulars
    # redirect_to :action => "additional_fees_list"
    @additional_categories = FinanceFeeCategory.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = '#{false}' and batch_id = '#{@finance_fee_category.batch_id}'"])
    respond_to do |format|
      format.js { render :action => 'additional_fees_delete' }
      flash[:notice] = "#{t('flash27')}"
    end
  end

  def add_particulars
    @collection_date = FinanceFeeCollection.find(params[:id])
    @additional_category = FinanceFeeCategory.find(@collection_date.fee_category_id)
    @student_categories = StudentCategory.active
    @finance_fee_particulars = FeeCollectionParticular.new
    @finance_fee_particulars_list = FeeCollectionParticular.find(:all, :conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}'"])
  end

  def add_particulars_new
    @collection_date = FinanceFeeCollection.find(params[:id])
    @additional_category = FinanceFeeCategory.find(@collection_date.fee_category_id)
    @student_categories = StudentCategory.active
    @finance_fee_particulars = FeeCollectionParticular.new
  end

  def add_particulars_create
    @collection_date = FinanceFeeCollection.find(params[:id])
    @additional_category = FinanceFeeCategory.find(@collection_date.fee_category_id)
    @error = false
    unless params[:finance_fee_particulars][:admission_no].nil?
      unless params[:finance_fee_particulars][:admission_no].empty?
        posted_params = params[:finance_fee_particulars]
        admission_no = posted_params[:admission_no].split(",")
        posted_params.delete "admission_no"
        err = ""
        admission_no.each do |a|
          posted_params["admission_no"] = a.to_s
          @finance_fee_particulars = FeeCollectionParticular.new(posted_params)
          @finance_fee_particulars.finance_fee_collection_id = @collection_date.id
          s = Student.first(:conditions => ["admission_no LIKE BINARY(?)", a])
          unless s.nil?
            if (s.batch_id == @collection_date.batch_id) or (@collection_date.batch_id.nil?)
              unless @finance_fee_particulars.save
                @error = true
              end
            else
              @error = true
              err = err + "#{a}#{t('does_not_belong_to_batch')} #{@collection_date.batch.full_name}. <br />"
            end
          else
            @error = true
            err = err + "#{a} #{t('does_not_exist')}<br />"
          end
        end
        @finance_fee_particulars.errors.add(:admission_no, " #{t('invalid')} : <br />" + err) if @error==true
        @finance_fee_particulars_list = FeeCollectionParticular.find(:all, :conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}'"]) unless @error== true
      else
        @error = true
        @finance_fee_particulars = FeeCollectionParticular.new(params[:finance_fee_particulars])
        @finance_fee_particulars.valid?
        @finance_fee_particulars.errors.add(:admission_no, "#{t('is_blank')}")
      end
    else
      @finance_fee_particulars = FeeCollectionParticular.new(params[:finance_fee_particulars])
      @finance_fee_particulars.finance_fee_collection_id = @collection_date.id
      unless @finance_fee_particulars.save
        @error = true
      else
        @finance_fee_particulars_list = FeeCollectionParticular.find(:all, :conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}'"])
      end

    end
  end

  def student_or_student_category
    @student_categories = StudentCategory.active

    select_value = params[:select_value]

    if select_value == "StudentCategory"
      render :update do |page|
        page.replace_html "student", :partial => "student_category_particulars"
      end
    elsif select_value == "Student"
      render :update do |page|
        page.replace_html "student", :partial => "student_admission_particulars"
      end
    elsif select_value == "Batch"
      render :update do |page|
        page.replace_html "student", :text => ""
      end
    end
  end

  def additional_fees_list
    @batchs=Batch.active
    #@additional_categories = FinanceFeeCategory.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and is_master = '#{false}'"])
  end

  def show_additional_fees_list
    @additional_categories = FinanceFeeCategory.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = '#{false}' and batch_id=?", params[:id]])
    render :update do |page|
      page.replace_html 'particulars', :partial => 'additional_fees_list'
    end
  end

  def additional_particulars
    @additional_category = FinanceFeeCategory.find(params[:id])
    @collection_date = FinanceFeeCollection.find_by_fee_category_id(@additional_category.id)
    @particulars = FeeCollectionParticular.find(:all, :conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}' "])
  end

  def add_particulars_edit
    @finance_fee_particulars = FeeCollectionParticular.find(params[:id])
  end

  def add_particulars_update
    @finance_fee_particulars = FeeCollectionParticular.find(params[:id])
    render :update do |page|
      if @finance_fee_particulars.update_attributes(params[:finance_fee_particulars])
        @collection_date = @finance_fee_particulars.finance_fee_collection
        @additional_category =@collection_date.fee_category
        @particulars = FeeCollectionParticular.paginate(:page => params[:page], :conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}' "])
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'particulars', :partial => 'additional_particulars_list'
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg32')}</p>"
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_fee_particulars
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  def add_particulars_delete
    @finance_fee_particulars = FeeCollectionParticular.find(params[:id])
    @finance_fee_particulars.update_attributes(:is_deleted => true)
    @collection_date = @finance_fee_particulars.finance_fee_collection
    @additional_category =@collection_date.fee_category
    @particulars = FeeCollectionParticular.paginate(:page => params[:page], :conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}' "])
    render :update do |page|
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('particulars_deleted_successfully')}</p>"
      page.replace_html 'particulars', :partial => 'additional_particulars_list'
    end
  end

  def fee_collection_batch_update
    fee_collection_batch_update_data
    render :update do |page|
      page.replace_html "batchs", :partial => "fee_collection_batchs"
    end

  end

  def fee_collection_batch_update_data
    if params[:id].present?
      @fee_category=FinanceFeeCategory.find(params[:id])
      @batches=Batch.active.find(:all, :joins => [{:finance_fee_particulars => :finance_fee_category}, :course], :conditions => "finance_fee_categories.id =#{@fee_category.id} and finance_fee_particulars.is_deleted=#{false}", :order => "courses.code ASC").uniq
    end
  end

  def fee_collection_batch_update_for_fee_collection
    fee_collection_batch_update_data
    render :update do |page|
      page.replace_html "batchs", :partial => "fee_collection_batches_for_fee_collection"
    end

  end

  def fee_collection_new
    @fines=Fine.active
    @fee_categories=FinanceFeeCategory.all(:select => "DISTINCT finance_fee_categories.*", :joins => [{:category_batches => :batch}, :fee_particulars], :conditions => "batches.is_active = 1 AND batches.is_deleted = 0 AND finance_fee_categories.is_deleted=0 AND finance_fee_particulars.is_deleted = 0")
    #@fee_categories=FinanceFeeCategory.find(:all,:joins=>"INNER JOIN finance_fee_particulars on finance_fee_particulars.finance_fee_category_id=finance_fee_categories.id AND finance_fee_particulars.is_deleted = 0 INNER JOIN batches on batches.id=finance_fee_particulars.batch_id AND batches.is_active = 1 AND batches.is_deleted = 0 AND finance_fee_categories.is_deleted=0",:group=>'concat(finance_fee_categories.name,finance_fee_categories.description)')
    @finance_fee_collection = FinanceFeeCollection.new
  end

  def fee_collection_create

    @user = current_user
    @fee_categories=FinanceFeeCategory.all(:select => "DISTINCT finance_fee_categories.*", :joins => [{:category_batches => :batch}, :fee_particulars], :conditions => "batches.is_active = 1 AND batches.is_deleted = 0 AND finance_fee_categories.is_deleted=0 AND finance_fee_particulars.is_deleted = 0")
    unless params[:finance_fee_collection].nil?
      fee_category_name = params[:finance_fee_collection][:fee_category_id]
      @fee_category = FinanceFeeCategory.find_all_by_id(fee_category_name, :conditions => ['is_deleted is false'])
    end
    category =[]
    @finance_fee_collection = FinanceFeeCollection.new
    if request.post?

      Delayed::Job.enqueue(DelayedFeeCollectionJob.new(@user, params[:finance_fee_collection], params[:fee_collection]))
      # @finance_fee_collection.bank_due_date =  params["finance_fee_collection"]["bank_due_date"]
      # @finance_fee_collection.save
      
      flash[:notice]="Collection is in queue. <a href='/scheduled_jobs/FinanceFeeCollection/1'>Click Here</a> to view the scheduled job."
      #flash[:notice] = t('flash_msg33')

    end
    redirect_to :action => 'fee_collection_new'
  end

  def fee_collection_view
    @batchs = Batch.active
  end

  def fee_collection_dates_batch
    if params[:id].present?
      @batch= Batch.find(params[:id])
      @finance_fee_collections = @batch.finance_fee_collections
      render :update do |page|
        page.replace_html 'fee_collection_dates', :partial => 'fee_collection_dates_batch'
      end
    else
      render :update do |page|
        page.replace_html 'fee_collection_dates', :text => ''
      end
    end
  end

  def fee_collection_edit
    @finance_fee_collection = FinanceFeeCollection.find params[:id]
    @batch=Batch.find(params[:batch_id])
  end


  def fee_collection_update
    @batch=Batch.find(params[:batch_id])
    @user = current_user
    finance_fee_collection = FinanceFeeCollection.find params[:id]
    @old_collection=finance_fee_collection
    attributes=finance_fee_collection.attributes
    attributes.delete_if { |key, value| ["id", "name", "start_date", "end_date", "due_date", "created_at"].include? key }
    @finance_fee_collection=FinanceFeeCollection.new(attributes)
    @error=true
    events = @finance_fee_collection.event
    @students=Student.find(:all, :joins => "INNER JOIN finance_fees on finance_fees.student_id=students.id", :conditions => "students.batch_id=#{@batch.id} and finance_fees.fee_collection_id=#{finance_fee_collection.id} and students.has_paid_fees=0 and students.has_paid_fees_for_batch=0")
    render :update do |page|
      FinanceFeeCollection.transaction do
        # if params[:finance_fee_collection][:due_date].to_date >= params[:finance_fee_collection][:end_date].to_date
        # finance_fee_collection.delete_collection(@batch.id)
        @old_collection.attributes=params[:finance_fee_collection]
        unless (@old_collection.changed?)
          @error=false
        else

          if @finance_fee_collection.update_attributes(params[:finance_fee_collection])
            if @old_collection.event
              new_event=@old_collection.event
              new_event.description=@finance_fee_collection.name
              new_event.start_date=@finance_fee_collection.due_date.to_datetime
              new_event.end_date=@finance_fee_collection.due_date.to_datetime
              new_event.origin=@finance_fee_collection
              new_event.save
            end
            # new_event = Event.create(:title => "Fees Due", :description => @finance_fee_collection.name, :start_date => @finance_fee_collection.due_date.to_datetime, :end_date => @finance_fee_collection.due_date.to_datetime, :is_due => true, :origin => @finance_fee_collection)
            # BatchEvent.create(:event_id => new_event.id, :batch_id => @batch.id)
            fee_collection_batch=FeeCollectionBatch.find(:first, :conditions => "finance_fee_collection_id='#{@old_collection.id}' and batch_id='#{@batch.id}'")
            if fee_collection_batch.present?
              fee_collection_batch.finance_fee_collection_id=@finance_fee_collection.id
              fee_collection_batch.save
            end
            CollectionDiscount.find(:all, :joins => [:finance_fee_collection, :fee_discount], :conditions => "fee_discounts.batch_id='#{@batch.id}' and finance_fee_collections.id='#{@old_collection.id}'").each do |cd|
              collection_discount_attributes=cd.attributes
              collection_discount_attributes.delete 'id'
              collection_discount=CollectionDiscount.new(collection_discount_attributes)
              collection_discount.finance_fee_collection_id=@finance_fee_collection.id
              collection_discount.save
              cd.destroy
            end

            CollectionParticular.find(:all, :joins => [:finance_fee_collection, :finance_fee_particular], :conditions => "finance_fee_particulars.batch_id='#{@batch.id}' and finance_fee_collections.id='#{@old_collection.id}'").each do |cp|
              collection_particular_attributes=cp.attributes
              collection_particular_attributes.delete 'id'
              collection_particular=CollectionParticular.new(collection_particular_attributes)
              collection_particular.finance_fee_collection_id=@finance_fee_collection.id
              collection_particular.save
              cp.destroy
            end
            if @old_collection.batches.empty?
              @old_collection.update_attributes(:is_deleted => true)
            end
            # FeeCollectionBatch.create(:finance_fee_collection_id => @finance_fee_collection.id, :batch_id => @batch.id)
            @error=false
            # events.update_attributes(:start_date => @finance_fee_collection.due_date.to_datetime, :end_date => @finance_fee_collection.due_date.to_datetime, :description => params[:finance_fee_collection][:name]) unless events.blank?
            fee_category_name = @finance_fee_collection.fee_category.name
            subject = "#{t('fees_submission_date')}"
            body = "<p><b>#{t('fee_submission_date_for')} <i>"+fee_category_name+"</i> #{t('has_been_updated')}</b> <br /><br/>
                                #{t('start_date')} : "+format_date(@finance_fee_collection.start_date)+"<br />"+
              " #{t('end_date')} : "+format_date(@finance_fee_collection.end_date)+" <br />"+
              " #{t('due_date')} : "+format_date(@finance_fee_collection.due_date)+" <br /><br /><br />"+
              " #{t('check_your')} #{t('fee_structure')} <br/><br/><br/> "
            recipient_ids = []
            FinanceFee.destroy_all("batch_id='#{params[:batch_id]}' and fee_collection_id='#{@old_collection.id}'")
            @students.each do |s|

              unless s.has_paid_fees
                FinanceFee.new_student_fee(@finance_fee_collection, s)
                recipient_ids << s.user.id if s.user
              end
            end

            Delayed::Job.enqueue(DelayedReminderJob.new(:sender_id => @user.id,
                :recipient_ids => recipient_ids,
                :subject => subject,
                :body => body))

          else
            raise ActiveRecord::Rollback

          end

        end
        #      else
        #        page.replace_html 'form-errors', :text => "<div id='error-box'><ul><li>#{t('flash_msg15')} .</li></ul></div>"
        #        flash[:notice]=""
        #
        #      end
      end
      if @error
        page.replace_html 'modal-box', :partial => 'fee_collection_edit', :object => finance_fee_collection
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_fee_collection
        page.visual_effect(:highlight, 'form-errors')
      else
        @finance_fee_collections = @batch.finance_fee_collections.find(:all, :conditions => ["is_deleted = '#{false}'"])
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'fee_collection_dates', :partial => 'fee_collection_list'
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('finance.flash12')}</p>"
      end
    end
    @finance_fee_collections = @batch.finance_fee_collections.find(:all, :conditions => ["is_deleted = '#{false}'"])
  end

  def fee_collection_delete
    @batch=Batch.find(params[:batch_id])
    @finance_fee_collection = FinanceFeeCollection.find params[:id]
    @finance_fee_collection.delete_collection(@batch.id)
    @finance_fee_collections = @batch.finance_fee_collections.find(:all, :conditions => ["is_deleted = '#{false}'"])
  end

  #fees_submission-----------------------------------

  def fees_submission_batch
    @batches = Batch.find(:all, :conditions => {:is_deleted => false, :is_active => true}, :joins => :course, :select => "`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name", :order => "course_full_name")
    @inactive_batches = Batch.find(:all, :conditions => {:is_deleted => false, :is_active => false}, :joins => :course, :select => "`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name", :order => "course_full_name")
    @dates = []
  end

  def update_fees_collection_dates

    @batch = Batch.find(params[:batch_id])
    #   @dates = @batch.finance_fee_collections
    master_fee_collections="SELECT distinct finance_fee_collections.name as name,finance_fee_collections.id as id,'load_fees_submission_batch' as action,'finance' as controller ,'Master Fees' as fee_type FROM `finance_fee_collections` inner join finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id inner join collection_particulars on collection_particulars.finance_fee_collection_id=finance_fees.fee_collection_id inner join finance_fee_particulars on finance_fee_particulars.id=collection_particulars.finance_fee_particular_id WHERE (finance_fees.batch_id=#{@batch.id} and finance_fee_collections.is_deleted=false and finance_fee_particulars.batch_id=#{@batch.id} and ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=finance_fees.batch_id) or (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id=finance_fees.student_id) or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id=finance_fees.student_category_id)))"
    (FedenaPlugin.can_access_plugin?("fedena_transport") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "TransportAdmin"))? transport_fee_collections="UNION ALL(SELECT distinct `transport_fee_collections`.name as name,`transport_fee_collections`.id as id,'transport_fee_collection_details' as action,'transport_fee' as controller,'Transport Fees' as fee_type FROM `transport_fee_collections` INNER JOIN transport_fees on transport_fees.transport_fee_collection_id =transport_fee_collections.id INNER JOIN students on transport_fees.receiver_id=students.id and transport_fees.receiver_type='Student' INNER JOIN batches on students.batch_id=batches.id WHERE (batches.id=#{@batch.id} and transport_fee_collections.is_deleted=0 and transport_fees.transaction_id IS NULL and transport_fees.bus_fare > 0.0) GROUP BY transport_fee_collections.id)" : transport_fee_collections=''
    (FedenaPlugin.can_access_plugin?("fedena_hostel") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "HostelAdmin"))? hostel_fee_collections="UNION ALL(SELECT distinct hostel_fee_collections.name as name,hostel_fee_collections.id as id,'hostel_fee_collection_details' as action,'hostel_fee' as controller,'Hostel Fees' as fee_type FROM `hostel_fee_collections` INNER JOIN `hostel_fees` ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id INNER JOIN `students` ON `students`.id = `hostel_fees`.student_id WHERE (students.batch_id=#{@batch.id} and hostel_fees.is_active=1 and hostel_fee_collections.is_deleted=false))": hostel_fee_collections=''
    @dates = FinanceFeeCollection.find_by_sql("#{master_fee_collections} #{transport_fee_collections} #{hostel_fee_collections}").group_by(&:fee_type)
    render :update do |page|
      page.replace_html "fees_collection_dates", :partial => "fees_collection_dates"
    end
  end

  def load_fees_submission_batch

    @batch = Batch.find(params[:batch_id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @students=Student.find(:all, :joins => "inner join finance_fees on finance_fees.student_id=students.id and finance_fees.batch_id=#{@batch.id} inner join collection_particulars on collection_particulars.finance_fee_collection_id=finance_fees.fee_collection_id inner join finance_fee_particulars on finance_fee_particulars.id=collection_particulars.finance_fee_particular_id", :conditions => "finance_fees.fee_collection_id='#{@date.id}' and finance_fee_particulars.batch_id='#{@batch.id}' and ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=finance_fees.batch_id) or (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id=finance_fees.student_id) or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id=finance_fees.student_category_id))").uniq
    student_ids=@students.collect(&:id).join(',')

    @dates = @batch.finance_fee_collections
    @target_action='load_fees_submission_batch'
    @target_controller='finance'

    if params[:student]
      @student = Student.find(params[:student])
      @fee = FinanceFee.first(:conditions => "fee_collection_id = #{@date.id}", :joins => "INNER JOIN students ON finance_fees.student_id = '#{@student.id}'")
    else
      @fee = FinanceFee.first(:conditions => "fee_collection_id = #{@date.id} and FIND_IN_SET(students.id,'#{ student_ids}')", :joins => 'INNER JOIN students ON finance_fees.student_id = students.id')
    end
    unless @fee.nil?

      @student ||= @fee.student
      @prev_student = @student.previous_fee_student(@date.id, student_ids)
      @next_student = @student.next_fee_student(@date.id, student_ids)
      @financefee = @student.finance_fee_by_date @date
      @due_date = @fee_collection.due_date
      @paid_fees = @fee.finance_transactions
      @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted = false"])
      particular_and_discount_details
      bal=(@total_payable-@total_discount).to_f
      days=(Date.today-@date.due_date.to_date).to_i
      auto_fine=@date.fine
      if days > 0 and auto_fine
        @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule

        if @fine_rule and @financefee.balance==0
          @fine_amount=@fine_amount-@paid_fees.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
        end
      end
      @fine_amount=0 if @financefee.is_paid
      render :update do |page|
        page.replace_html "fees_detail", :partial => "student_fees_submission"
        page.replace_html "show_cat_name", :text => @fee_category.name
      end
    else
      render :update do |page|
        page.replace_html "fees_detail", :text => '<p class="flash-msg">No students have been assigned this fee.</p>'
      end
    end
  end

  def update_ajax
    @target_action='load_fees_submission_batch'
    @target_controller='finance'
    @batch = Batch.find(params[:batch_id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @students=Student.find(:all, :joins => "inner join finance_fees on finance_fees.student_id=students.id and finance_fees.batch_id=#{@batch.id} inner join collection_particulars on collection_particulars.finance_fee_collection_id=finance_fees.fee_collection_id inner join finance_fee_particulars on finance_fee_particulars.id=collection_particulars.finance_fee_particular_id", :conditions => "finance_fees.fee_collection_id='#{@date.id}' and finance_fee_particulars.batch_id='#{@batch.id}' and ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=finance_fees.batch_id) or (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id=finance_fees.student_id) or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id=finance_fees.student_category_id))").uniq
    student_ids=@students.collect(&:id).join(',')
    @dates = @batch.finance_fee_collections
    @student = Student.find(params[:student]) if params[:student]
    @student ||= FinanceFee.first(:conditions => "fee_collection_id = #{@date.id}", :joins => 'INNER JOIN students ON finance_fees.student_id = students.id').student
    @prev_student = @student.previous_fee_student(@date.id, student_ids)
    @next_student = @student.next_fee_student(@date.id, student_ids)
    @due_date = @fee_collection.due_date
    total_fees =0

    @financefee = @student.finance_fee_by_date @date

    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    particular_and_discount_details
    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule

    end


    total_fees =@financefee.balance.to_f+params[:special_fine].to_f

    unless params[:fine].nil?
      unless @financefee.is_paid == true
        total_fees += params[:fine].to_f
      else
        total_fees = params[:fine].to_f
      end
    end
    unless params[:fees][:fees_paid].to_f <= 0
      unless params[:fees][:payment_mode].blank?
        unless FedenaPrecision.set_and_modify_precision(params[:fees][:fees_paid]).to_f > FedenaPrecision.set_and_modify_precision(total_fees).to_f
          transaction = FinanceTransaction.new
          (@financefee.balance.to_f > params[:fees][:fees_paid].to_f) ? transaction.title = "#{t('receipt_no')}. (#{t('partial')}) F#{@financefee.id}" : transaction.title = "#{t('receipt_no')}. F#{@financefee.id}"
          transaction.category = FinanceTransactionCategory.find_by_name("Fee")
          transaction.payee = @student
          transaction.amount = params[:fees][:fees_paid].to_f
          transaction.fine_amount = params[:fine].to_f
          transaction.fine_included = true unless params[:fine].nil?
          if params[:special_fine] and FedenaPrecision.set_and_modify_precision(total_fees)==params[:fees][:fees_paid]
            # transaction.fine_amount = params[:fine].to_f
            # transaction.fine_included = true
            @fine_amount=0
          end
          transaction.finance = @financefee
          transaction.transaction_date=params[:transaction_date]
          transaction.payment_mode = params[:fees][:payment_mode]
          transaction.payment_note = params[:fees][:payment_note]
          transaction.save

          # is_paid =@financefee.balance==0 ? true : false
          # @financefee.update_attributes(:is_paid => is_paid)

          @paid_fees = @financefee.finance_transactions
        else
          @paid_fees = @financefee.finance_transactions
          @financefee.errors.add_to_base("#{t('flash19')}")
        end
      else
        @paid_fees = @financefee.finance_transactions
        @financefee.errors.add_to_base("#{t('select_one_payment_mode')}")
      end
    else
      @paid_fees = @financefee.finance_transactions
      @financefee.errors.add_to_base("#{t('flash23')}")
    end
    if @fine_rule and @financefee.balance==0
      @fine_amount=@fine_amount-@paid_fees.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
    end
    @financefee.reload
    render :update do |page|
      page.replace_html "fees_detail", :partial => "student_fees_submission"

    end

  end

  def student_fee_receipt_pdf
    @batch=Batch.find(params[:batch_id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:id2])
    @student = Student.find(params[:id])
    @financefee = @student.finance_fee_by_date @date
    @due_date = @fee_collection.due_date

    @paid_fees = @financefee.finance_transactions
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted = false"])
    @currency_type = currency
    particular_and_discount_details
    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule

      if @fine_rule and @financefee.balance==0
        @fine_amount=@fine_amount-@paid_fees.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
      end
    end
    @fine_amount=0 if @financefee.is_paid

    render :pdf => 'student_fee_receipt_pdf'

    #        respond_to do |format|
    #            format.pdf { render :layout => false }
    #        end

  end

  def fee_report
    @batches = Batch.find(:all, :conditions => {:is_deleted => false, :is_active => true}, :joins => :course, :select => "`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name", :order => "course_full_name")
    @inactive_batches = Batch.find(:all, :conditions => {:is_deleted => false, :is_active => false}, :joins => :course, :select => "`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name", :order => "course_full_name")
    @dates = []
    @batch = Batch.find(params["finance"]["batch_id"]) if params[:finance] && params[:finance][:batch_id].present?
    
    parameters={:sort_order => params[:sort_order]}
    sort_order=parameters[:sort_order]||nil
    @s=Student.all(:select=>'students.roll_number,students.id,students.admission_no,students.first_name,students.middle_name,students.last_name,students.batch_id,sum(balance) balance,count(IF(balance>0,balance,NULL)) fee_collections_count',:joins=>"INNER JOIN #{derived_sql_table} finance on finance.student_id=students.id",:group=>'students.id',:include=>{:batch=>:course},:order=>sort_order)
    
    if @batch.present?
      @date = @batch.finance_fee_collections.last
      @student = @batch.students.last
      @financefee = @student.finance_fee_by_date @date
    end
  end

def finance_fee_report_pdf
    @batch = Batch.find(params[:batch])
    if @batch.present?
      @date = @batch.finance_fee_collections.last
      @student = @batch.students.last
      @financefee = @student.finance_fee_by_date @date
    end 
    render :pdf => 'finance_fee_report_pdf',
      :zoom => 0.68,:orientation => :landscape
  end
  
  # student vertical PDF
  def new_student_fee_receipt_pdf
    parameters={:sort_order => params[:sort_order]}
    sort_order=parameters[:sort_order]||nil
    @s=Student.all(:select=>'students.roll_number,students.id,students.admission_no,students.first_name,students.middle_name,students.last_name,students.batch_id,sum(balance) balance,count(IF(balance>0,balance,NULL)) fee_collections_count',:joins=>"INNER JOIN #{derived_sql_table} finance on finance.student_id=students.id",:group=>'students.id',:include=>{:batch=>:course},:order=>sort_order)
    
    @batch=Batch.find(params[:batch_id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:id2])
    @student = Student.find(params[:id])
    @financefee = @student.finance_fee_by_date @date
    @due_date = @fee_collection.due_date
    @bank_due_date = @fee_collection.bank_due_date
    @paid_fees = @financefee.finance_transactions
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted = false"])
    @currency_type = currency
    particular_and_discount_details
    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule

      if @fine_rule and @financefee.balance==0
        @fine_amount=@fine_amount-@paid_fees.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
      end
    end
    @fine_amount=0 if @financefee.is_paid


    master_fees_sql="SELECT distinct finance_fee_collections.name as collection_name,finance_fees.is_paid,finance_fees.balance,finance_fees.id as id,'FinanceFee' as fee_type,(finance_fees.balance+(select ifnull(sum(finance_transactions.amount-finance_transactions.fine_amount),0) from finance_transactions where finance_transactions.finance_id=finance_fees.id and finance_transactions.finance_type='FinanceFee')) as actual_amount,(select(fr.fine_amount) from fine_rules fr where fr.id=max(fine_rules.id)) as fine_amount,fine_rules.is_amount FROM `finance_fees` INNER JOIN `finance_fee_collections` ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id INNER JOIN `fee_collection_batches` ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN `collection_particulars` ON (`finance_fee_collections`.`id` = `collection_particulars`.`finance_fee_collection_id`) INNER JOIN `finance_fee_particulars` ON (`finance_fee_particulars`.`id` = `collection_particulars`.`finance_fee_particular_id`) LEFT JOIN `fines` ON `fines`.id = `finance_fee_collections`.fine_id AND fines.is_deleted is false LEFT JOIN `fine_rules` ON fine_rules.fine_id = fines.id and fine_days <= DATEDIFF(CURDATE(),finance_fee_collections.due_date) "
    (FedenaPlugin.can_access_plugin?("fedena_hostel") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "HostelAdmin"))? hostel_fees_sql="UNION ALL (SELECT fc.name as collection_name,if(hf.finance_transaction_id is null,false,true) is_paid,if(hf.finance_transaction_id is null,hf.rent,0) balance,hf.id as id,'HostelFee' as fee_type,hf.rent actual_amount,0 fine_amount,0 is_amount FROM `hostel_fees` hf INNER JOIN `hostel_fee_collections` fc ON `fc`.id = `hf`.hostel_fee_collection_id and fc.is_deleted=0 and hf.student_id='#{@student.id}')" : hostel_fees_sql=''
    (FedenaPlugin.can_access_plugin?("fedena_transport") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "TransportAdmin"))? transport_fees_sql="UNION ALL (SELECT tc.name as collection_name,if(tf.transaction_id is null,false,true) is_paid,if(tf.transaction_id is null,tf.bus_fare,0) balance,tf.id as id,'TransportFee' as fee_type,tf.bus_fare actual_amount,0 fine_amount,0 is_amount FROM `transport_fees` tf INNER JOIN `transport_fee_collections` tc ON `tc`.id = `tf`.transport_fee_collection_id and tc.is_deleted=0 and tf.receiver_id='#{@student.id}' and tf.receiver_type='Student')" : transport_fees_sql=''
    @finance_fees=FinanceFee.find_by_sql("#{master_fees_sql} WHERE (finance_fees.student_id=#{@student.id} and finance_fee_collections.is_deleted=0 and ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=finance_fees.batch_id) or (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id=finance_fees.student_id) or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id=finance_fees.student_category_id))) GROUP BY finance_fees.id  #{transport_fees_sql}  #{hostel_fees_sql}")

    render :pdf => 'student_fee_receipt_pdf',
      :zoom => 0.68,#,:orientation => :landscape,
      :margin => {    :top=> 2,
                :bottom => 2,
                :left=> 2,
                :right => 2},
      :layout => false
  end

  # horizontal batch reciept
  def batch_fee_receipt_horizontal_pdf
    parameters={:sort_order => params[:sort_order]}
    sort_order=parameters[:sort_order]||nil
    @s=Student.all(:select=>'students.roll_number,students.id,students.admission_no,students.first_name,students.middle_name,students.last_name,students.batch_id,sum(balance) balance,count(IF(balance>0,balance,NULL)) fee_collections_count',:joins=>"INNER JOIN #{derived_sql_table} finance on finance.student_id=students.id",:group=>'students.id',:include=>{:batch=>:course},:order=>sort_order)
    
    @batch=Batch.find(params[:batch_id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:id2])
    @student = Student.find(params[:id])
    @financefee = @student.finance_fee_by_date @date
    @due_date = @fee_collection.due_date

    @paid_fees = @financefee.finance_transactions
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted = false"])
    @currency_type = currency
    particular_and_discount_details
    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule

      if @fine_rule and @financefee.balance==0
        @fine_amount=@fine_amount-@paid_fees.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
      end
    end
    @fine_amount=0 if @financefee.is_paid

    render :pdf => 'batch_fee_receipt_horizontal_pdf',
      :zoom => 0.68,:orientation => :landscape,
      :margin => {    :top=> 5,
                :bottom => 00,
                :left=> 2,
                :right => 2},
      :layout => false
  end

  def student_fee_invoice_receipt_pdf
    parameters={:sort_order => params[:sort_order]}
    sort_order=parameters[:sort_order]||nil
    @s=Student.all(:select=>'students.roll_number,students.id,students.admission_no,students.first_name,students.middle_name,students.last_name,students.batch_id,sum(balance) balance,count(IF(balance>0,balance,NULL)) fee_collections_count',:joins=>"INNER JOIN #{derived_sql_table} finance on finance.student_id=students.id",:group=>'students.id',:include=>{:batch=>:course},:order=>sort_order)
    
    @batch=Batch.find(params[:batch_id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:id2])
    @student = Student.find(params[:id])
    @financefee = @student.finance_fee_by_date @date
    @due_date = @fee_collection.due_date
    @bank_due_date = @fee_collection.bank_due_date
    @paid_fees = @financefee.finance_transactions
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted = false"])
    @currency_type = currency
    particular_and_discount_details
    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule

      if @fine_rule and @financefee.balance==0
        @fine_amount=@fine_amount-@paid_fees.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
      end
    end
    @fine_amount=0 if @financefee.is_paid


    master_fees_sql="SELECT distinct finance_fee_collections.name as collection_name,finance_fees.is_paid,finance_fees.balance,finance_fees.id as id,'FinanceFee' as fee_type,(finance_fees.balance+(select ifnull(sum(finance_transactions.amount-finance_transactions.fine_amount),0) from finance_transactions where finance_transactions.finance_id=finance_fees.id and finance_transactions.finance_type='FinanceFee')) as actual_amount,(select(fr.fine_amount) from fine_rules fr where fr.id=max(fine_rules.id)) as fine_amount,fine_rules.is_amount FROM `finance_fees` INNER JOIN `finance_fee_collections` ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id INNER JOIN `fee_collection_batches` ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN `collection_particulars` ON (`finance_fee_collections`.`id` = `collection_particulars`.`finance_fee_collection_id`) INNER JOIN `finance_fee_particulars` ON (`finance_fee_particulars`.`id` = `collection_particulars`.`finance_fee_particular_id`) LEFT JOIN `fines` ON `fines`.id = `finance_fee_collections`.fine_id AND fines.is_deleted is false LEFT JOIN `fine_rules` ON fine_rules.fine_id = fines.id and fine_days <= DATEDIFF(CURDATE(),finance_fee_collections.due_date) "
    (FedenaPlugin.can_access_plugin?("fedena_hostel") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "HostelAdmin"))? hostel_fees_sql="UNION ALL (SELECT fc.name as collection_name,if(hf.finance_transaction_id is null,false,true) is_paid,if(hf.finance_transaction_id is null,hf.rent,0) balance,hf.id as id,'HostelFee' as fee_type,hf.rent actual_amount,0 fine_amount,0 is_amount FROM `hostel_fees` hf INNER JOIN `hostel_fee_collections` fc ON `fc`.id = `hf`.hostel_fee_collection_id and fc.is_deleted=0 and hf.student_id='#{@student.id}')" : hostel_fees_sql=''
    (FedenaPlugin.can_access_plugin?("fedena_transport") and (@current_user.admin? or @current_user.privileges.collect(&:name).include? "TransportAdmin"))? transport_fees_sql="UNION ALL (SELECT tc.name as collection_name,if(tf.transaction_id is null,false,true) is_paid,if(tf.transaction_id is null,tf.bus_fare,0) balance,tf.id as id,'TransportFee' as fee_type,tf.bus_fare actual_amount,0 fine_amount,0 is_amount FROM `transport_fees` tf INNER JOIN `transport_fee_collections` tc ON `tc`.id = `tf`.transport_fee_collection_id and tc.is_deleted=0 and tf.receiver_id='#{@student.id}' and tf.receiver_type='Student')" : transport_fees_sql=''
    @finance_fees=FinanceFee.find_by_sql("#{master_fees_sql} WHERE (finance_fees.student_id=#{@student.id} and finance_fee_collections.is_deleted=0 and ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=finance_fees.batch_id) or (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id=finance_fees.student_id) or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id=finance_fees.student_category_id))) GROUP BY finance_fees.id  #{transport_fees_sql}  #{hostel_fees_sql}")

    render :pdf => 'student_fee_receipt_pdf',
      :zoom => 0.68,:orientation => :landscape,
      :margin => {    :top=> 5,
                :bottom => 0,
                :left=> 2,
                :right => 2},
      :layout => false
  end

  # Batch vertical PDF
  def new_batch_fee_receipt_pdf
    parameters={:sort_order => params[:sort_order]}
    sort_order=parameters[:sort_order]||nil
    @s=Student.all(:select=>'students.roll_number,students.id,students.admission_no,students.first_name,students.middle_name,students.last_name,students.batch_id,sum(balance) balance,count(IF(balance>0,balance,NULL)) fee_collections_count',:joins=>"INNER JOIN #{derived_sql_table} finance on finance.student_id=students.id",:group=>'students.id',:include=>{:batch=>:course},:order=>sort_order)
    
    @batch=Batch.find(params[:batch_id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:id2])
    @student = Student.find(params[:id])
    @financefee = @student.finance_fee_by_date @date
    @due_date = @fee_collection.due_date

    @paid_fees = @financefee.finance_transactions
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted = false"])
    @currency_type = currency
    particular_and_discount_details
    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule

      if @fine_rule and @financefee.balance==0
        @fine_amount=@fine_amount-@paid_fees.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
      end
    end
    @fine_amount=0 if @financefee.is_paid

    render :pdf => 'student_fee_receipt_pdf',
      :zoom => 0.68,#,:orientation => :landscape,
      :margin => {    :top=> 2,
                :bottom => 2,
                :left=> 2,
                :right => 2},
      :layout => false
  end


  def update_fine_ajax
    @target_action='load_fees_submission_batch'
    @target_controller='finance'
    @date = @fee_collection = FinanceFeeCollection.find(params[:fine][:date])
    @batch = Batch.find(params[:fine][:batch_id])
    @student = Student.find(params[:fine][:student]) if params[:fine][:student]
    if request.post?
      @students=Student.find(:all, :joins => "inner join finance_fees on finance_fees.student_id=students.id and finance_fees.batch_id=#{@batch.id} inner join collection_particulars on collection_particulars.finance_fee_collection_id=finance_fees.fee_collection_id inner join finance_fee_particulars on finance_fee_particulars.id=collection_particulars.finance_fee_particular_id", :conditions => "finance_fees.fee_collection_id='#{@date.id}' and finance_fee_particulars.batch_id='#{@batch.id}' and ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=finance_fees.batch_id) or (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id=finance_fees.student_id) or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id=finance_fees.student_category_id))").uniq
      student_ids=@students.collect(&:id).join(',')
      @dates = @batch.finance_fee_collections
      @student ||= FinanceFee.first(:conditions => "fee_collection_id = #{@date.id}", :joins => 'INNER JOIN students ON finance_fees.student_id = students.id').student
      @prev_student = @student.previous_fee_student(@date.id, student_ids)
      @next_student = @student.next_fee_student(@date.id, student_ids)

      @financefee = @student.finance_fee_by_date @date
      @paid_fees = @financefee.finance_transactions
      @fine=nil
      unless params[:fine][:fee].nil?
        @fine=params[:fine][:fee]
      end

      @due_date = @fee_collection.due_date

      @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted = false"])
      particular_and_discount_details
      bal=(@total_payable-@total_discount).to_f
      days=(Date.today-@date.due_date.to_date).to_i
      auto_fine=@date.fine
      if days > 0 and auto_fine
        @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule

        if @fine_rule and @financefee.balance==0
          @fine_amount=@fine_amount-@paid_fees.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
        end
      end
      render :update do |page|
       
        if @fine.nil? or @fine.to_f > 0
          page.replace_html "fees_detail", :partial => "student_fees_submission", :with => @fine
          page << "Modalbox.hide();"
        elsif @fine.to_f <=0
          page.replace_html 'modal-box', :partial => 'fine_submission'
          page.replace_html 'form-errors', :text=>"<div id='error-box'><ul><li>#{t('finance.flash24')}</li></ul></div>"
        end
      end
    else
      render :update do |page|
        page.replace_html 'modal-box', :partial => 'fine_submission'
        page << "Modalbox.show($('modal-box'), {title: ''});"

      end
    end
  end

  def search_logic #student search (fees submission)
    query = params[:query]
    @target_action=params[:target_action]
    @target_controller=params[:target_controller]
    if query.length>= 3
      @students_result = Student.find(:all,
        :conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                            OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ",
          "#{query}%", "#{query}%", "#{query}%",
          "#{query}", "#{query}"],
        :order => "first_name asc") unless query == ''
    else
      @students_result = Student.find(:all,
        :conditions => ["admission_no = ? ", query],
        :order => "first_name asc") unless query == ''
    end
    render :layout => false
  end

  def fees_student_dates
    @student = Student.find(params[:id])
    @dates=FinanceFeeCollection.find(:all, :joins => "INNER JOIN collection_particulars on collection_particulars.finance_fee_collection_id=finance_fee_collections.id INNER JOIN finance_fee_particulars on finance_fee_particulars.id=collection_particulars.finance_fee_particular_id INNER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id", :conditions => "finance_fees.student_id='#{@student.id}' and finance_fee_collections.is_deleted=#{false} and ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id='#{@student.batch_id}') or (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id='#{@student.id}') or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id='#{@student.student_category_id}'))").uniq
  end

  def fees_submission_student
    @target_action='fees_submission_student'
    @target_controller='finance'
    if params[:date].present?
      @student = Student.find(params[:id])
      @date = @fee_collection = FinanceFeeCollection.find(params[:date])
      @financefee = @student.finance_fee_by_date(@date)


      @due_date = @fee_collection.due_date
      @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
      flash[:warning]=nil
      flash[:notice]=nil

      @paid_fees = @financefee.finance_transactions

      particular_and_discount_details
      bal=(@total_payable-@total_discount).to_f
      days=(Date.today-@date.due_date.to_date).to_i
      auto_fine=@date.fine
      if days > 0 and auto_fine
        @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
        if @fine_rule and @financefee.balance==0
          @fine_amount=@fine_amount-@paid_fees.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
        end
      end
      @fine_amount=0 if @financefee.is_paid
      render :update do |page|
        page.replace_html "fee_submission", :partial => "fees_submission_form"
      end
    else
      render :update do |page|
        page.replace_html "fee_submission", :text => ""
      end
    end


  end

  def update_student_fine_ajax
    @target_action='fees_submission_student'
    @target_controller='finance'
    @student = Student.find(params[:fine][:student])
    @date = @fee_collection = FinanceFeeCollection.find(params[:fine][:date])
    @financefee = @student.finance_fee_by_date(@date)
    unless params[:fine][:fee].to_f < 0
      @fine = (params[:fine][:fee])
      flash[:notice] = nil
    else
      flash[:notice] = "#{t('flash24')}"
    end
    @paid_fees = @financefee.finance_transactions
    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    particular_and_discount_details
    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
      if @fine_rule and @financefee.balance==0
        @fine_amount=@fine_amount-@paid_fees.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
      end
    end
    render :update do |page|
      page.replace_html "fee_submission", :partial => "fees_submission_form"
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

  def fees_submission_save
    @target_action='fees_submission_student'
    @target_controller='finance'
    @student = Student.find(params[:student])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financefee = @date.fee_transactions(@student.id)

    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    particular_and_discount_details
    total_fees = @financefee.balance.to_f+FedenaPrecision.set_and_modify_precision(params[:special_fine]).to_f
    unless params[:fine].nil?
      total_fees += FedenaPrecision.set_and_modify_precision(params[:fine]).to_f
    end
    @paid_fees = @financefee.finance_transactions


    if request.post?

      unless params[:fees][:fees_paid].to_f <= 0
        unless params[:fees][:payment_mode].blank?
          unless FedenaPrecision.set_and_modify_precision(params[:fees][:fees_paid]).to_f > FedenaPrecision.set_and_modify_precision(total_fees).to_f
            transaction = FinanceTransaction.new
            (@financefee.balance.to_f > params[:fees][:fees_paid].to_f) ? transaction.title = "#{t('receipt_no')}. (#{t('partial')}) F#{@financefee.id}" : transaction.title = "#{t('receipt_no')}. F#{@financefee.id}"
            transaction.category = FinanceTransactionCategory.find_by_name("Fee")
            transaction.payee = @student
            transaction.finance = @financefee
            transaction.fine_included = true unless params[:fine].nil?
            transaction.amount = params[:fees][:fees_paid].to_f
            transaction.fine_amount = params[:fine].to_f
            if params[:special_fine] and total_fees==params[:fees][:fees_paid].to_f
              # transaction.fine_amount = params[:fine].to_f+params[:special_fine].to_f
              # transaction.fine_included = true
              @fine_amount=0
            end
            transaction.transaction_date = params[:transaction_date]
            transaction.payment_mode = params[:fees][:payment_mode]
            transaction.payment_note = params[:fees][:payment_note]
            transaction.save
            # is_paid = @financefee.balance==0 ? true : false
            # @financefee.update_attributes(:is_paid => is_paid)
            flash[:warning] = "#{t('flash14')}"
            flash[:notice]=nil
          else
            flash[:warning]=nil
            flash[:notice] = "#{t('flash19')}"
          end
        else
          flash[:warning]=nil
          flash[:notice] = "#{t('select_one_payment_mode')}"
        end
      else
        flash[:warning]=nil
        flash[:notice] = "#{t('flash23')}"
      end
    end

    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule and @financefee.is_paid==false
      if @fine_rule and @financefee.balance==0
        @fine_amount=@fine_amount-@paid_fees.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
      end
    end
    @financefee.reload
    @fine_amount=0 if @financefee.is_paid

    render :update do |page|
      page.replace_html "fee_submission", :partial => "fees_submission_form"
    end
  end


  #fees structure ----------------------

  def fees_student_structure_search_logic # student search fees structure
    query = params[:query]
    unless query.length < 3
      @students_result = Student.find(:all,
        :conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                         OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ",
          "#{query}%", "#{query}%", "#{query}%", "#{query}", "#{query}"],
        :order => "batch_id asc,first_name asc") unless query == ''
    else
      @students_result = Student.find(:all,
        :conditions => ["admission_no = ? ", query],
        :order => "batch_id asc,first_name asc") unless query == ''
    end
    render :layout => false
  end

  def fees_structure_dates
    @student = Student.find(params[:id])
    #@dates = @student.batch.fee_collection_dates
    @student_fees = FinanceFee.find_all_by_student_id(@student.id, :select => 'fee_collection_id')
    @student_dates = ""
    @student_fees.map { |s| @student_dates += s.fee_collection_id.to_s + "," }
    @dates = FinanceFeeCollection.find(:all, :select => "distinct finance_fee_collections.*", :joins => :collection_particulars, :conditions => "FIND_IN_SET(finance_fee_collections.id,\"#{@student_dates}\") and finance_fee_collections.is_deleted = 0")
  end

  def fees_structure_for_student
    @student = Student.find(params[:id])
    @date= FinanceFeeCollection.find params[:date]

    @financefee=@student.finance_fee_by_date(@date)
    @fee_category = FinanceFeeCategory.find(@date.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    particular_and_discount_details
    #@total_discount_percentage = [@batch_discounts,@student_discounts,@category_discounts].flatten.compact.map{|s| s.discount(@student)}.sum
    render :update do |page|
      page.replace_html "fees_structure", :partial => "fees_structure"
    end
  end

  def student_fees_structure
    @student = Student.find(params[:id])
    @fee_collection = FinanceFeeCollection.find params[:id2]
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_collection.finance_fee_particulars.all(:conditions => "batch_id=#{@student.batch_id} and is_deleted=#{false}").select { |par| (par.receiver.present?) and (par.receiver==@student or par.receiver==@financefee.student_category or par.receiver==@student.batch) and (!par.is_deleted and par.batch_id==@student.batch_id) }

  end


  #fees defaulters-----------------------

  def fees_defaulters
    @courses = Course.all(:joins => {:batches => {:students => {:finance_fees => :finance_fee_collection}}}, :conditions => ["courses.is_deleted=? and finance_fees.balance > ? and finance_fee_collections.is_deleted=? and finance_fee_collections.due_date < ?", false, 0, false, Date.today], :group => "courses.id")
    @batchs = []
    @dates = []
  end

  def update_batches
    @course = Course.find(params[:course_id])
    @batchs = @course.batches.all(:joins => {:students => {:finance_fees => :finance_fee_collection}}, :conditions => ["batches.is_deleted=? and batches.is_active=? and finance_fees.balance > ? and finance_fee_collections.is_deleted=? and finance_fee_collections.due_date < ?", false, true, 0, false, Date.today], :group => "batches.id")

    render :update do |page|
      page.replace_html "batches_list", :partial => "batches_list"
    end
  end

  def update_fees_collection_dates_defaulters
    @batch = Batch.find(params[:batch_id])
    @dates = @batch.finance_fee_collections.all(:joins => "INNER JOIN `finance_fees` ON finance_fees.fee_collection_id = finance_fee_collections.id INNER JOIN `batches` ON `batches`.id = `finance_fees`.batch_id INNER JOIN students on students.id=finance_fees.student_id", :conditions => ["finance_fee_collections.is_deleted=? and finance_fee_collections.due_date < ? and finance_fees.balance> ?", false, Date.today, 0.0], :group => "id")
    render :update do |page|
      page.replace_html "fees_collection_dates", :partial => "fees_collection_dates_defaulters"
    end
  end


  def fees_defaulters_students
    @batch = Batch.find(params[:batch_id])
    @date = FinanceFeeCollection.find(params[:date])
    @defaulters=Student.find(:all, :joins => "INNER JOIN finance_fees on finance_fees.student_id=students.id ", :conditions => ["finance_fees.fee_collection_id='#{@date.id}' and finance_fees.balance > 0 and finance_fees.batch_id='#{@batch.id}'"], :order => "students.first_name ASC").uniq
    render :update do |page|
      page.replace_html "student", :partial => "student_defaulters"
    end
  end

  def fee_defaulters_pdf
    @batch = Batch.find(params[:batch_id])
    @date = @finance_fee_collection = FinanceFeeCollection.find(params[:date])
    @defaulters=Student.find(:all, :joins => "INNER JOIN finance_fees on finance_fees.student_id=students.id ", :conditions => ["finance_fees.fee_collection_id='#{@date.id}' and finance_fees.balance > 0 and finance_fees.batch_id='#{@batch.id}'"], :select => ["students.*,finance_fees.balance as balance"], :order => "students.first_name ASC").uniq
    @currency_type = currency

    render :pdf => 'fee_defaulters_pdf'
  end

  def pay_fees_defaulters
    @target_action='pay_fees_defaulters'
    @target_controller='finance'
    @batch=Batch.find(params[:batch_id])
    @fine = params[:fine].to_f unless params[:fine].nil?
    @student = Student.find(params[:id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financefee = @date.fee_transactions(@student.id)
    @due_date = @fee_collection.due_date

    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    particular_and_discount_details

    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    @paid_fees = @financefee.finance_transactions
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule

    end


    total_fees = @financefee.balance.to_f+FedenaPrecision.set_and_modify_precision(@fine_amount).to_f

    total_fees += @fine unless @fine.nil?

    if request.post?

      unless params[:fees][:fees_paid].to_f <= 0
        unless params[:fees][:payment_mode].blank?
          #unless params[:fees][:fees_paid].to_f> @total_fees
          unless FedenaPrecision.set_and_modify_precision(params[:fees][:fees_paid]).to_f > FedenaPrecision.set_and_modify_precision(total_fees).to_f
            transaction = FinanceTransaction.new
            (@financefee.balance.to_f > params[:fees][:fees_paid].to_f) ? transaction.title = "#{t('receipt_no')}. (#{t('partial')}) F#{@financefee.id}" : transaction.title = "#{t('receipt_no')}. F#{@financefee.id}"
            transaction.category = FinanceTransactionCategory.find_by_name("Fee")
            transaction.payee = @student
            transaction.finance = @financefee
            transaction.amount = params[:fees][:fees_paid].to_f
            transaction.fine_included = true unless @fine.nil?
            transaction.fine_amount = params[:fine].to_f


            if params[:special_fine] and total_fees==params[:fees][:fees_paid].to_f
              # transaction.fine_amount = params[:fine].to_f+FedenaPrecision.set_and_modify_precision(params[:special_fine]).to_f
              # transaction.fine_included = true
              @fine_amount=0
            end
            transaction.transaction_date = params[:transaction_date]
            transaction.payment_mode = params[:fees][:payment_mode]
            transaction.payment_note = params[:fees][:payment_note]
            transaction.save


            # is_paid =@financefee.balance==0 ? true : false
            # @financefee.update_attributes(:is_paid => is_paid)

            @paid_fees = @financefee.finance_transactions
            flash[:notice] = "#{t('flash14')}"
            redirect_to :action => "pay_fees_defaulters", :id => @student, :date => @date, :batch_id => @batch.id
          else
            flash[:notice] = "#{t('flash19')}"
          end
        else
          flash[:warn_notice] = "#{t('select_one_payment_mode')}"
        end
      else
        flash[:warn_notice] = "#{t('flash23')}"
      end

    end
    if @fine_rule and @financefee.balance==0
      @fine_amount=@fine_amount-@paid_fees.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
      @fine_amount= 0 if @fine_amount < 0
    end
    if @financefee.is_paid
      @fine=nil
      @fine_amount=0
    end
  end

  def update_defaulters_fine_ajax
    @target_action='pay_fees_defaulters'
    @target_controller='finance'
    @student = Student.find(params[:fine][:student])
    @date = FinanceFeeCollection.find(params[:fine][:date])
    @financefee = @date.fee_transactions(@student.id)
    @fee_collection = FinanceFeeCollection.find(params[:fine][:date])
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @date.fees_particulars(@student)
    unless params[:fine][:fee].to_f < 0
      @fine = params[:fine][:fee].to_f

      total_fees = 0
      @fee_particulars.each do |p|
        total_fees += p.amount
      end
      total_fees += @fine unless @fine.nil?
    else
      flash[:notice] = "#{t('flash24')}"
    end
    redirect_to :action => "pay_fees_defaulters", :id => @student.id, :date => @date.id, :fine => @fine, :batch_id => params[:batch_id]
  end

  def compare_report

  end

  def report_compare
    if (date_format(params[:start_date]).nil? or date_format(params[:end_date]).nil? or date_format(params[:start_date2]).nil? or date_format(params[:end_date2]).nil?)
      flash[:notice]=t('invalid_date_format')
      redirect_to :controller => "user", :action => "dashboard"
    elsif (params[:start_date]==params[:start_date2] and params[:end_date]==params[:end_date2])
      flash[:notice]=t('same_time_periods')
      redirect_to :action => "compare_report"
    elsif ((params[:end_date].to_date < params[:start_date].to_date) or (params[:end_date2].to_date < params[:start_date2].to_date))
      flash[:warn_notice]=t('end_date_lower')
      redirect_to :action => "compare_report"
    else
      fixed_category_name
      @hr = Configuration.find_by_config_value("HR")
      @start_date = (params[:start_date]).to_date
      @end_date = (params[:end_date]).to_date
      @start_date2 = (params[:start_date2]).to_date
      @end_date2 = (params[:end_date2]).to_date
      @transactions = FinanceTransaction.find(:all,
        :order => 'transaction_date desc', :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'"])
      @transactions2 = FinanceTransaction.find(:all,
        :order => 'transaction_date desc', :conditions => ["transaction_date >= '#{@start_date2}' and transaction_date <= '#{@end_date2}'"])
      @other_transaction_categories = FinanceTransaction.find(:all, params[:page], :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'and category_id NOT IN (#{@fixed_cat_ids.join(",")})"],
        :order => 'transaction_date').map { |ft| ft.category }.uniq
      @other_transaction_categories2 = FinanceTransaction.find(:all, params[:page], :conditions => ["transaction_date >= '#{@start_date2}' and transaction_date <= '#{@end_date2}'and category_id NOT IN (#{@fixed_cat_ids.join(",")})"],
        :order => 'transaction_date').map { |ft| ft.category }.uniq
      @salary=FinanceTransaction.sum('amount', :conditions => {:title => "Monthly Salary", :transaction_date => @start_date..@end_date}).to_f
      @salary2=FinanceTransaction.sum('amount', :conditions => {:title => "Monthly Salary", :transaction_date => @start_date2..@end_date2}).to_f
      @donations_total = FinanceTransaction.donations_triggers(@start_date, @end_date)
      @donations_total2 = FinanceTransaction.donations_triggers(@start_date2, @end_date2)
      @transactions_fees = FinanceTransaction.total_fees(@start_date, @end_date).map { |t| t.transaction_total.to_f }.sum
      @transactions_fees2 = FinanceTransaction.total_fees(@start_date2, @end_date2).map { |t| t.transaction_total.to_f }.sum
      @batchs = Batch.find(:all)
      @grand_total = FinanceTransaction.grand_total(@start_date, @end_date)
      @grand_total2 = FinanceTransaction.grand_total(@start_date2, @end_date2)
      @category_transaction_totals = {}
      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        @category_transaction_totals["#{category[:category_name]}"] = FinanceTransaction.total_transaction_amount(category[:category_name], @start_date, @end_date)
      end
      @category_transaction_totals2 = {}
      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        @category_transaction_totals2["#{category[:category_name]}"] = FinanceTransaction.total_transaction_amount(category[:category_name], @start_date2, @end_date2)
      end
      @graph = open_flash_chart_object(960, 500, "graph_for_compare_monthly_report?start_date=#{@start_date}&end_date=#{@end_date}&start_date2=#{@start_date2}&end_date2=#{@end_date2}")
    end
  end

  def month_date
    @start_date = params[:start_date]
    @end_date = params[:end_date]
  end

  def partial_payment
    render :update do |page|
      page.replace_html "partial_payment", :partial => "partial_payment"
    end
  end


  #reports pdf---------------------------

  def pdf_fee_structure
    @student = Student.find(params[:id])
    @institution_name = Configuration.find_by_config_key("InstitutionName")
    @institution_address = Configuration.find_by_config_key("InstitutionAddress")
    @institution_phone_no = Configuration.find_by_config_key("InstitutionPhoneNo")
    @currency_type = currency
    @date = FinanceFeeCollection.find params[:id2]
    @financefee=@student.finance_fee_by_date(@date)
    @fee_category = FinanceFeeCategory.find(@date.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    particular_and_discount_details

    render :pdf => 'pdf_fee_structure'

    #        respond_to do |format|
    #            format.pdf { render :layout => false }
    #        end
  end

  #graph------------------------------------


  def graph_for_update_monthly_report

    start_date = (params[:start_date]).to_date
    end_date = (params[:end_date]).to_date
    employees = Employee.find(:all)

    hr = Configuration.find_by_config_value("HR")
    donations_total = FinanceTransaction.donations_triggers(start_date, end_date)
    fees = FinanceTransaction.total_fees(start_date, end_date).map { |t| t.transaction_total.to_f }.sum
    income = FinanceTransaction.total_other_trans(start_date, end_date)[0]
    expense = FinanceTransaction.total_other_trans(start_date, end_date)[1]
    #    other_transactions = FinanceTransaction.find(:all,
    #      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"])


    x_labels = []
    data = []
    largest_value =0

    unless hr.nil?
      salary = FinanceTransaction.sum('amount', :conditions => {:title => "Monthly Salary", :transaction_date => start_date..end_date}).to_f
      unless salary <= 0
        x_labels << "#{t('salary')}"
        data << salary-(salary*2)
        largest_value = salary if largest_value < salary
      end
    end
    unless donations_total <= 0
      x_labels << "#{t('donations')}"
      data << donations_total
      largest_value = donations_total if largest_value < donations_total
    end

    unless fees <= 0
      x_labels << "#{t('fees_text')}"
      data << fees
      largest_value = fees if largest_value < fees
    end

    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      transaction = FinanceTransaction.total_transaction_amount(category[:category_name], start_date, end_date)
      amount = transaction[:amount]
      unless amount <= 0
        x_labels << "#{category[:category_name]}"
        transaction[:category_type] == "income" ? data << amount : data << amount-(amount*2)
        largest_value = amount if largest_value < amount
      end
    end

    unless income <= 0
      x_labels << "#{t('other_income')}"
      data << income
      largest_value = income if largest_value < income
    end
    unless expense <= 0
      x_labels << "#{t('other_expense')}"
      data << expense-(expense*2)
      largest_value = expense if largest_value < expense
    end


    #    other_transactions.each do |trans|
    #      x_labels << trans.title
    #      if trans.category.is_income? and trans.master_transaction_id == 0
    #        data << trans.amount
    #      else
    #        data << ("-"+trans.amount.to_s).to_i
    #      end
    #      largest_value = trans.amount if largest_value < trans.amount
    #    end

    largest_value += 500

    bargraph = BarFilled.new()
    bargraph.width = 1;
    bargraph.colour = '#bb0000';
    bargraph.dot_size = 3;
    bargraph.text = "#{t('amount')}"
    bargraph.values = data

    x_axis = XAxis.new
    x_axis.labels = x_labels

    y_axis = YAxis.new
    y_axis.set_range(FedenaPrecision.set_and_modify_precision(largest_value-(largest_value*2)), FedenaPrecision.set_and_modify_precision(largest_value), FedenaPrecision.set_and_modify_precision(largest_value/5))

    title = Title.new("#{t('finance_transactions')}")

    x_legend = XLegend.new("Examination name")
    x_legend.set_style('{font-size: 14px; color: #778877}')

    y_legend = YLegend.new("Marks")
    y_legend.set_style('{font-size: 14px; color: #770077}')

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.set_x_legend = x_legend
    chart.set_y_legend = y_legend
    chart.y_axis = y_axis
    chart.x_axis = x_axis

    chart.add_element(bargraph)


    render :text => chart.render

  end

  def graph_for_compare_monthly_report

    start_date = (params[:start_date]).to_date
    end_date = (params[:end_date]).to_date
    start_date2 = (params[:start_date2]).to_date
    end_date2 = (params[:end_date2]).to_date
    employees = Employee.find(:all)

    hr = Configuration.find_by_config_value("HR")
    donations_total = FinanceTransaction.donations_triggers(start_date, end_date)
    donations_total2 = FinanceTransaction.donations_triggers(start_date2, end_date2)
    fees = FinanceTransaction.total_fees(start_date, end_date).map { |t| t.transaction_total.to_f }.sum
    fees2 = FinanceTransaction.total_fees(start_date2, end_date2).map { |t| t.transaction_total.to_f }.sum
    income = FinanceTransaction.total_other_trans(start_date, end_date)[0]
    income2 = FinanceTransaction.total_other_trans(start_date2, end_date2)[0]
    expense = FinanceTransaction.total_other_trans(start_date, end_date)[1]
    expense2 = FinanceTransaction.total_other_trans(start_date2, end_date2)[1]

    #    other_transactions = FinanceTransaction.find(:all,
    #      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"])
    #    other_transactions2 = FinanceTransaction.find(:all,
    #      :conditions => ["transaction_date >= '#{start_date2}' and transaction_date <= '#{end_date2}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"])


    x_labels = []
    data = []
    data2 = []
    largest_value =0

    unless hr.nil?
      salary = FinanceTransaction.sum('amount', :conditions => {:title => "Monthly Salary", :transaction_date => start_date..end_date}).to_f
      salary2 = FinanceTransaction.sum('amount', :conditions => {:title => "Monthly Salary", :transaction_date => start_date2..end_date2}).to_f
      unless salary <= 0 and salary2 <= 0
        x_labels << "#{t('salary')}"
        data << salary-(salary*2)
        data2 << salary2-(salary2*2)
        largest_value = salary if largest_value < salary
        largest_value = salary2 if largest_value < salary2
      end
    end
    unless donations_total <= 0 and donations_total2 <= 0
      x_labels << "#{t('donations')}"
      data << donations_total
      data2 << donations_total2
      largest_value = donations_total if largest_value < donations_total
      largest_value = donations_total2 if largest_value < donations_total2
    end

    unless fees <= 0 and fees2 <= 0
      x_labels << "#{t('fees_text')}"
      data << FedenaPrecision.set_and_modify_precision(fees).to_f
      data2 << FedenaPrecision.set_and_modify_precision(fees2).to_f
      largest_value = fees if largest_value < fees
      largest_value = fees2 if largest_value < fees2
    end

    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      transaction1 = FinanceTransaction.total_transaction_amount(category[:category_name], start_date, end_date)
      transaction2 = FinanceTransaction.total_transaction_amount(category[:category_name], start_date2, end_date2)
      amount1 = transaction1[:amount]
      amount2 = transaction2[:amount]
      unless amount1 <= 0 and amount2 <= 0
        x_labels << "#{category[:category_name]}"
        transaction1[:category_type] == "income" ? data << amount1 : data << amount1-(amount1*2)
        transaction2[:category_type] == "income" ? data2 << amount2 : data2 << amount2-(amount2*2)
        largest_value = amount1 if largest_value < amount1
        largest_value = amount2 if largest_value < amount2
      end
    end

    unless income <= 0 and income2 <= 0
      x_labels << "#{t('other_income')}"
      data << income
      data2 << income2
      largest_value = income if largest_value < income
      largest_value = income2 if largest_value < income2
    end

    unless expense <= 0 and expense2 <= 0
      x_labels << "#{t('other_expense')}"
      data << FedenaPrecision.set_and_modify_precision(expense-(expense*2)).to_f
      data2 << FedenaPrecision.set_and_modify_precision(expense2-(expense2*2)).to_f
      largest_value = expense if largest_value < expense
      largest_value = expense2 if largest_value < expense2
    end

    #       other = 0
    #    other_transactions.each do |trans|
    #
    #      if trans.category.is_income? and trans.master_transaction_id == 0
    #        other += trans.amount
    #      else
    #        other -= trans.amount
    #      end
    #    end
    #    x_labels << "other"
    #    data << other
    #    largest_value = other if largest_value < other
    #    other2 = 0
    #    other_transactions2.each do |trans2|
    #      if trans2.category.is_income?
    #        other2 += trans2.amount
    #      else
    #        other2 -= trans2.amount
    #      end
    #    end
    #    data2 << other2
    #    largest_value = other2 if largest_value < other2

    largest_value += 500

    bargraph = BarFilled.new()
    bargraph.width = 1;
    bargraph.colour = '#bb0000';
    bargraph.dot_size = 3;
    bargraph.text = "#{t('for_the_period')} #{format_date(start_date)} #{t('to')} #{format_date(end_date)}"
    bargraph.values = data
    bargraph2 = BarFilled.new()
    bargraph2.width = 1;
    bargraph2.colour = '#000000';
    bargraph2.dot_size = 3;
    bargraph2.text = "#{t('for_the_period')} #{format_date(start_date2)} #{t('to')} #{format_date(end_date2)}"
    bargraph2.values = data2

    x_axis = XAxis.new
    x_axis.labels = x_labels

    y_axis = YAxis.new
    y_axis.set_range(FedenaPrecision.set_and_modify_precision(largest_value-(largest_value*2)), FedenaPrecision.set_and_modify_precision(largest_value), FedenaPrecision.set_and_modify_precision(largest_value/5))

    title = Title.new("#{t('finance_transactions')}")

    x_legend = XLegend.new("#{t('examination_name')}")
    x_legend.set_style('{font-size: 14px; color: #778877}')

    y_legend = YLegend.new("#{t('marks')}")
    y_legend.set_style('{font-size: 14px; color: #770077}')

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.set_x_legend = x_legend
    chart.set_y_legend = y_legend
    chart.y_axis = y_axis
    chart.x_axis = x_axis

    chart.add_element(bargraph)
    chart.add_element(bargraph2)


    render :text => chart.render

  end

  #ddnt complete this graph!

  def graph_for_transaction_comparison

    start_date = (params[:start_date]).to_date
    end_date = (params[:end_date]).to_date
    employees = Employee.find(:all)

    hr = Configuration.find_by_config_value("HR")
    donations_total = FinanceTransaction.donations_triggers(start_date, end_date)
    fees = FinanceTransaction.total_fees(start_date, end_date).map { |t| t.transaction_total.to_f }.sum
    income = FinanceTransaction.total_other_trans(start_date, end_date)[0]
    expense = FinanceTransaction.total_other_trans(start_date, end_date)[1]
    #    other_transactions = FinanceTransaction.find(:all,
    #      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"])


    x_labels = []
    data1 = []
    data2 = []

    largest_value =0

    unless hr.nil?
      salary = Employee.total_employees_salary(employees, start_date, end_date)
    end
    unless salary <= 0
      x_labels << "#{t('salary')}"
      data << salary-(salary*2)
      largest_value = salary if largest_value < salary
    end
    unless donations_total <= 0
      x_labels << "#{t('donations')}"
      data << donations_total
      largest_value = donations_total if largest_value < donations_total
    end

    unless fees <= 0
      x_labels << "#{t('fees_text')}"
      data << fees
      largest_value = fees if largest_value < fees
    end

    unless income <= 0
      x_labels << "#{t('other_income')}"
      data << income
      largest_value = income if largest_value < income
    end

    unless expense <= 0
      x_labels << "#{t('other_expense')}"
      data << expense
      largest_value = expense if largest_value < expense
    end

    #    other_transactions.each do |trans|
    #      x_labels << trans.title
    #      if trans.category.is_income? and trans.master_transaction_id == 0
    #        data << trans.amount
    #      else
    #        data << ("-"+trans.amount.to_s).to_i
    #      end
    #      largest_value = trans.amount if largest_value < trans.amount
    #    end

    largest_value += 500

    bargraph = BarFilled.new()
    bargraph.width = 1;
    bargraph.colour = '#bb0000';
    bargraph.dot_size = 3;
    bargraph.text = "#{t('amount')}"
    bargraph.values = data

    x_axis = XAxis.new
    x_axis.labels = x_labels

    y_axis = YAxis.new
    y_axis.set_range(largest_value-(largest_value*2), largest_value, largest_value/5)

    title = Title.new("#{t('finance_transactions')}")

    x_legend = XLegend.new("#{t('examination_name')}")
    x_legend.set_style('{font-size: 14px; color: #778877}')

    y_legend = YLegend.new("#{t('marks')}")
    y_legend.set_style('{font-size: 14px; color: #770077}')

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.set_x_legend = x_legend
    chart.set_y_legend = y_legend
    chart.y_axis = y_axis
    chart.x_axis = x_axis

    chart.add_element(bargraph)


    render :text => chart.render


  end

  #fee Discount
  def fee_discounts
    @batches = Batch.active
  end

  def fee_discount_new
    @batches = Batch.active
  end

  def load_discount_create_form
    @fee_categories=FinanceFeeCategory.all(:select => "DISTINCT finance_fee_categories.*", :joins => [{:category_batches => :batch}, :fee_particulars], :conditions => "batches.is_active = 1 AND batches.is_deleted = 0 AND finance_fee_categories.is_deleted=0 AND finance_fee_particulars.is_deleted = 0")
    if params[:type]== "batch_wise"
      @fee_discount = BatchFeeDiscount.new
      render :update do |page|
        page.replace_html "form-box", :partial => "batch_wise_discount_form"
        page.replace_html 'form-errors', :text => ""
      end
    elsif params[:type]== "category_wise"
      @student_categories = StudentCategory.active
      render :update do |page|
        page.replace_html "form-box", :partial => "category_wise_discount_form"
        page.replace_html 'form-errors', :text => ""
      end
    elsif params[:type] == "student_wise"
      @courses = Course.active
      @students=[]
      render :update do |page|
        page.replace_html "form-box", :partial => "student_wise_discount_form"
        page.replace_html 'form-errors', :text => ""
      end
    else
      render :update do |page|
        page.replace_html "form-box", :text => ""
        page.replace_html 'form-errors', :text => ""
      end
    end
  end

  def load_discount_batch
    if params[:id].present?
      @course = Course.find(params[:id])
      @batches =Batch.find(:all, :joins => "INNER JOIN students on students.batch_id=batches.id", :conditions => "batches.course_id=#{@course.id}").uniq
      #@batches = @course.batches.active
      render :update do |page|
        page.replace_html "batch-box", :partial => "fee_discount_batch_list"
      end
    else
      render :update do |page|
        page.replace_html "batch-box", :text => ""
      end
    end
  end

  def load_particular_fee_categories
    if params[:batch]
      @fees_categories=FinanceFeeCategory.find(:all, :select => "distinct finance_fee_categories.*", :joins => [:fee_particulars], :conditions => "finance_fee_particulars.is_deleted=false and finance_fee_particulars.batch_id=#{params[:batch]}")
      render :update do |page|
        page.replace_html "fee-category-box", :partial => "fee_particular_category_list"
      end
    else
      render :update do |page|
        page.replace_html "fee-category-box", :text => ""
      end
    end
  end

  def load_fee_category_particulars
    if params[:id]
      if params[:cat_id].present?
        @particulars=FinanceFeeParticular.find(:all, :select => "finance_fee_particulars.*", :conditions => "finance_fee_category_id =#{params[:id]} and is_deleted = false and (receiver_type='Batch' or (receiver_type='StudentCategory' and receiver_id=#{params[:cat_id]}) ) ")
      else
        @particulars=FinanceFeeParticular.find(:all, :select => "finance_fee_particulars.*", :conditions => {:finance_fee_category_id => params[:id], :is_deleted => false})
      end
      # @student_categories=StudentCategory.active
      render :update do |page|
        page.replace_html "batch-data", :partial => "discount_particulars_list"
      end
    else
      render :update do |page|
        page.replace_html "batch-data", :text => ""
      end
    end

  end

  def particular_discount_applicable_students
    if params[:particulars].present?
      @students= Student.find(:all, :select => "distinct students.*,ffp.id as master_receiver_id,concat(ffp.name,'-',batches.name) as receiver_name,'FinanceFeeParticular' as master_receiver_type", :joins => "inner join batches on batches.id=students.batch_id inner join finance_fee_particulars ffp on ffp.batch_id=students.batch_id and ((ffp.receiver_type='Student' and ffp.receiver_id=students.id) or (ffp.receiver_type='Batch' and ffp.receiver_id=students.batch_id) or (ffp.receiver_type='StudentCategory' and ffp.receiver_id=students.student_category_id))", :conditions => ["ffp.id in (?)", params[:particulars]], :order => "students.first_name asc").group_by(&:receiver_name)
    else
      @students=Student.find(:all, :joins => {:batch => :course}, :select => "distinct students.*,students.batch_id as master_receiver_id,concat(courses.code,'-',batches.name) as receiver_name,'Student' as master_receiver_type", :conditions => ["students.batch_id in (?) and students.is_deleted=false", params[:batch_ids]], :order => "students.first_name asc").group_by(&:receiver_name)
    end
    respond_to do |format|
      format.js { render :action => 'particular_discount_applicable_students.js.erb'
      }
      format.html
    end
  end

  def load_batch_fee_category
    if params[:batch].present?
      @batch=Batch.find(params[:batch])
      fees_categories =FinanceFeeCategory.find(:all, :joins => "INNER JOIN category_batches on category_batches.finance_fee_category_id=finance_fee_categories.id INNER JOIN finance_fee_particulars on finance_fee_particulars.finance_fee_category_id=category_batches.finance_fee_category_id",
        :conditions => "finance_fee_particulars.batch_id=#{@batch.id} and category_batches.batch_id=#{@batch.id} and finance_fee_particulars.is_deleted=false and finance_fee_categories.is_deleted=false and finance_fee_categories.is_master=1").uniq
      #fees_categories = @batch.finance_fee_categories.find(:all,:conditions=>"is_deleted = 0 and is_master = 1")
      @fees_categories=[]
      fees_categories.each do |f|
        particulars=f.fee_particulars.select { |s| s.is_deleted==false }
        unless particulars.empty?
          @fees_categories << f
        end
      end
      render :update do |page|
        page.replace_html "fee-category-box", :partial => "fee_discount_category_list"
      end
    else
      render :update do |page|
        page.replace_html "fee-category-box", :text => ""
      end
    end
  end


  def batch_wise_discount_create
    unless params[:fee_discount][:finance_fee_category_id].blank? or params[:fee_collection].blank?
      FeeDiscount.transaction do
        params[:fee_collection][:category_ids].each do |c|
          @fee_discount = FeeDiscount.new(params[:fee_discount])

          if params[:fee_discount][:master_receiver_type]=='FinanceFeeParticular'
            master_receiver=FinanceFeeParticular.find(c)
            @fee_discount.master_receiver=master_receiver
            @fee_discount.receiver = master_receiver.receiver
            @fee_discount.batch_id=master_receiver.batch_id
          else
            @fee_discount.receiver_type="Batch"
            @fee_discount.receiver_id = c
            @fee_discount.batch_id=c
          end

          unless @fee_discount.save
            @error = true
            raise ActiveRecord::Rollback
          end
        end
      end
    else
      @fee_discount = FeeDiscount.new(params[:fee_discount])
      @fee_discount.save
      @error = true
    end
  end

  def category_wise_fee_discount_create
    unless params[:fee_discount][:finance_fee_category_id].blank? or params[:fee_collection].blank?
      FeeDiscount.transaction do
        params[:fee_collection][:category_ids].each do |c|
          @fee_discount = FeeDiscount.new(params[:fee_discount])
          if params[:fee_discount][:master_receiver_type]=='FinanceFeeParticular'
            master_receiver=FinanceFeeParticular.find(c)
            @fee_discount.master_receiver=master_receiver
            @fee_discount.batch_id=master_receiver.batch_id
          else
            @fee_discount.receiver_type="StudentCategory"
            @fee_discount.batch_id=c
          end

          unless @fee_discount.save
            @error = true
            @fee_discount.errors.add_to_base("#{t('select_student_category')}") if params[:fee_discount][:receiver_id].empty?
            raise ActiveRecord::Rollback
          end
        end
      end
    else
      @fee_discount = FeeDiscount.new(params[:fee_discount])
      @fee_discount.save
      @error = true
    end
  end

  def student_wise_fee_discount_create
    unless params[:fee_discount][:finance_fee_category_id].blank?
      @fee_category=FinanceFeeCategory.find(params[:fee_discount][:finance_fee_category_id])
      s=@fee_category
      discount_attributes=params[:discounts]
      if params[:discounts].present?
        attributes_to_be_merged=params[:fee_discount].delete_if { |k, v| k=='master_receiver_type' or k=='finance_fee_category_id' }
        discount_attributes[:fee_discounts_attributes].each { |k, v| v.merge!(attributes_to_be_merged) }

        @fee_category.fee_discounts_attributes=discount_attributes['fee_discounts_attributes']
        unless @fee_category.valid?
          @error=true
        else
          Delayed::Job.enqueue(DelayedStudentFeeDiscount.new(@fee_category.id, discount_attributes))
        end
      else
        @error=true
        @fee_category.errors.add_to_base("#{t('select_at_least_one_student')}")
      end
    else
      @fee_category=FinanceFeeCategory.new()
      @error=true
      @fee_category.errors.add_to_base(t('fees_category_cant_be_blank'))
    end
  end


  def update_master_fee_category_list
    @batch = Batch.find(params[:id])
    @fee_categories=@batch.finance_fee_categories.find(:all, :conditions => "is_master=1 and is_deleted= 0", :order => "name asc")
    #@fee_categories = FinanceFeeCategory.find_all_by_batch_id(@batch.id, :conditions=>"is_master=1 and is_deleted= 0")
    render :update do |page|
      page.replace_html "master-category-box", :partial => "update_master_fee_category_list"
    end
  end

  def show_fee_discounts
    @batch=Batch.find(params[:b_id])
    if params[:id]==""
      render :update do |page|
        page.replace_html "discount-box", :text => ""
      end
    else

      @fee_category = FinanceFeeCategory.find(params[:id])
      @discounts = @fee_category.fee_discounts.all(:joins => "LEFT OUTER JOIN students ON students.id = fee_discounts.receiver_id AND fee_discounts.receiver_type = 'Student' LEFT OUTER JOIN batches ON batches.id = fee_discounts.receiver_id AND fee_discounts.receiver_type = 'Batch' LEFT OUTER JOIN student_categories ON student_categories.id = fee_discounts.receiver_id AND fee_discounts.receiver_type = 'StudentCategory'", :conditions => ["(students.id IS NOT NULL OR batches.id IS NOT NULL OR student_categories.id IS NOT NULL) AND fee_discounts.batch_id='#{@batch.id}' AND fee_discounts.is_deleted= 0"])

      render :update do |page|
        page.replace_html "discount-box", :partial => "show_fee_discounts"
      end
    end
  end

  def edit_fee_discount
    @fee_discount = FeeDiscount.find(params[:id])
  end

  def update_fee_discount
    @fee_discount = FeeDiscount.find(params[:id])
    unless @fee_discount.update_attributes(params[:fee_discount])
      @error = true
    else
      @fee_category = @fee_discount.finance_fee_category
      @discounts = @fee_category.fee_discounts.all(:conditions => ["batch_id='#{@fee_discount.batch_id}'  and is_deleted= 0"])
      #@fee_category.is_collection_open ? @discount_edit = false : @discount_edit = true
    end
  end

  def delete_fee_discount
    @fee_discount = FeeDiscount.find(params[:id])
    #batch=@fee_discount.batch
    @fee_category = FinanceFeeCategory.find(@fee_discount.finance_fee_category_id)
    @error = true unless @fee_discount.update_attributes(:is_deleted => true)
    unless @fee_category.nil?
      @discounts = @fee_category.fee_discounts.all(:conditions => ["batch_id='#{@fee_discount.batch_id}' and is_deleted= #{false}"])
      #@fee_category.is_collection_open ? @discount_edit = false : @discount_edit = true
    end
    render :update do |page|
      page.replace_html "discount-box", :partial => "show_fee_discounts"
      page.replace_html "flash-notice", :text => "<p class='flash-msg'>#{t('discount_deleted_successfully')}.</p>"
    end

  end

  def collection_details_view
    @fee_collection = FinanceFeeCollection.find(params[:id])
    @particulars = @fee_collection.finance_fee_particulars.all(:conditions => ["batch_id='#{params[:batch_id]}'"])
    @total_payable=@particulars.map { |s| s.amount }.sum.to_f
    @discounts = @fee_collection.fee_discounts.all(:conditions => ["batch_id='#{params[:batch_id]}'"])
  end

  def fixed_category_name
    @cat_names = ['Fee', 'Salary', 'Donation']
    @plugin_cat = []
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      @cat_names << "#{category[:category_name]}"
      @plugin_cat << "#{category[:category_name]}"
    end
    @fixed_cat_ids = FinanceTransactionCategory.find(:all, :conditions => {:name => @cat_names}).collect(&:id)
  end

  def delete_transaction_fees_defaulters
    @target_action='pay_fees_defaulters'
    @target_controller='finance'
    transaction_deletion
    render :update do |page|
      page.redirect_to :action => "pay_fees_defaulters", :id => @student, :date => @date, :batch_id => params[:batch_id]
    end
  end


  def delete_transaction_for_particular_wise_fee_pay
    @target_action='particular_wise_fee_payment'
    @target_controller='finance_extensions'
    transaction_deletion
    @financefee.reload
    @applied_discount=ParticularDiscount.find(:all, :joins => [{:particular_payment => :finance_fee}], :conditions => "finance_fees.id=#{@financefee.id}").sum(&:discount).to_f
    @transaction_category_id=FinanceTransactionCategory.find_by_name("Fee").id
    render :update do |page|
      flash[:notice]="#{t('finance.flash18')}"
      page.replace_html "fee_submission", :partial => "finance_extensions/particular_fees_submission_form"
    end
  end


  def delete_transaction_for_student
    transaction_deletion
    @target_action='fees_submission_student'
    @target_controller='finance'
    render :update do |page|
      page.replace_html "fee_submission", :partial => "fees_submission_form"
    end
  end

  def delete_transaction_by_batch
    @target_action='load_fees_submission_batch'
    @target_controller='finance'
    transaction_deletion
    @batch = Batch.find(params[:batch_id])
    @students=Student.find(:all, :joins => "inner join finance_fees on finance_fees.student_id=students.id and finance_fees.batch_id=#{@batch.id} inner join collection_particulars on collection_particulars.finance_fee_collection_id=finance_fees.fee_collection_id inner join finance_fee_particulars on finance_fee_particulars.id=collection_particulars.finance_fee_particular_id", :conditions => "finance_fees.fee_collection_id='#{@date.id}' and finance_fee_particulars.batch_id='#{@batch.id}' and ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=finance_fees.batch_id) or (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id=finance_fees.student_id) or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id=finance_fees.student_category_id))").uniq
    student_ids=@students.collect(&:id).join(',')
    @dates = FinanceFeeCollection.find(:all)
    @fee = FinanceFee.first(:conditions => "fee_collection_id = #{@date.id}", :joins => 'INNER JOIN students ON finance_fees.student_id = students.id')
    @student ||= @fee.student
    @prev_student = @student.previous_fee_student(@date.id, student_ids)
    @next_student = @student.next_fee_student(@date.id, student_ids)

    render :update do |page|
      page.replace_html "fees_detail", :partial => "student_fees_submission"
    end
  end

  def transaction_deletion
    @student = Student.find(params[:id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financetransaction=FinanceTransaction.find(params[:transaction_id])
    ActiveRecord::Base.transaction do
      if FedenaPlugin.can_access_plugin?("fedena_pay")
        payment = @financetransaction.payment
        unless payment.nil?
          status = Payment.payment_status_mapping[:reverted]
          payment.update_attributes(:status_description => status)
          payment.save
        end
      end
      if @financetransaction
        mft=@financetransaction.multi_fees_transactions
        if mft.present?
          mft_amount=mft.first.amount.to_f-@financetransaction.amount.to_f
          if mft_amount==0.0
            mft.first.send(:destroy_without_callbacks)
          else
            mft.first.update_attributes(:amount => mft_amount)
          end
        end
        raise ActiveRecord::Rollback unless @financetransaction.destroy
      end
    end
    @financefee = @student.finance_fee_by_date(@date)
    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])

    flash[:warning]=nil
    flash[:notice]=nil

    @paid_fees = @financefee.finance_transactions
    particular_and_discount_details
    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    @fine_amount=0
    @paid_fine=0
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}'"], :order => 'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
      @paid_fine=@fine_amount
      if @fine_rule.present?
        @fine_amount=@fine_amount-@paid_fees.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
      end
    end
  end

  def particular_and_discount_details
    @fee_particulars = @date.finance_fee_particulars.all(:conditions => "batch_id=#{@financefee.batch_id}").select { |par| (par.receiver.present?) and (par.receiver==@student or par.receiver==@financefee.student_category or par.receiver==@financefee.batch) }
    @categorized_particulars=@fee_particulars.group_by(&:receiver_type)
    @discounts=@date.fee_discounts.all(:conditions => "batch_id=#{@financefee.batch_id}").select { |par| (par.receiver.present?) and ((par.receiver==@financefee.student or par.receiver==@financefee.student_category or par.receiver==@financefee.batch) and (par.master_receiver_type!='FinanceFeeParticular' or (par.master_receiver_type=='FinanceFeeParticular' and (par.master_receiver.receiver.present? and @fee_particulars.collect(&:id).include? par.master_receiver_id) and (par.master_receiver.receiver==@financefee.student or par.master_receiver.receiver==@financefee.student_category or par.master_receiver.receiver==@financefee.batch)))) }
    @categorized_discounts=@discounts.group_by(&:master_receiver_type)
    @total_discount = 0
    @total_payable=@fee_particulars.map { |s| s.amount }.sum.to_f
    @total_discount =@discounts.map { |d| d.master_receiver_type=='FinanceFeeParticular' ? (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) : @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100) }.sum.to_f unless @discounts.nil?
  end

  def update_deleted_transactions
    all_fee_types=['HostelFee','TransportFee','FinanceFee','Refund','BookMovement','InstantFee']
    @transactions =CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20, :conditions => ["created_at >='#{Date.today}' and created_at <'#{Date.today+1.day}' and (collection_name is not null or finance_type in (?))",all_fee_types], :order => 'created_at desc')
    if request.xhr?
      render :update do |page|
        page.replace_html 'deleted_transactions', :partial => "finance/deleted_transactions"
      end
    end
  end

  def transaction_filter_by_date
    @start_date=params[:s_date]
    @end_date=params[:e_date]
    all_fee_types=['HostelFee','TransportFee','FinanceFee','Refund','BookMovement','InstantFee']
    if params['transaction_type'].present? and params['transaction_type']==t('others')
      conditions="and (collection_name is null or finance_type not in (?))"
    else
      conditions="and (collection_name is not null or finance_type in (?))"
    end
    @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,
      :order => 'created_at desc', :conditions => ["created_at >= '#{@start_date}' and created_at < '#{@end_date.to_date+1.day}' #{conditions}",all_fee_types])
    render :update do |page|
      page.replace_html 'search_div', :partial => "finance/search_by_date_deleted_transactions"
    end
  end

  def list_deleted_transactions
    @transactions =CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20, :conditions => ["created_at >='#{Date.today}' and created_at <'#{Date.today+1.day}'"], :order => 'created_at desc')
    render :update do |page|
      page.replace_html 'deleted_transactions', :partial => "finance/deleted_transactions"
    end
  end

  def search_fee_collection
    if params[:option]==t('fee_collection_name')
      @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20, :order => 'created_at desc',
        :conditions => ["collection_name LIKE ?",
          "#{params[:query]}%"]) unless params[:query] == ''
    elsif params[:option]==t('date_text')
      @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20, :order => 'created_at desc',
        :conditions => ["created_at LIKE ?",
          "#{params[:query]}%"]) unless params[:query] == ''
    else
      if FedenaPlugin.can_access_plugin?("fedena_instant_fee")
        @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20, :order => 'created_at desc', :joins => 'LEFT OUTER JOIN students ON students.id = payee_id LEFT OUTER JOIN employees ON employees.id = payee_id LEFT OUTER JOIN instant_fees ON instant_fees.id = finance_id',
          :conditions => ["students.admission_no LIKE ? OR employees.employee_number LIKE ? OR instant_fees.guest_payee LIKE ?",
            "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%"]) unless params[:query] == ''
      else
        @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20, :order => 'created_at desc', :joins => 'LEFT OUTER JOIN students ON students.id = payee_id LEFT OUTER JOIN employees ON employees.id = payee_id',
          :conditions => ["students.admission_no LIKE ? OR employees.employee_number LIKE ?",
            "#{params[:query]}%", "#{params[:query]}%"]) unless params[:query] == ''
      end
    end

    render :update do |page|
      page.replace_html 'search_div', :partial => "finance/search_deleted_transactions"
    end
    #render :partial => "finance/search_deleted_transactions"
  end

  def transactions_advanced_search
    @searched_for = ""
    if (params[:search] or params[:date])
      all_fee_types="'HostelFee','TransportFee','FinanceFee','Refund','BookMovement','InstantFee'"
      if params['transaction']['type'].present? and params['transaction']['type']==t('others')
        @searched_for =@searched_for+ "<span> #{t('transaction_type')}</span>: #{t('others')}"
        conditions="and (cancelled_finance_transactions.collection_name is null or cancelled_finance_transactions.finance_type not in (#{all_fee_types}))"
      else
        @searched_for =@searched_for+ "<span> #{t('transaction_type')}</span>: #{t('fees_text')}"
        conditions="and (cancelled_finance_transactions.collection_name is not null or cancelled_finance_transactions.finance_type in (#{all_fee_types}))"
      end

      search_attr=params[:search].delete_if { |k, v| v=="" }
      condition_attr=""
      search_attr.keys.each do |k|
        if ["collection_name", "category_id"].include?(k)

          condition_attr=condition_attr+" AND cancelled_finance_transactions.#{k} LIKE ? "

        elsif ["first_name", "admission_no"].include?(k)
          condition_attr=condition_attr+" AND students.#{k} LIKE ?"
        elsif ["employee_number", "employee_name"].include?(k)

          k=="employee_number" ? condition_attr=condition_attr+" AND employees.#{k} LIKE ?" : condition_attr=condition_attr+" AND employees.first_name LIKE ?"
        else
          condition_attr=condition_attr+" AND instant_fees.#{k} LIKE ?" if FedenaPlugin.can_access_plugin?("fedena_instant_fee")
        end

      end
      condition_attr=condition_attr+conditions
      #p condition_attr.split(' ')[1..-1].join(' ')
      unless condition_attr.empty?
        condition_attr=condition_attr.split(' ')[1..-1].join(' ')
        condition_attr="("+condition_attr+")"+" AND (cancelled_finance_transactions.created_at < ? AND cancelled_finance_transactions.created_at > ?)"
      else
        condition_attr= "(cancelled_finance_transactions.created_at < ? AND cancelled_finance_transactions.created_at > ?)"
      end
      condition_array=[]
      condition_array << condition_attr
      search_attr.values.each { |c| condition_array<< (c+"%") }
      #i=2
      condition_array<<"#{params[:date][:end_date].to_date+1.day}%"
      condition_array<<"#{params[:date][:start_date]}%"
      #params[:date].values.each{|d| i=i-1;condition_array<< (d.to_date+i.day)}
      if FedenaPlugin.can_access_plugin?("fedena_instant_fee")
        @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20, :order => 'created_at desc', :joins => 'LEFT OUTER JOIN students ON students.id = payee_id LEFT OUTER JOIN employees ON employees.id = payee_id LEFT OUTER JOIN instant_fees ON instant_fees.id = finance_id',
          :conditions => condition_array) unless params[:query] == ''
      else
        @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20, :order => 'created_at desc', :joins => 'LEFT OUTER JOIN students ON students.id = payee_id LEFT OUTER JOIN employees ON employees.id = payee_id ',
          :conditions => condition_array) unless params[:query] == ''
      end
      
      search_attr.each do |k, v|
        @searched_for=@searched_for+ "<span> #{k.humanize}</span>"
        @searched_for=@searched_for+ ": " +v.humanize+" "
      end
      params[:date].each do |k, v|
        @searched_for=@searched_for+ "<span> #{k.humanize}</span>"
        @searched_for=@searched_for+ ": " +format_date(v.humanize)+" "
      end
      if params[:remote]=="remote"
        render :update do |page|
          page.replace_html 'search-result', :partial => "finance/transaction_advanced_search"
        end
      end
    end
  end


  def new_refund
    @refund_rule=RefundRule.new
    @collections=FinanceFeeCollection.find(:all, :conditions => {:is_deleted => false}, :group => :name)
  end


  def create_refund

    @refund_rule=RefundRule.new
    @old_collections=FinanceFeeCollection.find(:all, :conditions => "is_deleted = false and batch_id is not null", :group => :name)
    @new_collections=FinanceFeeCollection.find(:all, :select => "distinct finance_fee_collections.*", :joins => {:fee_collection_batches => :batch}, :conditions => "finance_fee_collections.is_deleted = false and finance_fee_collections.batch_id is null and batches.is_active=true and batches.is_deleted=false")
    @collections=(@old_collections+@new_collections).uniq
    if request.post?
      @refund_rule.attributes=params[:refund_rule]
      @refund_rule.user=current_user
      if @refund_rule.save
        flash[:notice]="#{t('refund_rule_created')}"
        redirect_to :controller => 'finance', :action => 'create_refund'
      else
        render :create_refund
      end
    end
  end

  def refund_student_search
    query = params[:query]
    if query.length>= 3
      @students= Student.find(:all, :joins => 'INNER JOIN finance_fees ON finance_fees.student_id = students.id AND finance_fees.balance=0',
        :conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                            OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ",
          "#{query}%", "#{query}%", "#{query}%",
          "#{query}", "#{query}"],
        :order => "batch_id asc,first_name asc") unless query == ''
      @students=@students.uniq
    else
      @students = Student.find(:all, :joins => 'INNER JOIN finance_fees ON finance_fees.student_id = students.id AND finance_fees.balance=0',
        :conditions => ["admission_no = ? ", query],
        :order => "batch_id asc,first_name asc") unless query == ''
    end
    render :layout => false
  end

  def fees_refund_dates
    @student=Student.find(params[:id])
    @dates= FinanceFeeCollection.find(:all, :select => "distinct finance_fee_collections.*", :joins => "INNER JOIN finance_fees ON finance_fees.fee_collection_id = finance_fee_collections.id AND finance_fees.student_id='#{@student.id}' AND finance_fees.balance = 0 AND finance_fees.is_paid=true LEFT JOIN fee_collection_batches on fee_collection_batches.finance_fee_collection_id=finance_fee_collections.id and fee_collection_batches.batch_id=finance_fees.batch_id LEFT JOIN batches on batches.id=finance_fees.batch_id LEFT JOIN fee_refunds on fee_refunds.finance_fee_id=finance_fees.id", :conditions => "(finance_fee_collections.is_deleted=false or fee_refunds.id is not null) and batches.is_active=true", :order => "name asc")
  end

  def fees_refund_student
    @student = Student.find(params[:id])
    if params[:date].present?
      @date = @fee_collection = FinanceFeeCollection.find(params[:date])
      @financefee = @student.finance_fee_by_date(@date)


      @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])

      @paid_fees = @financefee.finance_transactions

      @refund_amount=0
      particular_and_discount_details
      #@collection=FinanceFeeCollection.find_by_name(@date.name, :conditions => {:is_deleted => false})
      @refund_rule=@date.refund_rules.find(:first, :order => 'refund_validity ASC', :conditions => ["refund_validity >=  '#{Date.today}'"])
      @fee_refund=@financefee.fee_refund
      if @fee_refund
        #@fee_refund=@financefee.fee_refund
        @refund_rule=@fee_refund.refund_rule if @fee_refund
      end
      total_fees = (@total_payable-@total_discount)
      @refund_amount=(total_fees)*(@refund_rule.amount.to_f)/(@refund_rule.is_amount ? total_fees : 100) if @refund_rule
      @eligible_refund= (total_fees > @refund_amount) ? @refund_amount : total_fees
      if request.post?
        FeeRefund.transaction do
          transaction = FinanceTransaction.new
          transaction.receipt_no = transaction.refund_receipt_no
          transaction.title = "#{@refund_rule.name} &#x200E;(#{@student.first_name}) &#x200E;"
          transaction.category = FinanceTransactionCategory.find_by_name("Refund")
          transaction.payee = @student
          transaction.amount = params[:fees][:amount].to_f
          transaction.transaction_date = Date.today
          transaction.description = params[:fees][:reason]
          transaction.save

          @fee_refund=transaction.build_fee_refund(params[:fees])
          @fee_refund.finance_fee_id=@financefee.id
          @fee_refund.user=current_user
          @fee_refund.refund_rule=@refund_rule
          unless @fee_refund.save
            raise ActiveRecord::Rollback
          else
            flash[:notice]="#{t('refund')} #{t('succesful')}"
          end

        end

        render :update do |page|
          page.replace_html "flash-div", :text => ''
          page.replace_html "refund", :partial => "fees_refund_form"
        end

      else
        render :update do |page|
          page.replace_html "fee_submission", :partial => "fees_refund_form"
        end
      end
    else
      render :update do |page|
        page.replace_html "fee_submission", :text => ""
      end
    end
  end

  def revert_fee_refund
    fee_refund=FeeRefund.find(params[:id])
    finance_fee=fee_refund.finance_fee

    if fee_refund.finance_transaction.destroy
      flash[:notice]="#{t('fees_refund')} #{t('successfully_reverted').downcase}"
    end
    student = finance_fee.student
    redirect_to :action => :fees_refund_dates, :id => student.id

  end

  def view_refund_rules
    @dates=FinanceFeeCollection.find(:all, :select => "distinct finance_fee_collections.*", :joins => :refund_rules, :conditions => {:is_deleted => false})
  end


  def list_refund_rules
    @finance_fee_collection=FinanceFeeCollection.find(params[:id])
    @refund_rules=@finance_fee_collection.refund_rules
    render :update do |page|
      flash[:notice]=nil
      page.replace_html 'categories', :partial => 'refund_rules'
    end
  end

  def edit_refund_rules
    @refund_rule=RefundRule.find(params[:id])
    respond_to do |format|
      format.js { render :action => 'edit_refund_rules' }
    end
  end

  def refund_rule_update
    @refund_rule=RefundRule.find(params[:id])
    finance_fee_collection=@refund_rule.finance_fee_collection

    if @refund_rule.update_attributes(params[:refund_rule])
      render :update do |page|
        @refund_rules=finance_fee_collection.refund_rules
        page.replace_html 'form-errors', :text => ''
        page.replace_html 'categories', :partial => 'refund_rules'
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('refund_rules').singularize} #{t('has_been_updated')}</p>"
        @error=false
      end
    else

      render :update do |page|

        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @refund_rule

        page.visual_effect(:highlight, 'form-errors')
      end

    end
  end

  def refund_rule_delete
    refund_rule=RefundRule.find(params[:id])
    @finance_fee_collection=refund_rule.finance_fee_collection
    @refund_rules=@finance_fee_collection.refund_rules
    if refund_rule.destroy
      render :update do |page|
        flash[:notice]="#{t('finance.flash29')}"
        page.replace_html 'categories', :partial => 'refund_rules'
      end
    end
  end

  def fee_refund_student_pdf
    @student = Student.find(params[:id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financefee = @student.finance_fee_by_date(@date)


    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])

    @paid_fees = @financefee.finance_transactions

    @refund_amount=0
    particular_and_discount_details
    fee_refund=@financefee.fee_refund
    @refund_amount=fee_refund.amount.to_f
    @refund_percentage=fee_refund.refund_rule.refund_percentage
    render :pdf => 'fee_refund_student_pdf'
  end

  def view_refunds
    @page=0
    @current_user=current_user
    @start_date=Date.today
    @end_date=Date.today
    if @current_user.admin? or @current_user.privileges.collect(&:name).include? "ManageRefunds"
      if params[:id]
        @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => [:finance_fee], :conditions => ["finance_fees.student_id='#{params[:id].to_i}' and fee_refunds.created_at >='#{@start_date}' and fee_refunds.created_at <'#{@end_date+1.day}'"], :order => 'created_at desc')
      else
        @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 10, :conditions => ["created_at >='#{@start_date}' and created_at <'#{@end_date+1.day}'"], :order => 'created_at desc')
      end
    elsif @current_user.parent?
      @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => [:finance_fee], :conditions => ["finance_fees.student_id='#{@current_user.guardian_entry.ward_id}' and fee_refunds.created_at >='#{Date.today}' and fee_refunds.created_at <'#{Date.today+1.day}'"], :order => 'created_at desc')
    else
      @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => [:finance_fee], :conditions => ["finance_fees.student_id='#{@current_user.student_entry.id}' and fee_refunds.created_at >='#{Date.today}' and fee_refunds.created_at <'#{Date.today+1.day}'"], :order => 'created_at desc')
    end
  end

  def refund_student_view
    @page=0
    @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 5, :joins => [:finance_transaction], :conditions => ["finance_transactions.payee_id='#{params[:id].to_i}' and finance_transactions.payee_type='Student'"], :order => 'created_at desc')
  end

  def refund_student_view_pdf
    refund_student_view
    render :pdf => 'refund_student_view_pdf'
  end

  def list_refunds
    @start_date=Date.today
    @end_date=Date.today
    @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 5, :conditions => ["created_at >='#{Date.today}' and created_at <'#{Date.today+1.day}'"], :order => 'created_at desc')
    @page=params[:page] ? params[:page].to_i-1 : 0
    render :update do |page|
      page.replace_html 'search_div', :partial => "finance/view_refunds"
    end
  end

  def refund_filter_by_date
    @start_date=params[:s_date].to_date
    @end_date=params[:e_date].to_date
    @page=params[:page] ? params[:page].to_i-1 : 0
    @current_user=current_user
    if @current_user.admin? or @current_user.privileges.collect(&:name).include? "ManageRefunds"
      @refunds = FeeRefund.paginate(:page => params[:page], :per_page => 10,
        :order => 'created_at desc', :conditions => ["created_at >= '#{@start_date}' and created_at < '#{@end_date.to_date+1.day}'"])
    elsif @current_user.parent?
      @refunds = FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => [:finance_fee],
        :order => 'created_at desc', :conditions => ["finance_fees.student_id='#{@current_user.guardian_entry.ward_id}' and created_at >= '#{@start_date}' and created_at < '#{@end_date.to_date+1.day}'"])
    else
      @refunds = FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => [:finance_fee],
        :order => 'created_at desc', :conditions => ["finance_fees.student_id='#{@current_user.student_entry.id}' and fee_refunds.created_at >= '#{@start_date}' and fee_refunds.created_at < '#{@end_date.to_date+1.day}'"])
    end
    render :update do |page|
      page.replace_html 'search_div', :partial => "finance/view_refunds_by_date"
    end
  end

  def search_fee_refunds
    @page=params[:page] ? params[:page].to_i-1 : 0

    if params[:option]==t('student_name')
      @refunds=FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => 'INNER JOIN finance_fees on finance_fees.id=fee_refunds.finance_fee_id INNER JOIN students on students.id=finance_fees.student_id',
        :order => 'created_at desc', :conditions => ["students.first_name LIKE ?",
          "#{params[:query]}%"])
    else
      @refunds=FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => 'INNER JOIN finance_fees on finance_fees.id=fee_refunds.finance_fee_id INNER JOIN finance_fee_collections on finance_fee_collections.id=finance_fees.fee_collection_id',
        :order => 'created_at desc', :conditions => ["finance_fee_collections.name LIKE ?",
          "#{params[:query]}%"])
    end
    render :update do |page|
      page.replace_html 'search_div', :partial => "finance/view_refunds_by_search"
    end
  end

  def refund_search_pdf

    if params[:option]==t('student_name')
      @refunds=FeeRefund.find(:all, :joins => 'INNER JOIN finance_fees on finance_fees.id=fee_refunds.finance_fee_id INNER JOIN students on students.id=finance_fees.student_id',
        :order => 'created_at desc', :conditions => ["students.first_name LIKE ?",
          "#{params[:query]}%"])
    elsif params[:option]==t('fee_collection_name') or params[:option]=="Fee Collection Name"
      @refunds=FeeRefund.find(:all, :joins => 'INNER JOIN finance_fees on finance_fees.id=fee_refunds.finance_fee_id INNER JOIN finance_fee_collections on finance_fee_collections.id=finance_fees.fee_collection_id',
        :order => 'created_at desc', :conditions => ["finance_fee_collections.name LIKE ?",
          "#{params[:query]}%"])
    else
      if date_format_check
        if (params[:option] or (@start_date and @end_date))
          @refunds = FeeRefund.find(:all,
            :order => 'created_at desc', :conditions => ["created_at >= '#{@start_date}' and created_at < '#{@end_date.to_date+1.day}'"])

        else
          error=true

        end
      end
    end
    if error
      flash[:notice]=t('invalid_date_format')
      redirect_to :controller => "user", :action => "dashboard"
    else
      render :pdf => 'refund_search_pdf'
    end
  end

  def generate_fine
    @fine=Fine.new
    @fine_rule=FineRule.new
    @fines=Fine.active

  end


  def fine_list
    if params[:id].present?
      @fine=Fine.find(params[:id])
      @fine_rules=@fine.fine_rules.order_in_fine_days
      render :update do |page|
        page.replace_html "fine_list", :partial => "list_fines"
      end
    else
      render :update do |page|
        page.replace_html "fine_list", :text => ""
      end
    end
  end

  def fine_slabs_edit_or_create

    if params[:id].present?
      if params[:id]=="0"
        @fine=Fine.new
        render :update do |page|
          page.replace_html "form-errors", :text => ""
          page.replace_html "select_fine", :partial => "new_fine"
          page.replace_html "flash_box", :text => ""
        end
      else
        @fine=Fine.find(params[:id])
        render :update do |page|
          page.replace_html "flash_box", :text => ""
          page.replace_html "form-errors", :text => ""
          page.replace_html "select_fine", :partial => "list_fine_slabs"
        end
      end
    end

    if request.post?
      if params[:fine_id].nil?
        flash[:notice]=t('fine_created_successfully')
      else
        flash[:notice]=t('fine_slabs_updated')
      end
      if  params[:fine][:is_deleted].present?
        flash[:notice]=t('fine_deleted')
      end
      fine_id=params[:fine_id]
      @fine=Fine.find_or_initialize_by_id(fine_id)
      if @fine.update_attributes(params[:fine])
        # @fine=Fine.find(params[:fine_id])
        render :update do |page|
          page.redirect_to "generate_fine"
        end
      else
        flash[:notice]=nil
        render :update do |page|
          page.replace_html "form-errors", :partial => "errors", :object => @fine
          unless fine_id.present?
            page.replace_html "select_fine", :partial => "fine_errors"
          else
            page.replace_html "select_fine", :partial => "list_fine_slabs"
          end
        end
      end
    end
  end


  def student_wise_fee_payment
    @student=Student.find(params[:id])
  end
  def add_additional_details_for_donation
    @all_details = DonationAdditionalField.find(:all, :order=>"priority ASC")
    @additional_details = DonationAdditionalField.find(:all, :conditions=>{:status=>true},:order=>"priority ASC")
    @inactive_additional_details = DonationAdditionalField.find(:all, :conditions=>{:status=>false},:order=>"priority ASC")
    @additional_field = DonationAdditionalField.new
    @finance_additional_field_option = @additional_field.donation_additional_field_options.build
    if request.post?
      priority = 1
      unless @all_details.empty?
        last_priority = @all_details.map{|r| r.priority}.compact.sort.last
        priority = last_priority + 1
      end
      @additional_field = DonationAdditionalField.new(params[:donation_additional_field])
      @additional_field.priority = priority
      if @additional_field.save
        flash[:notice] = "#{t('additional_field_added')}"
        redirect_to :controller => "finance", :action => "add_additional_details_for_donation"
      end
    end
  end
  def edit_additional_details_for_donation
    @additional_details = DonationAdditionalField.find(:all, :conditions=>{:status=>true},:order=>"priority ASC")
    @inactive_additional_details = DonationAdditionalField.find(:all, :conditions=>{:status=>false},:order=>"priority ASC")
    @additional_field = DonationAdditionalField.find(params[:id])
    @donation_additional_field_option = @additional_field.donation_additional_field_options
    if request.get?
      render :action=>'add_additional_details_for_donation'
    else
      if @additional_field.update_attributes(params[:donation_additional_field])
        flash[:notice] = "#{t('additional_filed_edittted')}"
        redirect_to :action => "add_additional_details_for_donation"
      else
        render :action=>"add_additional_details_for_donation"
      end
    end
  end

  def delete_additional_details_for_donation
    donations = DonationAdditionalDetail.find(:all ,:conditions=>"additional_field_id = #{params[:id]}")
    if donations.blank?
      DonationAdditionalField.find(params[:id]).destroy
      @additional_details = DonationAdditionalField.find(:all, :conditions=>{:status=>true},:order=>"priority ASC")
      @inactive_additional_details = DonationAdditionalField.find(:all, :conditions=>{:status=>false},:order=>"priority ASC")
      flash[:notice]="#{t('additional_field_deleted')}"
      redirect_to :action => "add_additional_details_for_donation"
    else
      flash[:notice]="#{t('donations_with_this_field_exists')}"
      redirect_to :action => "add_additional_details_for_donation"
    end
  end

  private

  def date_format(date)
    /(\d{4}-\d{2}-\d{2})/.match(date)
  end


end

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

class FinanceTransaction < ActiveRecord::Base
  belongs_to :category, :class_name => 'FinanceTransactionCategory', :foreign_key => 'category_id'
  delegate :name, :to => :category, :allow_nil=> true,:prefix=>true
  belongs_to :student
  belongs_to :finance, :polymorphic => true
  belongs_to :payee, :polymorphic => true
  belongs_to :master_transaction, :class_name => "FinanceTransaction"
  belongs_to :user
  belongs_to :batch
  has_many :finance_fees, :through => :fee_transactions
  has_many :fee_transactions
  has_many :finance_fees, :through => :fee_transactions
  has_many :fee_transactions
  has_one :fee_refund, :dependent => :destroy
  has_one :finance_donation,:foreign_key=>'transaction_id',  :dependent => :destroy
  cattr_reader :per_page
  validates_presence_of :title, :amount, :transaction_date
  validates_presence_of :category, :message => :not_specified
  validates_numericality_of :amount, :greater_than_or_equal_to => 0, :message => :must_be_positive, :allow_blank => true

  after_create :add_voucher_or_receipt_number
  before_save :verify_precision, :set_fine
  after_create :add_user
  before_destroy :refund_check
  after_destroy :create_cancelled_transaction
  has_many :monthly_payslips
  has_many :particular_payments, :dependent => :destroy
  has_and_belongs_to_many :multi_fees_transactions, :join_table => "multi_fees_transactions_finance_transactions"

  after_create :verify_and_send_sms
  
  include CsvExportMod

  def verify_and_send_sms
    recipients = []
    models = {'FinanceFee' => 'finance_fee_collection','HostelFee' => 'hostel_fee_collection','TransportFee' => 'transport_fee_collection',
      'InstantFee' => 'instant_fee_category','RegistrationCourse' => ''      }
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active and models.keys.include? finance_type and sms_setting.fee_submission_sms_active and payee.present?
      payee_name = self.payee.first_name
      case finance_type
      when 'InstantFee'
        collection_name = self.finance.instant_fee_category.present? ? self.finance.instant_fee_category.name : self.finance.custom_category
      when 'RegistrationCourse'
        collection_name = t('application_fees')
      else
        collection = self.finance.send(models[finance_type])
        collection_name = collection.name if collection.present?
      end
      if payee.is_a? Student and payee.is_sms_enabled
        if sms_setting.parent_sms_active
          guardian = payee.immediate_contact if payee.immediate_contact.present?
          recipients.push guardian.mobile_phone if (guardian.present? and guardian.mobile_phone.present?)
        end
        recipients.push payee.phone2 if (sms_setting.student_sms_active and payee.phone2.present?)
      end
      if payee.is_a? Employee and sms_setting.employee_sms_active
        recipients.push payee.mobile_phone if payee.mobile_phone.present?
      end
      if payee.class.name == "Applicant"
        recipients.push payee.phone2 if payee.phone2.present?
      end
    end
    if recipients.present? and collection_name.present?
      recipients = recipients.collect { |x| x.split(',') }
      recipients.flatten!
      recipients.uniq!
      message = "#{t('fee_sms_message_body',:payee_name=>payee_name,:currency_name=>currency_name,:amount=>FedenaPrecision.set_and_modify_precision(amount.to_f),:collection_name=>collection_name,:payment_date=>format_date(transaction_date))}"
      
      Delayed::Job.enqueue(SmsManager.new(message,recipients))      
    end
  end

  def verify_precision
    self.amount = FedenaPrecision.set_and_modify_precision self.amount
    self.fine_amount = FedenaPrecision.set_and_modify_precision self.fine_amount
  end

  def self.report(start_date, end_date, page)
    cat_names = ['Fee', 'Salary', 'Donation']
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      cat_names << "#{category[:category_name]}"
    end
    fixed_cat_ids = FinanceTransactionCategory.find(:all, :conditions => {:name => cat_names}).collect(&:id)
    self.find(:all,
      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id NOT IN (#{fixed_cat_ids.join(",")})"],
      :order => 'transaction_date')
  end

  def self.grand_total(start_date, end_date)
    fee_id = FinanceTransactionCategory.find_by_name("Fee").id
    donation_id = FinanceTransactionCategory.find_by_name("Donation").id
    cat_names = ['Fee', 'Salary', 'Donation']
    plugin_name = []
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      cat_names << "#{category[:category_name]}"
      plugin_name << "#{category[:category_name]}"
    end
    fixed_categories = FinanceTransactionCategory.find(:all, :conditions => {:name => cat_names})
    fixed_cat_ids = fixed_categories.collect(&:id)
    fixed_transactions = FinanceTransaction.find(:all,
      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id IN (#{fixed_cat_ids.join(",")})"])
    other_transactions = FinanceTransaction.find(:all,
      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id NOT IN (#{fixed_cat_ids.join(",")})"])
    #    transactions_fees = FinanceTransaction.find(:all,
    #      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id ='#{fee_id}'"])
    #    donations = FinanceTransaction.find(:all,
    #      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id ='#{donation_id}'"])
    trigger = FinanceTransactionTrigger.find(:all)
    hr = Configuration.find_by_config_value("HR")
    income_total = 0
    expenses_total = 0
    fees_total =0
    salary = 0

    unless hr.nil?
      salary = FinanceTransaction.sum('amount', :conditions => {:title => "Monthly Salary", :transaction_date => start_date..end_date}).to_f
      expenses_total += salary
    end

    transactions_fees = fixed_transactions.reject { |tr| tr.category_id != fee_id }
    donations = fixed_transactions.reject { |tr| tr.category_id != donation_id }

    donations.each do |d|
      if d.master_transaction_id == 0
        income_total +=d.amount
      else
        expenses_total +=d.amount
      end

    end
    transactions_fees.each do |fees|
      income_total +=fees.amount
      fees_total += fees.amount
    end

    # plugin transactions
    plugin_name.each do |p|
      category = fixed_categories.reject { |cat| cat.name.downcase != p.downcase }
      unless category.blank?
        cat_id = category.first.id
        transactions_plugin = fixed_transactions.reject { |tr| tr.category_id != cat_id }
        transactions_plugin.each do |t|
          if t.category.is_income?
            income_total +=t.amount
          else
            expenses_total +=t.amount
          end
        end
      end
    end

    other_transactions.each do |t|
      if t.category.is_income? and t.master_transaction_id == 0
        income_total +=t.amount
      else
        expenses_total +=t.amount
      end
    end
    income_total-expenses_total

  end

  def self.total_fees(start_date, end_date)
    fee_id = FinanceTransactionCategory.find_by_name("Fee").id
    fees =[]
    fees = FinanceTransaction.find(:all, :joins => "INNER JOIN batches on batches.id=finance_transactions.batch_id
INNER JOIN fee_transactions on fee_transactions.finance_transaction_id=finance_transactions.id
INNER JOIN finance_fees on finance_fees.id=fee_transactions.finance_fee_id",
      :conditions => ["finance_transactions.transaction_date >= '#{start_date}' and finance_transactions.transaction_date <= '#{end_date}' and finance_transactions.category_id='#{fee_id}'"],
      :group => ["finance_fees.fee_collection_id,finance_transactions.batch_id"],
      :select => ["batches.*,SUM(finance_transactions.amount) as transaction_total,finance_fees.fee_collection_id as collection_id"])
    return fees
  end

  def self.total_other_trans(start_date, end_date)
    cat_names = ['Fee', 'Salary', 'Donation']
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      cat_names << "#{category[:category_name]}"
    end
    fixed_cat_ids = FinanceTransactionCategory.find(:all, :conditions => {:name => cat_names}).collect(&:id)
    fees = 0
    transactions = FinanceTransaction.find(:all, :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id NOT IN (#{fixed_cat_ids.join(",")})"])
    transactions_income = transactions.reject { |x| !x.category.is_income? }.compact
    transactions_expense = transactions.reject { |x| x.category.is_income? }.compact
    income = 0
    expense = 0
    transactions_income.each do |f|
      income += f.amount
    end
    transactions_expense.each do |f|
      expense += f.amount
    end
    [income, expense]
  end

  def self.donations_triggers(start_date, end_date)
    donation_id = FinanceTransactionCategory.find_by_name("Donation").id
    donations_income =0
    donations_expenses =0
    donations = FinanceTransaction.find(:all, :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}' and master_transaction_id = 0 and category_id ='#{donation_id}'"])
    trigger = FinanceTransaction.find(:all, :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}' and master_transaction_id != 0 and category_id ='#{donation_id}'"])
    donations.each do |d|
      if d.category.is_income?
        donations_income+=d.amount
      else
        donations_expenses+=d.amount
      end
    end
    trigger.each do |t|
      #unless t.finance_category.id.nil?
      # if d.category_id == t.finance_category.id
      donations_expenses += t.amount
      #end
      #end
    end
    donations_income-donations_expenses

  end


  def self.expenses(start_date, end_date)
    expenses = FinanceTransaction.find(:all, :select => 'finance_transactions.*', :joins => ' INNER JOIN finance_transaction_categories ON finance_transaction_categories.id = finance_transactions.category_id', \
        :conditions => ["finance_transaction_categories.is_income = 0 and finance_transaction_categories.id != 1 and transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'"])
    expenses
  end

  def self.incomes(start_date, end_date)
    incomes = FinanceTransaction.find(:all, :select => 'finance_transactions.*', :joins => ' INNER JOIN finance_transaction_categories ON finance_transaction_categories.id = finance_transactions.category_id', \
        :conditions => ["finance_transaction_categories.is_income = 1 and transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}' "])
    incomes = incomes.reject { |income| (income.category.is_fixed or income.master_transaction_id != 0) }
    incomes
  end


  def student_payee
    stu = self.payee
    stu ||= ArchivedStudent.find_by_former_id(self.payee_id)
  end

  def employee_payee
    stu = self.payee
    stu ||= ArchivedEmployee.find_by_former_id(self.payee_id)
  end

  def fetch_payee
    record = self.payee
    record ||= self.payee_type == "Employee" ? self.employee_payee : self.payee_type == "Student" ? self.student_payee : self.payee
  end


  def self.total_transaction_amount(transaction_category, start_date, end_date)
    amount = 0
    finance_transaction_category = FinanceTransactionCategory.find_by_name("#{transaction_category}")
    category_type = finance_transaction_category.is_income ? "income" : "expense"
    transactions = FinanceTransaction.find(:all,
      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id ='#{finance_transaction_category.id}'"])
    transactions.each { |transaction| amount += transaction.amount }
    return {:amount => amount, :category_type => category_type}
  end

  def add_voucher_or_receipt_number
    if self.category.is_income and self.master_transaction_id == 0
      receipt_numbers = FinanceTransaction.search(:receipt_no_not_like => "refund").map { |f| f.receipt_no }
      last_no = receipt_numbers.map { |k| k.scan(/\d+$/i).last.to_i }.max
      last_transaction = FinanceTransaction.last(:conditions => ["receipt_no NOT LIKE '%refund%' and receipt_no LIKE ?", "%#{last_no}"])
      last_receipt_no = last_transaction.receipt_no unless last_transaction.nil?
      unless last_receipt_no.nil?
        receipt_split = /(.*?)(\d+)$/.match(last_receipt_no)
        if receipt_split[1].blank?
          receipt_number = receipt_split[2].next
        else
          receipt_number = receipt_split[1]+receipt_split[2].next
        end
      else
        config_receipt_no = Configuration.get_config_value('FeeReceiptNo')
        receipt_number = config_receipt_no.present? ? config_receipt_no : "1"
      end
      self.update_attributes(:receipt_no => receipt_number)
    else
      last_transaction = FinanceTransaction.last(:conditions => "voucher_no IS NOT NULL and TRIM(voucher_no) not like ''")
      last_voucher_no = last_transaction.voucher_no unless last_transaction.nil?
      if last_voucher_no.present?
        voucher_split = last_voucher_no.to_s.scan(/[A-Z]+|\d+/i)
        if voucher_split[1].blank?
          voucher_number = voucher_split[0].next
        else
          voucher_number = voucher_split[0]+voucher_split[1].next
        end
      else
        voucher_number = "1"
      end
      self.update_attributes(:voucher_no => voucher_number)
    end
  end

  def refund_receipt_no
    receipt_numbers = FinanceTransaction.search(:receipt_no_not_like => "refund").map { |f| f.receipt_no }
    last_no = receipt_numbers.map { |k| k.scan(/\d+$/i).last.to_i }.max
    last_transaction = FinanceTransaction.last(:conditions => ["receipt_no NOT LIKE '%refund%' and receipt_no LIKE ?", "%#{last_no}"])
    last_receipt_no = last_transaction.receipt_no unless last_transaction.nil?
    unless last_receipt_no.nil?
      receipt_split = /(.*?)(\d+)$/.match(last_receipt_no)
      if receipt_split[1].blank?
        receipt_number = receipt_split[2].next
      else
        receipt_number = receipt_split[1]+receipt_split[2].next
      end
    else
      config_receipt_no = Configuration.get_config_value('FeeReceiptNo')
      receipt_number = config_receipt_no.present? ? config_receipt_no : "1"
    end
    return receipt_number
  end

  def set_fine
    # balance=finance.balance+fine_amount-(amount)
    if finance_type=="FinanceFee"
      balance=finance.balance
      manual_fine= fine_amount.present? ? fine_amount.to_f : 0
      fee_balance=balance
      actual_amount=balance+finance.finance_transactions.sum(:amount)-finance.finance_transactions.sum(:fine_amount)
      date=finance.finance_fee_collection
      days=(Date.today-date.due_date.to_date).to_i
      auto_fine=date.fine
      fine_amount=0
      if auto_fine.present?
        fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{date.created_at}'"], :order => 'fine_days ASC')
        fine_amount=fine_rule.is_amount ? fine_rule.fine_amount : (actual_amount*fine_rule.fine_amount)/100 if fine_rule
        paid_fine=finance.finance_transactions.find(:all, :conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
        fine_amount=fine_amount-paid_fine
      end
      actual_balance=FedenaPrecision.set_and_modify_precision(finance.balance+fine_amount).to_f
      amount_paying=FedenaPrecision.set_and_modify_precision(amount-manual_fine).to_f
      actual_balance=0 if FinanceFee.find(finance.id).is_paid
      if amount_paying > actual_balance and description!='fine_amount_included'
        errors.add_to_base(t('finance.flash19'))
        return false
      end
    end
  end

  def add_user
    if Fedena.present_user.present?
      update_attributes(:user_id => Fedena.present_user.id)
      if finance_type=="FinanceFee"
        update_attributes(:batch_id => "#{payee.batch_id}")
        FeeTransaction.create(:finance_fee_id => finance.id, :finance_transaction_id => id)
        balance=finance.balance+fine_amount-(amount)
        manual_fine= fine_amount.present? ? fine_amount.to_f : 0
        fee_balance=balance
        actual_amount=balance+finance.finance_transactions.sum(:amount)-finance.finance_transactions.sum(:fine_amount)
        date=finance.finance_fee_collection
        days=(Date.today-date.due_date.to_date).to_i
        auto_fine=date.fine
        fine_amount=0
        if auto_fine.present?
          fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{date.created_at}'"], :order => 'fine_days ASC')
          fine_amount=fine_rule.is_amount ? fine_rule.fine_amount : (actual_amount*fine_rule.fine_amount)/100 if fine_rule
          auto_fine_amount=fine_amount
          paid_fine=finance.finance_transactions.find(:all, :conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
          fine_amount=fine_amount-paid_fine
        end
        is_paid=false
        balance=FedenaPrecision.set_and_modify_precision(balance).to_f
        fine_amount= FedenaPrecision.set_and_modify_precision(fine_amount).to_f
        if (balance <= 0)
          fee_balance=0
          is_paid=(-(balance)==fine_amount)
          if -(balance)>0
            # self.fine_amount=-(balance)+manual_fine
            # self.fine_included=true
            # self.description="fine_amount_included"
            auto_fine_amount=nil unless is_paid
            sql="UPDATE `finance_transactions` SET `fine_amount` = '#{-(balance)+manual_fine}',`auto_fine`='#{auto_fine_amount}', `fine_included` = 1, `description` = 'fine_amount_included' WHERE `id` = #{id}"
            # self.save(false)
            ActiveRecord::Base.connection.execute(sql)
          end
        end
        # is_paid= ((balance.to_f==0.0) and (finance.finance_transactions.sum(:fine_amount).to_f) >= (fine_amount.to_f))
        # finance.update_attributes(:balance => fee_balance, :is_paid => is_paid)
        finance_fee_sql="UPDATE `finance_fees` SET `balance` = '#{fee_balance}', `is_paid` = #{is_paid} WHERE `id` = '#{finance.id}'"
        ActiveRecord::Base.connection.execute(finance_fee_sql)
      elsif finance_type=="HostelFee"
        finance.update_attributes(:finance_transaction_id=>id)
      elsif finance_type=="TransportFee"
        finance.update_attributes(:transaction_id=>id)
      end

    end
  end

  def self.total(trans_id, fees)
    paid_fees = FinanceTransaction.find(:all, :conditions => "FIND_IN_SET(id,\"#{trans_id}\")", :order => "created_at ASC")
    total_fees=fees
    paid=0
    fine=0
    paid_fees.each do |p|
      paid += p.amount.to_f
      fine += p.fine_amount.to_f
    end
    total_fees =total_fees-paid
    total_fees =total_fees+fine
    #return @total_fees
  end

  def currency_name
    Configuration.currency
  end

  def date_of_transaction
    format_date(self.transaction_date,:format=>:long)
  end

  def self.fetch_finance_payslip_data(params)
    finance_payslip_data(params)
  end

  def self.fetch_finance_transaction_data(params)
    finance_transaction_data(params)
  end

  def create_cancelled_transaction
    finance_transaction_attributes=self.attributes
    if finance_type=='FinanceFee'
      balance=finance.balance+(amount-fine_amount)
      finance.update_attributes(:is_paid => false, :balance => balance)

      FeeTransaction.destroy_all({:finance_transaction_id => id})
    end
    if finance.present? and ["FinanceFee","HostelFee","TransportFee","InstantFee"].include? finance_type
      collection_name=finance.name
      finance_type_name=finance_type
    else
      if category_name=='Refund' and fee_refund.present? and fee_refund.finance_fee.present?
        collection_name=fee_refund.finance_fee.name
      else
        collection_name=nil
      end
      finance_type_name=category_name
    end
    finance_transaction_attributes.merge!(:user_id => Fedena.present_user.id, :finance_type => finance_type_name,:collection_name =>collection_name)
    finance_transaction_attributes.delete "id"
    finance_transaction_attributes.delete "created_at"
    finance_transaction_attributes.delete "updated_at"
    finance_transaction_attributes.delete "multi_fees_transaction_id"
    finance_transaction_attributes.delete "finance_transaction_id"
    dependend_destroy_models=FinanceTransaction.reflect_on_all_associations.select{|a| a.options[:dependent]==:destroy}.map{|d| d.name}
    other_details={}
    dependend_destroy_models.each do |ddm|
      if instance_eval(ddm.to_s).respond_to? 'fetch_other_details_for_cancelled_transaction'
        other_details=instance_eval(ddm.to_s).fetch_other_details_for_cancelled_transaction
      end
    end
    finance_transaction_attributes.merge!(:other_details=>other_details,:finance_transaction_id=>id,:lastvchid=>-(lastvchid.to_i.abs))
    cancelled_transaction=CancelledFinanceTransaction.new(finance_transaction_attributes)
    cancelled_transaction.save
  end

  def refund_check
    if finance_type=='FinanceFee'
      return finance.fee_refund.blank?
    elsif finance_type=="TransportFee"
      finance.update_attributes(:transaction_id=>nil)
    elsif finance_type=="HostelFee"
      finance.update_attributes(:finance_transaction_id=>nil)
    end
  end

  def cashier_name
    user.present? ? user.full_name : "#{t('deleted_user')}"
  end

end

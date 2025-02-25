class HostelFeeCollection < ActiveRecord::Base
  belongs_to :batch
  has_many :finance_transaction,:through=>:hostel_fees
  has_many :hostel_fees
  has_one :event, :as=>:origin

  #validates_uniqueness_of :name, :scope=>:batch_id
  validates_presence_of :name, :start_date,:end_date,:due_date
  before_save :validate_dates
  accepts_nested_attributes_for :hostel_fees

  def validate_dates
    errors.add(:end_date, :is_before_start_date) if self.start_date.to_date > self.end_date.to_date
    errors.add(:due_date, :is_before_start_date) if self.start_date > self.due_date
    errors.add(:due_date, :is_before_end_date) if self.end_date > self.due_date
    #errors.add(:start_date,"overlap End Date ") if self.end_date == self.start_date

  end

  def check_fee_category
    finance_fees = HostelFee.find_all_by_hostel_fee_collection_id(self.id)
    flag = 1
    finance_fees.each do |f|
      flag = 0 unless f.finance_transaction_id.nil?
    end
    flag == 1 ? true : false
  end

  def transaction_amount(start_date,end_date)
    trans =[]
      self.finance_transaction.each{|f| trans<<f if (f.transaction_date.to_s >= start_date and f.transaction_date.to_s <= end_date)}
    trans.map{|t|t.amount}.sum
  end

  def fee_table
    self.hostel_fees.all(:conditions=>"finance_transaction_id IS NULL")
  end
end
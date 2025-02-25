class TransportFeeCollection < ActiveRecord::Base
  belongs_to :batch
  has_many :transport_fees, :dependent => :destroy
  has_many :finance_transaction,:through=>:transport_fees
  validates_presence_of :name,:start_date,:end_date,:due_date
  named_scope :employee, :select => "distinct transport_fee_collections.*", :joins=>[:transport_fees], :conditions => "transport_fee_collections.is_deleted=false and transport_fees.receiver_type='Employee' and transport_fee_collections.due_date < '#{Date.today}'"
  has_one :event, :as=>:origin

  accepts_nested_attributes_for :transport_fees, :allow_destroy => true

  def validate
    errors.add :end_date_before_start_date if self.start_date.present? and self.end_date.present? and (self.start_date > self.end_date)
    errors.add :due_date_before_start_date if self.start_date.present? and self.due_date.present? and (self.start_date > self.due_date)
    errors.add :due_date_before_end_date if self.due_date.present? and self.end_date.present? and (self.end_date > self.due_date)
  end
  def self.shorten_string(string, count)
    if string.length >= count
      shortened = string[0, count]
      splitted = shortened.split(/\s/)
      words = splitted.length
      splitted[0, words-1].join(" ") + ' ...'
    else
      string
    end
  end
  def check_status
    return true unless self.transport_fees.all(:conditions => 'transaction_id IS NOT NULL' ).blank?
    return false
  end

  def transaction_amount(start_date,end_date)
    trans =[]
      self.finance_transaction.each{|f| trans<<f if (f.transaction_date.to_s >= start_date and f.transaction_date.to_s <= end_date)}
    trans.map{|t|t.amount}.sum
  end

  def fee_table
    self.transport_fees.all(:conditions=>"transaction_id IS NULL")
  end
end

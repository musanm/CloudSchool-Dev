class MultiFeesTransaction < ActiveRecord::Base
  belongs_to :student
  has_and_belongs_to_many :finance_transactions,:join_table => "multi_fees_transactions_finance_transactions"

  before_destroy :delete_finance_transactions

  private
  def delete_finance_transactions
    finance_transactions.destroy_all
  end
end

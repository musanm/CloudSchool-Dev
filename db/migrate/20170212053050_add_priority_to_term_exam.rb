class AddPriorityToTermExam < ActiveRecord::Migration
  def self.up
    add_column :term_exams, :order_priority, :integer
  end

  def self.down
    remove_column :term_exams, :order_priority
  end
end

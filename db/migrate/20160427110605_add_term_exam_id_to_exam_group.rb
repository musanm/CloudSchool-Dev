class AddTermExamIdToExamGroup < ActiveRecord::Migration
  def self.up
    add_column :exam_groups, :term_exam_id, :integer
  end

  def self.down
    remove_column :exam_groups, :term_exam_id
  end
end

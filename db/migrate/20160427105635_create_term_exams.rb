class CreateTermExams < ActiveRecord::Migration
  def self.up
    create_table :term_exams do |t|
      t.integer :batch_id
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :term_exams
  end
end

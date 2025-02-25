class TermExam < ActiveRecord::Base
	belongs_to :batch
	has_many :exam_groups
	default_scope :order => 'order_priority asc'
	validates_presence_of :name , :batch_id
end

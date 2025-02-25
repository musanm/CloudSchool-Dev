class Remark < ActiveRecord::Base
  belongs_to :remark_setting,:foreign_key=>'target_id',:class_name=>"RemarkSetting"
  has_many :remark_parameters,:dependent=>:destroy
  belongs_to :student
  belongs_to :user,:foreign_key=>'submitted_by'
  accepts_nested_attributes_for :remark_parameters, :allow_destroy => true
  
end

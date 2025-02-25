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
class FaGroup < ActiveRecord::Base
  has_many :fa_criterias
  has_and_belongs_to_many :subjects
  belongs_to :cce_exam_category
  has_many :cce_reports, :through=>:fa_criterias 

  named_scope :active,:conditions=>{:is_deleted=>false}

  #  validates_format_of :criteria_formula,:with=>/^((avg\([a-zA-Z](\,[a-zA-Z])+\))|(best\([0-9](\,[a-zA-Z]){2,32}\))|([a-zA-Z]))(([\+\-\*\/])((avg\([a-zA-Z](\,[a-zA-Z])+\))|(best\([0-9](\,[a-zA-Z]){2,32}\))|([a-zA-Z0-9])))*$/,:allow_blank=>true
  validates_format_of :criteria_formula,:with=>/^((avg\([A-Z](\,[A-Z])+\))|(best\([0-9](\,[A-Z]){2,32}\))|([A-Z]))(([\+\-\*\/])((avg\([A-Z](\,[A-Z])+\))|(best\([0-9](\,[A-Z]){2,32}\))|([A-Z0-9])))*$/,:allow_blank=>true
  def validate
    errors.add_to_base("Name can't be blank") unless self.name.present?
    errors.add_to_base("CCE exam category can't be blank") if self.cce_exam_category_id.blank?
    errors.add_to_base("Description can't be blank") if self.desc.blank?
  end
    
end

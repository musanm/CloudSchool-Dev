class IaCalculation < ActiveRecord::Base
  validates_presence_of :formula
  validates_format_of :formula,:with=>/^((avg\([A-Z](\,[A-Z])+\))|(best\([0-9](\,[A-Z]){2,32}\))|([A-Z]))(([\+\-\*\/])((avg\([A-Z](\,[A-Z])+\))|(best\([0-9](\,[A-Z]){2,32}\))|([A-Z0-9])))*$/
  #  validates_format_of :formula,:with=>/^((avg\([a-zA-Z](\,[a-zA-Z])+\))|(best\([0-9](\,[a-zA-Z]){2,32}\))|([a-zA-Z]))(([\+\-\*\/])((avg\([a-zA-Z](\,[a-zA-Z])+\))|(best\([0-9](\,[a-zA-Z]){2,32}\))|([a-zA-Z0-9])))*$/
  belongs_to :ia_group
end

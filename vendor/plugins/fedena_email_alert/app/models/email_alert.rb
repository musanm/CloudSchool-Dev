class EmailAlert < ActiveRecord::Base
 # validates_presence_of :model
 serialize :mail_to

  named_scope :active,{ :conditions => { :value=> true }}


  def self.defined_model(model)
     (model.to_s.camelize.constantize rescue nil).nil??false:true
  end

end

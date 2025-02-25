class ImportLogDetail < ActiveRecord::Base
  belongs_to :import
  
  def self.make_order(collection)
    collection.sort_by{|element| [element.model.to_i]}
  end
end

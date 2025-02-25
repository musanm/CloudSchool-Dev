module FedenaInventory
  def self.dependency_check(record,type)
    if type == "permanant"
      if record.class.to_s == "Employee"
        return true if Indent.count(:joins=>"LEFT OUTER JOIN `users` ON `users`.id = `indents`.user_id LEFT OUTER JOIN `users` managers_indents ON `managers_indents`.id = `indents`.manager_id",:conditions=>["(indents.user_id=? or indents.manager_id=?) and indents.is_deleted ='0'",record.user_id,record.user_id]) > 0
      end
    end
    return false
  end

  def self.csv_export_list
    return ["store", "store_items", "supplier"]
  end

  def self.csv_export_data(report_type,params)
    case report_type
    when "store"
      data = Store.store_data(params)
    when "store_items"
      data = StoreItem.store_items_data(params)
    when "supplier"
      data = Supplier.supplier_data(params)
    end
  end
end

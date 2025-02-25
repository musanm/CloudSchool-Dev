Gretel::Crumbs.layout do
  crumb :inventories_index do
    link I18n.t('grns.inventory'), {:controller=>"inventories", :action=>"index"}
  end
  crumb :store_categories_index do
    link I18n.t('store_categories.store_categories'), {:controller=>"store_categories", :action=>"index"}
    parent :inventories_index
  end
  crumb :store_categories_create do
    link I18n.t('store_categories.store_categories'), {:controller=>"store_categories", :action=>"index"}
    parent :inventories_index
  end
  crumb :store_categories_edit do
    link I18n.t('store_categories.store_categories'), {:controller=>"store_categories", :action=>"index"}
    parent :inventories_index
  end
  crumb :store_categories_update do
    link I18n.t('store_categories.store_categories'), {:controller=>"store_categories", :action=>"index"}
    parent :inventories_index
  end
  crumb :store_types_index do
    link I18n.t('store_types.store_types'), {:controller=>"store_types", :action=>"index"}
    parent :inventories_index
  end
  crumb :store_types_new do
    link I18n.t('store_types.store_types'), {:controller=>"store_types", :action=>"index"}
    parent :inventories_index
  end
  crumb :store_types_create do
    link I18n.t('store_types.store_types'), {:controller=>"store_types", :action=>"index"}
    parent :inventories_index
  end
  crumb :store_types_edit do
    link I18n.t('store_types.store_types'), {:controller=>"store_types", :action=>"index"}
    parent :inventories_index
  end
  crumb :store_types_update do
    link I18n.t('store_types.store_types'), {:controller=>"store_types", :action=>"index"}
    parent :inventories_index
  end
  crumb :stores_index do
    link I18n.t('stores.stores'), {:controller=>"stores", :action=>"index"}
    parent :inventories_index
  end
  crumb :stores_new do
    link I18n.t('stores.stores'), {:controller=>"stores", :action=>"index"}
    parent :inventories_index
  end
  crumb :stores_create do
    link I18n.t('stores.stores'), {:controller=>"stores", :action=>"index"}
    parent :inventories_index
  end
  crumb :stores_edit do
    link I18n.t('stores.stores'), {:controller=>"stores", :action=>"index"}
    parent :inventories_index
  end
  crumb :stores_update do
    link I18n.t('stores.stores'), {:controller=>"stores", :action=>"index"}
    parent :inventories_index
  end
  crumb :store_items_index do
    link I18n.t('inventories.store_items'), {:controller=>"store_items", :action=>"index"}
    parent :inventories_index
  end
  crumb :store_items_new do
    link I18n.t('new_text'), {:controller=>"store_items", :action=>"new"}
    parent :store_items_index
  end
  crumb :store_items_create do
    link I18n.t('new_text'), {:controller=>"store_items", :action=>"new"}
    parent :store_items_index
  end
  crumb :store_items_edit do |store_item|
    link "#{I18n.t('edit_text')} - #{store_item.item_name_was}", {:controller=>"store_items", :action=>"edit", :id => store_item.id}
    parent :store_items_index
  end
  crumb :supplier_types_index do
    link I18n.t('supplier_types.supplier_types'), {:controller=>"supplier_types", :action=>"index"}
    parent :inventories_index
  end
  crumb :supplier_types_new do
    link I18n.t('new_text'), {:controller=>"supplier_types", :action=>"new"}
    parent :supplier_types_index
  end
  crumb :supplier_types_create do
    link I18n.t('new_text'), {:controller=>"supplier_types", :action=>"new"}
    parent :supplier_types_index
  end
  crumb :supplier_types_edit do |supplier_type|
    link "#{I18n.t('edit_text')} - #{supplier_type.name_was}", {:controller=>"supplier_types", :action=>"edit", :id => supplier_type.id}
    parent :supplier_types_index
  end
  crumb :suppliers_index do
    link I18n.t('suppliers.suppliers'), {:controller=>"suppliers", :action=>"index"}
    parent :inventories_index
  end
  crumb :suppliers_new do
    link I18n.t('new_text'), {:controller=>"suppliers", :action=>"new"}
    parent :suppliers_index
  end
  crumb :suppliers_create do
    link I18n.t('new_text'), {:controller=>"suppliers", :action=>"new"}
    parent :suppliers_index
  end
  crumb :suppliers_show do |supplier|
    link supplier.name_was, {:controller=>"suppliers", :action=>"show", :id => supplier.id}
    parent :suppliers_index
  end
  crumb :suppliers_edit do |supplier|
    link I18n.t('edit_text'), {:controller=>"suppliers", :action=>"edit", :id => supplier.id}
    parent :suppliers_show, supplier
  end
  crumb :indents_index do
    link I18n.t('indents.indents'), {:controller=>"indents", :action=>"index"}
    parent :inventories_index
  end
  crumb :inventories_search do
    link I18n.t('indents.search'), {:controller=>"inventories", :action=>"search"}
    parent :indents_index
  end
  crumb :indents_new do
    link I18n.t('new_text'), {:controller=>"indents", :action=>"new"}
    parent :indents_index
  end
  crumb :indents_create do
    link I18n.t('new_text'), {:controller=>"indents", :action=>"new"}
    parent :indents_index
  end
  crumb :indents_show do |indent|
    link indent.indent_no_was, {:controller=>"indents", :action=>"show", :id => indent.id}
    parent :indents_index
  end
  crumb :indents_edit do |indent|
    link I18n.t('edit_text'), {:controller=>"indents", :action=>"edit", :id => indent.id}
    parent :indents_show, indent
  end
  crumb :purchase_orders_index do
    link I18n.t('purchase_orders.purchase_orders'), {:controller=>"purchase_orders", :action=>"index"}
    parent :inventories_index
  end
  crumb :purchase_orders_new do
    link I18n.t('new_text'), {:controller=>"purchase_orders", :action=>"new"}
    parent :purchase_orders_index
  end
  crumb :purchase_orders_create do
    link I18n.t('new_text'), {:controller=>"purchase_orders", :action=>"new"}
    parent :purchase_orders_index
  end
  crumb :purchase_orders_show do |purchase_order|
    link purchase_order.po_no_was, {:controller=>"purchase_orders", :action=>"show", :id => purchase_order.id}
    parent :purchase_orders_index
  end
  crumb :purchase_orders_edit do |purchase_order|
    link I18n.t('edit_text'), {:controller=>"purchase_orders", :action=>"edit", :id => purchase_order.id}
    parent :purchase_orders_show, purchase_order
  end
  crumb :grns_index do
    link I18n.t('purchase_orders.grn_text'), {:controller=>"grns", :action=>"index"}
    parent :inventories_index
  end
  crumb :purchase_orders_raised_grns do |purchase_order|
    link I18n.t('purchase_orders.grn_text'), {:controller=>"purchase_orders", :action=>"raised_grns", :id => purchase_order.id}
    parent :purchase_orders_show, purchase_order
  end
  crumb :grns_new do
    link I18n.t('new_text'), {:controller=>"grns", :action=>"new"}
    parent :grns_index
  end
  crumb :grns_create do
    link I18n.t('new_text'), {:controller=>"grns", :action=>"new"}
    parent :grns_index
  end
  crumb :grns_show do |grn|
    link grn.grn_no, {:controller=>"grns", :action=>"new", :id =>grn.id}
    parent :grns_index
  end
 
  crumb :purchase_orders_acceptance do |purchase_order|
    link "#{purchase_order.po_no} #{I18n.t('purchase_orders.acceptance')}", {:controller=>"purchase_orders", :action=>"acceptance", :id => purchase_order.id }
    parent :purchase_orders_index
  end
  crumb :grns_report do |date_range|
    link I18n.t('Inventory_account'), {:controller=>"grns",:action=>"report",:start_date=>date_range.first.to_date,:end_date=>date_range.last.to_date}
    parent :finance_update_monthly_report,date_range
  end

  crumb :report do |date_range|
    link I18n.t('SalesInventory_account'), {:controller=>"invoices",:action=>"report",:start_date=>date_range.first.to_date,:end_date=>date_range.last.to_date}
    parent :finance_update_monthly_report,date_range
  end
  crumb :grns_report_detail do |list|
    link list.first.finance_transaction.title, {:controller=>"instant_fees",:action=>"report_detail",:id => list.first.id, :start_date=>list.last.first.to_date,:end_date=>list.last.last.to_date}
    parent :grns_report,list.last
  end
  crumb :item_categories_index do
    link I18n.t('item_categories.item_category'), {:controller=>"item_categories", :action=>"index"}
    parent :inventories_index
  end
  crumb :item_categories_create do
    link I18n.t('item_categories.item_category'), {:controller=>"item_categories", :action=>"index"}
    parent :inventories_index
  end
  crumb :item_categories_edit do
    link I18n.t('item_categories.item_category'), {:controller=>"item_categories", :action=>"index"}
    parent :inventories_index
  end
  crumb :item_categories_update do
    link I18n.t('item_categories.item_category'), {:controller=>"item_categories", :action=>"index"}
    parent :inventories_index
  end
  crumb :invoices_index do
    link I18n.t('invoices.invoices'), {:controller=>"invoices", :action=>"index"}
    parent :inventories_index
  end
  crumb :invoices_new do
    link I18n.t('new_text'), {:controller=>"invoices", :action=>"new"}
    parent :invoices_index
  end
  crumb :invoices_edit do |invoice|
    link I18n.t('edit_text'), {:controller=>"invoices", :action=>"edit",:id => invoice.id}
    parent :invoices_index
  end
  crumb :inventory_reports_index do
    link I18n.t('reports'), {:controller=>"inventory_reports", :action=>"index"}
    parent :inventories_index
  end

   crumb :inventory_reports_reports do
    link "#{I18n.t('generate')} #{I18n.t('reports')}", {:controller=>"inventory_reports", :action=>"reports"}
    parent :inventory_reports_index
  end

  crumb :inventory_reports_sales_reports do
    link I18n.t('inventory_reports.sales_reports'), {:controller=>"inventory_reports", :action=>"sales_reports"}
    parent :inventory_reports_index
  end

  crumb :inventory_reports_item_wise_report do
    link "#{I18n.t('generate')} #{I18n.t('inventory_reports.item_wise_report')}", {:controller=>"inventory_reports", :action=>"item_wise_report"}
    parent :inventory_reports_sales_reports
  end


  crumb :inventory_reports_invoice_report do
    link "#{I18n.t('generate')} #{I18n.t('inventory_reports.invoice_report')}", {:controller=>"inventory_reports", :action=>"invoice_report"}
    parent :inventory_reports_sales_reports
  end

  crumb :inventory_reports_day_wise_report do
    link "#{I18n.t('generate')} #{I18n.t('inventory_reports.day_wise_report')}", {:controller=>"inventory_reports", :action=>"day_wise_report"}
    parent :inventory_reports_sales_reports
  end

  crumb :invoice_show do |invoice|
    link invoice.last.invoice_no, {:controller=>"invoices", :action=>"show", :id => invoice.last.id}
    if invoice[0].present?
      parent :report,[invoice[0],invoice[1]]
    else
      parent :invoices_index
    end
  end

  crumb :invoices_create do
    link I18n.t('stores.stores'), {:controller=>"invoices", :action=>"create"}
    parent :invoices_index
  end
  crumb :invoices_update do
    link I18n.t('edit_text'), {:controller=>"invoices", :action=>"update"}
    parent :invoices_index
  end

  crumb :item_categories_show do
    link I18n.t('item_categories.item_category'), {:controller=>"item_categories", :action=>"show"}
    parent :item_categories_index
  end
end

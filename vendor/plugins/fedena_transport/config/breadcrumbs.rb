Gretel::Crumbs.layout do
  crumb :transport_dash_board do
    link I18n.t('transport_text'), {:controller=>"transport", :action=>"dash_board"}
  end
  crumb :routes_index do
    link I18n.t('routes.route_details'), {:controller=>"routes", :action=>"index"}
    parent :transport_dash_board
  end
  crumb :routes_new do
    link I18n.t('routes.add_new_route'), {:controller=>"routes", :action=>"new"}
    parent :routes_index
  end
  crumb :routes_create do
    link I18n.t('routes.add_new_route'), {:controller=>"routes", :action=>"new"}
    parent :routes_index
  end
  crumb :routes_show do |route|
    link route.destination, {:controller=>"routes", :action=>"show",:id=>route.id}
    parent :routes_index
  end
  crumb :routes_edit do |route|
    link "#{I18n.t('edit_text')} - #{route.destination_was}", {:controller=>"routes", :action=>"edit", :id => route.id}
    parent :routes_index
  end
  crumb :vehicles_index do
    link I18n.t('transport.vehicles'), {:controller=>"vehicles", :action=>"index"}
    parent :transport_dash_board
  end
  crumb :vehicles_new do
    link I18n.t('vehicles.add_new_vehicle'), {:controller=>"vehicles", :action=>"new"}
    parent :vehicles_index
  end
  crumb :vehicles_show do |vehicle|
    link vehicle.vehicle_no, {:controller=>"vehicles", :action=>"show",:id=>vehicle.id}
    parent :vehicles_index
  end
  crumb :vehicles_create do
    link I18n.t('vehicles.add_new_vehicle'), {:controller=>"vehicles", :action=>"new"}
    parent :vehicles_index
  end
  crumb :vehicles_edit do |vehicle|
    link "#{I18n.t('edit_text')} - #{vehicle.vehicle_no_was}", {:controller=>"vehicles", :action=>"edit", :id => vehicle.id}
    parent :vehicles_index
  end
  crumb :transport_index do
    link I18n.t('transport.user_details'), {:controller=>"transport", :action=>"index"}
    parent :transport_dash_board
  end
  crumb :transport_transport_details do
    link I18n.t('transport.transport_details'), {:controller=>"transport", :action=>"transport_details"}
    parent :transport_dash_board
  end
  crumb :transport_edit_transport do |transport|
    link transport.receiver.full_name, {:controller=>"transport", :action=>"edit_transport", :id => transport.id}
    parent :transport_index
  end
  crumb :transport_add_transport do |user|
    link user.full_name, {:controller=>"transport", :action=>"add_transport", :id => user.id, :user => "employee"}
    parent :transport_index
  end
  crumb :transport_vehicle_report do
    link I18n.t('transport.vehicle_details'), {:controller=>"transport", :action=>"vehicle_report"}
    parent :transport_dash_board
  end
  crumb :transport_single_vehicle_details do |vehicle|
    link vehicle.vehicle_no, {:controller=>"transport", :action=>"single_vehicle_details", :id => vehicle.id}
    parent :transport_vehicle_report
  end
  crumb :transport_student_transport_details do |student|
    link I18n.t('transport.transport_details'), {:controller=>"transport", :action=>"student_transport_details", :id => student.id}
    parent :student_profile, student
  end
  crumb :transport_employee_transport_details do |employee|
    link I18n.t('transport.transport_details'), {:controller=>"transport", :action=>"employee_transport_details", :id => employee.id}
    parent :employee_profile, employee
  end
  crumb :transport_fee_index do
    link I18n.t('transport_fee_text'), {:controller=>"transport_fee", :action=>"index"}
    parent :transport_dash_board
  end
  crumb :transport_fee_transport_fee_collections do
    link I18n.t('transport_fee.fee_collection'), {:controller=>"transport_fee", :action=>"transport_fee_collections"}
    parent :transport_fee_index
  end
  crumb :transport_fee_transport_fee_collection_new do
    link "#{I18n.t('transport_fee.create_fee_collection_dates')} : #{I18n.t('batch')}-#{I18n.t('wise')}", {:controller=>"transport_fee", :action=>"transport_fee_collection_new"}
    parent :transport_fee_transport_fee_collections
  end
  crumb :transport_fee_collection_creation_and_assign do
    link "#{I18n.t('transport_fee.user_wise_fee_collections')}", {:controller=>"transport_fee", :action=>"collection_creation_and_assign"}
    parent :transport_fee_transport_fee_collections
  end

  crumb :transport_fee_allocate_or_deallocate_fee_collection do
    link "#{I18n.t('manage')}  #{I18n.t('fee_collection')}", {:controller=>"transport_fee", :action=>"allocate_or_deallocate_fee_collection"}
    parent :transport_fee_transport_fee_collections
  end


  crumb :transport_fee_transport_fee_collection_create do
    link I18n.t('transport_fee.create_fee_collection_dates'), {:controller=>"transport_fee", :action=>"transport_fee_collection_new"}
    parent :transport_fee_transport_fee_collections
  end
  crumb :transport_fee_transport_fee_collection_view do
    link I18n.t('transport_fee.view_transport_fee_collection_dates'), {:controller=>"transport_fee", :action=>"transport_fee_collection_view"}
    parent :transport_fee_transport_fee_collections
  end
  crumb :transport_fee_transport_fee_defaulters_view do
    link I18n.t('transport_fee.student_defaulters'), {:controller=>"transport_fee", :action=>"transport_fee_defaulters_view"}
    parent :transport_fee_pay_transport_fees
  end
  crumb :transport_fee_employee_defaulters_transport_fee_collection do
    link I18n.t('transport_fee.employee_defaulters'), {:controller=>"transport_fee", :action=>"employee_defaulters_transport_fee_collection"}
    parent :transport_fee_index
  end
  crumb :transport_fee_transport_fee_search do
    link I18n.t('transport.user_details'), {:controller=>"transport_fee", :action=>"transport_fee_search"}
    parent :transport_fee_pay_transport_fees
  end
  crumb :transport_fee_fees_student_dates do |student|
    link student.full_name, {:controller=>"transport_fee", :action=>"fees_student_dates", :id => student.id}
    parent :transport_fee_transport_fee_search
  end
  crumb :transport_fee_fees_employee_dates do |employee|
    link employee.full_name, {:controller=>"transport_fee", :action=>"fees_student_dates", :id => employee.id}
    parent :transport_fee_transport_fee_search
  end
  crumb :transport_fee_student_profile_fee_details do |fee|
    link I18n.t('transport_fee.transport_fee_status'), {:controller=>"transport_fee", :action=>"student_profile_fee_details", :id2 => fee.id, :id => fee.receiver_id}
    parent :student_fees, fee.receiver
  end
  crumb :transport_fee_transport_fees_report do |date_range|
    link I18n.t('transport_fee.transport_fees_report_small'), {:controller=>"transport_fee", :action=>"transport_fees_report",:start_date=>date_range.first.to_date,:end_date=>date_range.last.to_date}
    parent :finance_update_monthly_report,date_range
  end
  crumb :transport_fee_employee_transport_fees_report do |date_range|
    link I18n.t('report'), {:controller=>"transport_fee", :action=>"employee_transport_fees_report",:start_date=>date_range.first.to_date,:end_date=>date_range.last.to_date}
    parent :transport_fee_transport_fees_report,date_range
  end
  crumb :transport_fee_batch_transport_fees_report do |list|
    link list.first.full_name, {:controller=>"transport_fee", :action=>"batch_transport_fees_report",:start_date=>list.last.first.to_date,:end_date=>list.last.last.to_date}
    parent :transport_fee_transport_fees_report,list.last
  end

  crumb :transport_fee_user_wise_transport_fees_report do |list|
    link "#{I18n.t('user_text')} #{I18n.t('wise')} #{I18n.t('fee_collection')}", {:controller=>"transport_fee", :action=>"batch_transport_fees_report",:start_date=>list.last.first.to_date,:end_date=>list.last.last.to_date}
    parent :transport_fee_transport_fees_report,list.last
  end
  crumb :routes_add_additional_details do
    link I18n.t('routes.add_route_additional_details'), {:controller=>"routes",:action=>"add_additional_details"}
    parent :transport_dash_board
  end

  crumb :routes_edit_additional_details do
    link I18n.t('routes.edit_route_additional_details'), {:controller=>"routes",:action=>"edit_additional_details"}
    parent :transport_dash_board
  end


  crumb :vehicles_add_additional_details do
    link I18n.t('vehicles.add_vehicle_additional_details'), {:controller=>"vehicles",:action=>"add_additional_details"}
    parent :transport_dash_board
  end

  crumb :vehicles_edit_additional_details do
    link I18n.t('vehicles.edit_vehicle_additional_details'), {:controller=>"vehicles",:action=>"edit_additional_details"}
    parent :transport_dash_board
  end

  crumb :transport_fee_pay_transport_fees do
    link I18n.t('pay_fees'), {:controller=>"transport_fee", :action=>"pay_transport_fees"}
    parent :transport_fee_index
  end

  crumb :transport_fee_pay_batch_wise do
    link "#{I18n.t('batch')}-#{I18n.t('wise')}", {:controller=>"transport_fee", :action=>"pay_batch_wise"}
    parent :transport_fee_pay_transport_fees
  end
end

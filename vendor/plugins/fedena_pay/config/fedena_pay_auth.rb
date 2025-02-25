authorization do

  role :payment do
    has_permission_on [:online_payments],:to =>[
      :index
    ]
    has_permission_on [:payment_settings],:to=>[
      :settings,
      :show_gateway_fields,
      :return_to_fedena_pages,
      :index,
      :transactions,
      :show_transaction_details
    ]
    has_permission_on [:custom_gateways],:to=>[
      :index,
      :new,
      :create,
      :show
    ]
    has_permission_on [:custom_gateways],:to=>[:edit,:update,:destroy] do
      if_attribute :self_created => is {true}
    end
  end

  role :masteradmin do
    includes  :payment
  end

  role :admin do
    includes  :payment
  end

  role :general_settings do
    includes  :payment
  end

  role :student do
    has_permission_on [:finance], :to => [
      :student_fee_receipt_pdf
    ]
  end

  role :parent do
    has_permission_on [:finance], :to => [
      :student_fee_receipt_pdf
    ]
  end

end
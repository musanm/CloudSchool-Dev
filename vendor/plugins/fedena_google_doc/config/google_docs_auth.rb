authorization do
  role :admin do
    has_permission_on [:google_docs], :to => [:index, :upload]
  end

  role :employee do
    has_permission_on [:google_docs], :to => [:index, :upload]
  end
  
  role :student do
    has_permission_on [:google_docs], :to => [:index, :upload]
  end
  

end


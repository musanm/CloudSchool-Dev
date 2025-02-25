authorization do
  role :guest do
    has_permission_on :oauth, :to=>[:login,:new]
  end
end


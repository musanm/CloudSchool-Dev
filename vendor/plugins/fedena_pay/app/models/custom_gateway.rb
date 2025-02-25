class CustomGateway < ActiveRecord::Base
  serialize :gateway_parameters

  validates_presence_of :name,:gateway_parameters
  #validates_uniqueness_of :name

  before_save :make_params_hash

  def validate
    if self.gateway_parameters and (self.new_record? or self.gateway_parameters_changed?)
      config_names = []
      config_values = []
      self.gateway_parameters[:config_fields].values.each do|c|
        config_names.push(c[:name])
        config_values.push(c[:value])
      end
      self.errors.add_to_base("Configuration Field names cannot be duplicate.") unless config_names.uniq.length == config_names.length
      self.errors.add_to_base("target_url not specified in Configuration Fields.") unless config_names.include?("target_url")
      self.errors.add_to_base("Configuration Field name cannot be blank.") if config_names.select{|c| c.blank?}.count > 0
      self.errors.add_to_base("Configuration Value cannot be blank.") if config_values.select{|c| c.blank?}.count > 0
      variable_params_types = []
      variable_values = []
      self.gateway_parameters[:variable_fields].values.each do|a|
        variable_params_types.push(a[:field_type])
        variable_values.push(a[:name])
      end
      self.errors.add_to_base("Cannot assign duplicate values to same variable field.") unless variable_params_types.uniq.length == variable_params_types.length
      self.errors.add_to_base("Variable Field name cannot be blank.") if variable_values.select{|v| v.blank?}.count > 0
      self.errors.add_to_base("Variable Field for Amount cannot be empty.") unless variable_params_types.include?("amount")
      self.errors.add_to_base("Variable Field for Redirect URL cannot be empty.") unless variable_params_types.include?("redirect_url")
      response_params_types = []
      response_names = []
      self.gateway_parameters[:response_parameters].values.each do|r|
        response_params_types.push(r[:parameter_type])
        response_names.push(r[:name])
      end
      self.errors.add_to_base("Cannot assign duplicate values to same response field.") unless response_params_types.uniq.length == response_params_types.length
      self.errors.add_to_base("Response parameter for Amount cannot be empty.") unless response_params_types.include?("amount")
      self.errors.add_to_base("Response parameter for Success Code cannot be empty.") unless response_params_types.include?("success_code")
      self.errors.add_to_base("Response parameter for Transaction Reference cannot be empty.") unless response_params_types.include?("transaction_reference")
      self.errors.add_to_base("Response parameter for Transaction Status cannot be empty.") unless response_params_types.include?("transaction_status")
      self.errors.add_to_base("Response Parameter name cannot be blank.") if response_names.select{|r| r.blank?}.count > 0
    end
  end

  def make_params_hash
    if self.gateway_parameters and (self.new_record? or self.gateway_parameters_changed?)
      variable_parameters = Hash.new
      self.gateway_parameters[:variable_fields].values.each do|a|
        variable_parameters[a[:field_type]]=a[:name]
      end
      self.gateway_parameters[:variable_fields] = variable_parameters
      config_parameters = Hash.new
      self.gateway_parameters[:config_fields].values.each do|c|
        config_parameters[c[:name]]=c[:value]
      end
      self.gateway_parameters[:config_fields] = config_parameters
      response_parameters = Hash.new
      self.gateway_parameters[:response_parameters].values.each do|a|
        response_parameters[a[:parameter_type]]=a[:name]
      end
      self.gateway_parameters[:response_parameters] = response_parameters
    end
  end

  def remodel_params_hash
    if self.gateway_parameters
      if self.gateway_parameters[:variable_fields]
        variable_parameters = Hash.new
        i=0
        self.gateway_parameters[:variable_fields].each_pair do|k,v|
          h=Hash.new
          h["field_type"]=k
          h["name"]=v
          variable_parameters[i.to_s]=h
          i=i+1
        end
        self.gateway_parameters[:variable_fields] = variable_parameters
      end
      if self.gateway_parameters[:config_fields]
        config_parameters = Hash.new
        m=0
        self.gateway_parameters[:config_fields].each_pair do|k,v|
          c=Hash.new
          c["name"]=k
          c["value"]=v
          config_parameters[m.to_s] = c
          m=m+1
        end
        self.gateway_parameters[:config_fields] = config_parameters
      end
      if self.gateway_parameters[:response_parameters]
        response_parameters = Hash.new
        n=0
        self.gateway_parameters[:response_parameters].each_pair do|k,v|
          h=Hash.new
          h["parameter_type"]=k
          h["name"]=v
          response_parameters[n.to_s]=h
          n=n+1
        end
        self.gateway_parameters[:response_parameters] = response_parameters
      end
      return self
    end
  end

  def self.available_gateways
    CustomGateway.all(:conditions=>{:is_deleted=>false})
  end

  def self.own_gateways
    CustomGateway.available_gateways
  end

  def self_created
    CustomGateway.own_gateways.include?(self)
  end
end

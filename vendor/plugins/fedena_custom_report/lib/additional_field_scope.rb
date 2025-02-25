module AdditionalFieldScope

  def self.extended(base)
    base.class_eval do
      cattr_accessor :additional_field_methods
      base.additional_field_methods = base.get_additional_fields.collect{|af| (af.name.downcase.gsub(" ","_") + "_additional_fields_" + af.id.to_s).to_sym if af.name.to_i == 0 }.compact
      base.get_additional_fields.each do |af|
        if af.name.to_i == 0
          define_method ( af.name.downcase.gsub(" ","_") + "_additional_fields_" + af.id.to_s).to_sym do
            res = self.send(self.class.additional_detail_table).detect { |a| a.send(base.additional_field_model_foreign_key) == af.id }
            res ? "#{res.additional_info}" : ""
          end
        end        
      end
      
    end
  end

  def get_additional_fields
    additional_field_model ? additional_field_model.all(:conditions=>{:status=>true}) : []
  end
  def additional_field_model
    base = self
    base_name=self.to_s.underscore
    additional_detail_table = [base_name,"additional_details"].join("_").to_sym
    additional_field_table = [base_name,"additional_field"].join("_").to_sym
    additional_field_model = nil

    if base.reflect_on_association(additional_detail_table)
      additional_detail_model = base.reflect_on_association(additional_detail_table).klass
      if additional_detail_model.reflect_on_association(additional_field_table)
        additional_field_model = additional_detail_model.reflect_on_association(additional_field_table).klass
      elsif additional_detail_model.reflect_on_association(:additional_field)
        additional_field_model = additional_detail_model.reflect_on_association(:additional_field).klass
      end
    end
    additional_field_model
  end
  def additional_field_model_foreign_key
    base = self
    base_name=self.to_s.underscore
    additional_detail_table = [base_name,"additional_details"].join("_").to_sym
    additional_field_table = [base_name,"additional_field"].join("_").to_sym
    additional_field_model_foreign_key = nil

    if base.reflect_on_association(additional_detail_table)
      additional_detail_model = base.reflect_on_association(additional_detail_table).klass
      if additional_detail_model.reflect_on_association(additional_field_table)
        additional_field_model_foreign_key = additional_detail_model.reflect_on_association(additional_field_table).primary_key_name
      elsif additional_detail_model.reflect_on_association(:additional_field)
        additional_field_model_foreign_key = additional_detail_model.reflect_on_association(:additional_field).primary_key_name
      end
    end
    additional_field_model_foreign_key
  end

  def additional_detail_table
    base_name=name.to_s.underscore
    [base_name,"additional_details"].join("_").to_sym
  end
  def additional_detail_model
    adm = self.reflect_on_association(additional_detail_table)
    adm ? adm.klass : nil
  end
  def additional_detail_model_foreign_key
    adm = self.reflect_on_association(additional_detail_table)
    adm ? adm.primary_key_name : nil
  end
  def report_search(*args)
    opts=args.extract_options!
    additional_field_params=opts.delete :additional_field_params
    args << opts
    unless additional_field_params.nil?
      with_scope(:find=>additional_field_params) do
        super(*args)
      end
    else
      super(*args)
    end
  end
end

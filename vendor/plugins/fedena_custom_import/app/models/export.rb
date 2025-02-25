class Export < ActiveRecord::Base
  
  serialize :structure
  serialize :associated_columns
  serialize :join_columns

  default_scope :order => "created_at DESC"
  
  MODELS = [["Employee Admission","Employee"],["Student Admission","Student"],["Guardian Addition","Guardian"],["Student Attendance","Attendance"],["Student Exam Scores","ExamScore"]]

  validates_presence_of :name
  validates_uniqueness_of :name

  has_many :imports

  class << self
    def get_models
      models = Array.new
      models = MODELS
      if FedenaPlugin.accessible_plugins.include? "fedena_library"
        models.push(["Library Book","Book"])
      end
      if FedenaPlugin.accessible_plugins.include? "fedena_inventory"
        models.push(["Store Item","StoreItem"],["Supplier","Supplier"],["Store","Store"])
      end
      models.uniq
    end
    
    def get_attributes(model)
      if model=='Student'
        attributes = (model.constantize.column_names - ["id","created_at","updated_at","class_roll_no","photo_updated_at"]).map{|column| column.to_s + "|#{model.to_s}"}
      else
        attributes = (model.constantize.column_names - ["id","created_at","updated_at","photo_updated_at"]).map{|column| column.to_s + "|#{model.to_s}"}
      end
      [attributes,model]
    end

    def load_yaml(model)
      if File.exists?("#{Rails.root}/vendor/plugins/fedena_custom_import/config/models/#{model.underscore}.yml")
        exports = YAML.load_file(File.join(Rails.root,"vendor/plugins/fedena_custom_import/config/models","#{model.underscore}.yml"))
      end
      exports
    end


    def process_attributes(model)
      attributes = get_attributes(model)
      settings = load_yaml(model)
      filter_attributes = settings[model.underscore].nil? ? Array.new : settings[model.underscore]["filters"].map{|filter| filter.to_s + "|#{model.to_s}"}
      attr_accessor_list = (settings[model.underscore].present? and settings[model.underscore]["attr_accessor_list"].present?) ? settings[model.underscore]["attr_accessor_list"].map{|attr| attr.to_s + "|#{model.to_s}"} : Array.new
      csv_attributes = (attributes.first + attr_accessor_list) - filter_attributes
      csv_attributes
    end

    def place_overrides(model)
      attributes = process_attributes(model)
      settings = load_yaml(model)
      override_attributes = Hash.new
      unless settings[model.underscore].nil?
        override_attributes = settings[model.underscore]["overrides"]
      end
      
      attributes.each do |attribute|
        attribute_name = attribute.split('|').first

        if override_attributes.present? and override_attributes.keys.include? attribute_name.to_s
          attribute_override = attribute.gsub(attribute_name,override_attributes[attribute_name])
          attributes[attributes.index(attribute)] = attribute_override
        else
          attribute_override = attribute.gsub(attribute_name,attribute_name.humanize)
          attributes[attributes.index(attribute)] = attribute_override
        end
      end
      attributes
    end

    def prepare_associated_columns(model,associated_models)
      settings = load_yaml(model)
      associated_model_hash_values = settings[model.underscore]["associates"].nil? ? Array.new : settings[model.underscore]["associates"].select{|key,value| associated_models.include? key }
      header = Array.new
      associated_model_hash_values.each do |associated_model|
        header_model = associated_model.second.camelize.constantize
        if header_model.column_names.include? "name"
          if header_model.scopes.keys.include? :active
            header_columns = header_model.active.all.map(&:name).map{|column| column + "|#{associated_model.first.to_s}|asscoiate"}.compact.flatten
          else
            header_columns = header_model.all.map(&:name).map{|column| column + "|#{associated_model.first.to_s}|asscoiate"}.compact.flatten
          end
        else
          raise "Name column not found in the model."
        end
        header << header_columns
      end
      header.flatten.compact
    end

    def prepare_join_columns(model,join_models)
      settings = load_yaml(model)
      join_model_hash_values = settings[model.underscore]["joins"].nil? ? Array.new : settings[model.downcase]["joins"].select{|key,value| join_models.include? key }
      header = Array.new
      join_model_hash_values.each do |join_model|
        header_model = join_model.first.singularize.camelize.constantize
        if header_model.column_names.include? "name"
          if header_model.column_names.include? "is_active"
            header_columns = header_model.all(:conditions => {:is_active => true}).map(&:name).map{|column| column + "|#{join_model.first.to_s}|join"}.compact.flatten
          else
            header_columns = header_model.all.map(&:name).map{|column| column + "|#{join_model.first.to_s}|join"}.compact.flatten
          end
        else
          raise "Name column not found in the model."
        end
        header << header_columns
      end
      header.flatten.compact
    end

    def make_final_columns_set(model,all_columns,join_columns)
      final_columns = Array.new
      core_columns = self.process_attributes(model)
      associated_columns = (all_columns - join_columns)
      final_columns = associated_columns.nil? ? core_columns : core_columns + associated_columns
      final_columns = join_columns.nil? ? core_columns : core_columns + join_columns
      final_columns = final_columns.flatten.compact
      associated_columns = associated_columns.flatten.compact
      join_columns = join_columns.flatten.compact
      [final_columns,associated_columns,join_columns]
    end
    
    def load_fastercsv(header_data,model)
      settings = load_yaml(model)
      injectable_columns = Array.new
      csv_data = FasterCSV.generate do |csv|
        core_columns =  self.place_overrides(model)
        associated_columns = header_data
        header_column = associated_columns.nil? ? core_columns : core_columns + associated_columns
        header_column = header_column.map{|column| "#{column.split('|').first}|#{column.split('|').second.underscore.humanize}"}.flatten.compact
        if settings[model.underscore]["inject"].present?
          injectable_columns = settings[model.underscore]["inject"].map{|injectable_column| "#{injectable_column.to_s.humanize}|inject"}
        end
        csv << injectable_columns + header_column
      end
      [csv_data,model]
    end 
  end
end
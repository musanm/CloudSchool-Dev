class Import < ActiveRecord::Base
  require 'set'
  require 'fileutils'
  include EditCustomImport
  attr_accessor :file_path,:job_type,:row_counter

  has_attached_file :csv_file,
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:basename.:extension",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[] #add correct csv file format

  belongs_to :export
  has_many :import_log_details,:dependent => :destroy

  default_scope :order => "created_at DESC"
  named_scope :editable_imports,:conditions=>{:is_edit=>true}

  def perform
    if is_edit
      build_core_data_on_edit(self.csv_file.to_file.path)
    else
      build_core_data(self.csv_file.to_file.path)
    end
    prev_record = Configuration.find_by_config_key("job/Import/#{self.job_type}")
    if prev_record.present?
      prev_record.update_attributes(:config_value=>Time.now)
    else
      Configuration.create(:config_key=>"job/Import/#{self.job_type}", :config_value=>Time.now)
    end
  end

  def csv_save(upload)
    self.csv_file = upload
    self.save
  end



  def build_core_data(file)
    settings = load_yaml
    model_name = export.model.constantize
    core_rows = Array.new
    header_row = Array.new
    inject_rows = Array.new
    if check_header_format(file) == true
      if FasterCSV.read(file).size > 1
        i = 0
        FasterCSV.foreach(file) do |csv_row|
          new_model_instance = model_name.new
          value_hash = Hash.new
          if i == 0
            header_row = csv_row
            core_rows = csv_row.select{|element| element.split('|').second.to_s.downcase.gsub(' ','_').camelize.to_s == model_name.to_s }
            inject_rows = csv_row.select{|element| element.split('|').second.to_s.downcase.gsub(' ','_').to_s == "inject" }
          else
            core_rows.each do |core_row|
              self.row_counter = i + 1
              index = header_row.index(core_row)
              database_row_name = settings[model_name.to_s.underscore]["overrides"].select{|key,value| value.to_s == core_row.split('|').first.to_s}.first.nil? ? nil : settings[model_name.to_s.underscore]["overrides"].select{|key,value| value.to_s == core_row.split('|').first.to_s}.first.first unless settings[model_name.to_s.underscore]["overrides"].nil?
              database_row_name = core_row.split('|').first.downcase.gsub(' ','_') if database_row_name.nil?
              process_row = database_row_name.dup
              process_row.slice! "_id"
              assoc = settings[model_name.to_s.underscore]["associations"].present? ? settings[model_name.to_s.underscore]["associations"].find{|assoc| process_row.pluralize.index(assoc.to_s)==0 } : Array.new
              process_row = assoc ? assoc : process_row
              if settings[model_name.to_s.underscore]["associations"].present? and settings[model_name.to_s.underscore]["associations"].include? process_row.to_sym

                if settings[model_name.to_s.underscore]["map_combination"].present? and settings[model_name.to_s.underscore]["map_combination"].keys.include? process_row.to_s
                  map_method = settings[model_name.to_s.underscore]["map_combination"][process_row.to_s]
                  scope_to_apply = process_row.to_s.camelize.constantize.scopes.keys.include? :active
                  all_data = scope_to_apply == true ? process_row.to_s.camelize.constantize.active.map{|data| [data.id,data.send(map_method)]} : process_row.to_s.camelize.constantize.all.map{|data| [data.id,data.send(map_method)]}
                  associated_id = all_data.select{|data| data.second == csv_row[index]}.first.nil? ? nil : all_data.select{|data| data.second == csv_row[index]}.first.first
                else
                  assoc_reflection = model_name.reflect_on_association(process_row.to_sym)
                  associated_model = assoc_reflection.klass
                  associated_column = settings[model_name.to_s.underscore]["associated_columns"][process_row.to_s]
                  primary_key = model_name.reflect_on_association(process_row.to_sym).options[:foreign_key] || :id
                  associated_id =  case assoc_reflection.macro
                  when :belongs_to
                    associated_model.search({associated_column.to_sym => csv_row[index]}).first.try(primary_key)
                  else
                    assoc_reflection.klass.search({associated_column.to_sym => csv_row[index]}).first.try(primary_key)
                  end
                end
                value_hash = value_hash.merge(database_row_name.to_sym => associated_id)
              else
                if settings[model_name.to_s.underscore]["booleans"].present? and settings[model_name.to_s.underscore]["booleans"].include? database_row_name.to_sym
                  if csv_row[index].present?
                    value_hash = value_hash.merge(database_row_name.to_sym => 1)
                  else
                    value_hash = value_hash.merge(database_row_name.to_sym => 0)
                  end
                else
                  if (settings[model_name.to_s.underscore]["attr_accessor_list"].present? and settings[model_name.to_s.underscore]["attr_accessor_list"].include? database_row_name.to_sym)
                    value_hash = value_hash.merge(database_row_name.to_sym => csv_row[index])
                  else
                    if model_name.columns_hash[database_row_name].sql_type == "varchar(255)"
                      csv_row[index] = csv_row[index].nil? ? "" : csv_row[index]
                    end
                    value_hash = value_hash.merge(database_row_name.to_sym => csv_row[index])
                  end
                end
              end
            end

            unless inject_rows.blank?
              if settings[model_name.to_s.underscore]["inject"].present? and settings[model_name.to_s.underscore]["finders"].present?
                value_hash = process_injections(model_name,value_hash,inject_rows,header_row,csv_row)
              end
            end
            new_model_instance = model_name.new(value_hash)
            if settings[model_name.to_s.underscore]["mandatory_joins"].present?
              new_model_instance = build_join_data(new_model_instance,csv_row,header_row)
            end
            if new_model_instance.present? and new_model_instance.valid?
              if new_model_instance.save
                build_associate_data(new_model_instance,csv_row,header_row)
              else
                self.import_log_details.create(:status => t('imports.failed'),:model => self.row_counter,:description => "#{new_model_instance.errors.full_messages.join(", ")}") unless new_model_instance.nil?
              end
            else
              self.import_log_details.create(:status => t('imports.failed'),:model => self.row_counter,:description => "#{new_model_instance.errors.full_messages.join(", ")}") unless new_model_instance.nil?
            end
          end
          i += 1
        end
        if import_log_details.all.select{|ild| ild.status == t('imports.failed')}.blank?
          self.status = t('imports.success')
        else
          self.status = t('imports.completed_with_errors')
        end
        self.csv_file = nil
        self.save
      else
        self.status = t('imports.succes_with_no_data')
        self.csv_file = nil
        self.save
      end
    else
      self.status = t('imports.failed')
      self.csv_file = nil
      self.save
      self.import_log_details.create(:status => t('imports.failed'),:model => self.row_counter,:description => t('import_log_details.export_format_not_matching'))
    end
  rescue Exception => e
    self.status = "#{t('imports.failed')} : #{e.message}"
    self.save
  end



  def build_associate_data(new_model_instance,csv_row,header_row)
    settings = load_yaml
    flag = 0
    associated_models = settings[new_model_instance.class.name.underscore]["associates"].nil? ? Array.new : settings[new_model_instance.class.name.underscore]["associates"].keys
    associated_models.each do |associated_model|
      associated_model_name = associated_model.camelize.constantize
      associated_rows = header_row.select{|element| element.split('|').second.to_s.downcase.gsub(' ','_' ).to_s == associated_model.to_s }
      search_model = settings[new_model_instance.class.name.underscore]["associates"][associated_model].camelize.constantize
      search_column = settings[new_model_instance.class.name.underscore]["associate_column_search"][search_model.to_s.underscore]
      insert_column = settings[new_model_instance.class.name.underscore]["associate_columns"][associated_model]
      if settings[new_model_instance.class.name.underscore]["associate_column_condition"].present?
        column_condition = settings[new_model_instance.class.name.underscore]["associate_column_condition"][search_model.to_s.underscore]
      end
      associated_rows.each do |associated_row|
        index = header_row.index(associated_row)
        search_row = associated_row.split('|').first
        if associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).present? and associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).options.present? and associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).options[:foreign_key].present?
          child_associate_column = associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).options[:foreign_key]
        else
          child_associate_column = search_model.to_s.underscore + "_id"
        end
        if column_condition.nil?
          associate_value_id = search_model.find(:first,:conditions => {search_column.to_sym => search_row}).try(:id)
        else
          associate_value_id = search_model.find(:first,:conditions => ["#{search_column} = ? AND #{column_condition}", search_row]).try(:id)
        end
        new_associate_record = new_model_instance.send(associated_model.pluralize).new(insert_column.to_sym => csv_row[index].nil? ? nil : csv_row[index].gsub('|', ', '),(child_associate_column).to_sym => associate_value_id)
        if new_associate_record.valid?
          new_associate_record.save
        else
          flag = 1
          self.import_log_details.create(:status => t('imports.failed'),:model => self.row_counter,:description => "#{new_associate_record.errors.full_messages.join("\n")}")
        end
      end
    end
    if flag == 0
      unless settings[new_model_instance.class.name.to_s.underscore]["mandatory_joins"].present?
        build_join_data(new_model_instance,csv_row,header_row)
      end
    elsif flag == 1
      associated_models.map{|associated_model| new_model_instance.send(associated_model.pluralize).all.map{|element| element.destroy}}
      if settings[new_model_instance.class.name.underscore]["dependent"].present?
        new_model_instance.send(settings[new_model_instance.class.name.underscore]["dependent"]).try(:destroy)
      end
      new_model_instance.destroy
    end
  end


  def self.default_time_zone_present_time(time_stamp)
    server_time = time_stamp
    server_time_to_gmt = server_time.getgm
    local_tzone_time = server_time
    time_zone = Configuration.find_by_config_key("TimeZone")
    unless time_zone.nil?
      unless time_zone.config_value.nil?
        zone = TimeZone.find(time_zone.config_value)
        if zone.difference_type=="+"
          local_tzone_time = server_time_to_gmt + zone.time_difference
        else
          local_tzone_time = server_time_to_gmt - zone.time_difference
        end
      end
    end
    return local_tzone_time
  end
end





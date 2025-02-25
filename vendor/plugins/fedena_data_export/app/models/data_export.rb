class DataExport < ActiveRecord::Base
  require 'fileutils'
  require 'nokogiri'

  belongs_to :export_structure
  attr_accessor :job_type,:model_ids,:blank_file

  validates_presence_of :file_format

  has_attached_file :export_file,
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :url => "/data_exports/:id/download_export_file",
    :max_file_size => 52428800,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]

  validates_attachment_size :export_file, :less_than => 52428800,\
    :message=>'must be less than 50 MB.',:if=> Proc.new { |p| p.export_file_file_name_changed? }

  class DataExportValidationError < StandardError
  end

  def status_message
    case status
    when 'Success'
      status
    when 'In progress','In progess'
      'In progress'
    else
      'Failed'
    end
  end

  def perform
    begin
      @export_file_str = "tmp/#{Time.now.strftime("%H%M%S%d%m%Y")}_#{export_structure.model_name}.#{file_format}"
      remove_old_entry
      make_file
      self.export_file = File.open(@export_file_str)
      raise DataExportValidationError, self.errors.full_messages unless save
    rescue Exception=>e
      self.reload
      self.update_attribute(:status,e.message)
    ensure
      File.delete(@export_file_str) if File.exist?(@export_file_str)
    end

    prev_record = Configuration.find_by_config_key("job/DataExport/#{self.job_type}")
    if prev_record.present?
      prev_record.update_attributes(:config_value=>Time.now)
    else
      Configuration.create(:config_key=>"job/DataExport/#{self.job_type}", :config_value=>Time.now)
    end
  end

  def remove_old_entry
    update_attributes(:status => "In progress")
    data_export = export_structure.data_export
    if (data_export.present? and data_export.id != id)
      export_structure.data_export.destroy
    end
  end

  def make_file
    file_format == "csv" ? make_csv_file : make_xml_file
    update_attributes(:status => "Success")
  end

  def check_database
    export_structure.model_name.camelize.constantize.first.nil?
  end

  def make_blank_xml_file
    @file << '<?xml version="1.0" encoding="UTF-8"?><xml_error_detail><xml_error><error>Blank Database</error></xml_error></xml_error_detail>'
    update_attributes(:status => "Success")
  end

  def get_template
    if export_structure.plugin_name.nil?
      template_file = ERB.new File.new("#{Rails.root}/app/views#{export_structure.template}").read, 0, ">"
    else
      template_file = ERB.new File.new("#{Rails.root}/vendor/plugins/#{export_structure.plugin_name}/app/views#{export_structure.template}").read, 0, ">"
    end
    template_file
  end

  def make_xml_file
    @file = open(@export_file_str,'w')
    if check_database
      make_blank_xml_file
    else
      i = 0
      xml_start_tag = String.new
      xml_close_tag = String.new
      export_structure.model_name.camelize.constantize.send(export_structure.make_query.first,export_structure.make_query.second.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}) do |block_datas|
        instance_variable_set("@" + export_structure.model_name.pluralize,block_datas)
        @xml = Builder::XmlMarkup.new
        template_file = get_template
        xml_file_content = template_file.result(get_binding)
        made_xml = make_xml_data(xml_file_content)
        xml_start_tag = made_xml.second
        xml_close_tag = made_xml.third
        xml_data = made_xml.first
        start_xml_file(xml_start_tag) if i == 0
        append_file_data(xml_data)
        i += 1
        break if export_structure.model_name == "configuration"
      end
      finish_xml_file(xml_close_tag)
    end
    @file.close
  end

  def make_xml_data(xml_file_content)
    xml_data = delete_xml_content_info(xml_file_content.to_s)
    xml_data = delete_start_xml_tag(xml_data)
    start_tag = xml_data.second
    xml_data = delete_closing_xml_tag(xml_data.first)
    closing_tag = xml_data.second
    xml_data = xml_data.first
    [xml_data,start_tag,closing_tag]
  end

  def delete_closing_xml_tag(xml_file_content)
    xml_file_content = xml_file_content.reverse
    slice_index = xml_file_content.index('<')
    end_tag = xml_file_content.slice!(0,slice_index + 1).reverse
    [xml_file_content.reverse,end_tag]
  end

  def delete_start_xml_tag(xml_file_content)
    xml_file_content = xml_file_content
    slice_index = xml_file_content.index('>')
    start_tag = xml_file_content.slice!(0,slice_index + 1)
    [xml_file_content,start_tag]
  end

  def delete_xml_content_info(xml_file_content)
    xml_file_content = xml_file_content.gsub('<?xml version="1.0" encoding="UTF-8"?>',"")
  end

  def start_xml_file(xml_start_tag)
    @file << '<?xml version="1.0" encoding="UTF-8"?>'
    @file << xml_start_tag
  end

  def append_file_data(file_content)
    @file << file_content
  end

  def finish_xml_file(xml_close_tag)
    @file << xml_close_tag
  end

  def default_block_data_count
    export_structure.query[export_structure.query.keys.first][:batch_size]
  end

  def make_csv_file
    make_xml_file
    xml_content = open(@export_file_str).read
    hash = ActiveSupport::OrderedHash.from_xml(xml_content)
    array_datas = hash[hash.keys.first][hash[hash.keys.first].keys.first]
    raw_headers = array_datas.is_a?(Hash) ? array_datas.keys : array_datas.first.keys
    default_headers = check_database ? raw_headers : export_structure.csv_header_order
    final_headers = check_database ? raw_headers : default_headers & raw_headers
    headers = final_headers.map(&:humanize)
    @file = FasterCSV.open(@export_file_str, "w") do |csv|
      csv << headers
      if array_datas.is_a? Array
        array_datas.each do |array_data|
          values = Array.new
          final_headers.each do |header|
            if array_data[header].is_a? HashWithIndifferentAccess
              values.push(make_table(array_data[header]))
            else
              values.push(array_data[header])
            end
          end
          csv << values
          break if export_structure.model_name == "configuration"
        end
      else
        values = Array.new
        final_headers.each do |header|
          values.push(array_datas[header])
        end
        csv << values
      end
    end
  end

  def make_table(table_data)
    extracted_data = table_data[table_data.keys.first]
    table_headers = (extracted_data.is_a? Array) ? extracted_data.first.keys : extracted_data.keys
    new_table = FasterCSV::Table.new([FasterCSV::Row.new(table_headers.map(&:humanize),Array.new)])
    table_array_datas = table_data[table_data.keys.first]
    if table_array_datas.is_a? Array
      table_array_datas.each do |data|
        values = Array.new
        table_headers.each do |table_header|
          values.push(data[table_header].to_s)
        end
        new_table << (FasterCSV::Row.new(table_headers,values))
      end
    else
      values = Array.new
      table_headers.each do |table_header|
        values.push(table_array_datas[table_header])
      end
      new_table << (FasterCSV::Row.new(table_headers,values))
    end
    new_table
  end

  def get_binding
    binding
  end
end



class Report < ActiveRecord::Base
  
  has_many :report_queries,:dependent => :destroy
  has_many :report_columns,:dependent => :destroy

  accepts_nested_attributes_for  :report_columns
  accepts_nested_attributes_for :report_queries,
    :reject_if => proc { |attributes|
    attributes['query'].blank? and (attributes['date_query(1i)'].blank? or
        attributes['date_query(2i)'].blank? or
        attributes['date_query(3i)'].blank?)
  }

  validates_presence_of :name, :report_columns, :report_queries

  def after_initialize
    unless model_object.nil?
      model_object.extend JoinScope
      model_object.extend AdditionalFieldScope
    end
  end
  
  def search_param
    sp={}
    self.report_queries.each do |rq|
      sp[rq.query_string]= rq.query unless ['join','additional'].include? rq.column_type
    end
    sp[:join_params]=join_params
    sp[:additional_field_params]=additional_field_params
    sp
  end
  
  def join_params
    jp={}
    cond={}
    join_queries=report_queries.group_by(&:column_type)['join']
    unless join_queries.blank?
      join_queries = join_queries.group_by(&:table_name)
      jp[:joins] = join_queries.keys.collect{|k| eval(k).table_name.singularize.to_sym}
      join_queries.each do |k,rqs|
        cond[k]=[]
        rqs.each do |rq|
          cond[k] << rq.make_query
        end
      end
      q_str=[]
      cond.values.each do |str|
        q_str << "(#{str.join(" OR ")})"
      end
      jp[:conditions]=[q_str.join(" AND ")]
    end
    jp
  end

  def additional_field_params
    ap={}
    cond={}
    additional_field_queries = report_queries.group_by(&:column_type)['additional']
    unless additional_field_queries.blank?
      additional_field_queries = additional_field_queries.group_by(&:table_name)
      ap[:joins] = additional_field_queries.keys.collect{|k| eval(k).table_name.to_sym}
      additional_field_queries.each do |k,rqs|
        cond[k]=[]
        rqs.each do |rq|
          cond[k] << rq.make_query_for_additional_field
        end
      end
      query_strings=[]
      query_values = []
      cond.values.each do |str|
        queries = []
        str.each{|s| queries << s.first; query_values << s[1..-1]}
        query_strings << "(#{queries.join(" OR ")})"
      end
      ap[:conditions]=[query_strings.join(" OR ")] + query_values.flatten
    end
    ap
  end
 
  def include_param
    ip=[]
    model_name = Kernel.const_get(self.model)
    self.report_columns.each do |rc|
      model_name.fields_to_search[:association].each do |as|
        case as
        when Symbol
          (ip << as) if rc.method.include? as.to_s
        when Hash
          (ip << as) if (as.keys+as.values).include? rc.method.to_sym
        end
      end
      (ip << rc.association_method.to_sym) if rc.association_method.present?
      (ip << self.model_object.additional_detail_table) if rc.method.to_s.include?("_additional_fields_")
    end
    ip.uniq
  end
  def to_csv
    csv = FasterCSV.generate do |csv|
      cols = [t('sl_no')]
      self.report_columns.each{|rc| cols << rc.title}
      csv << cols
      table_name = Kernel.const_get(model.to_sym).table_name
      search_results = model_object.report_search(self.search_param).all(:include=>self.include_param,:group => "#{table_name}.id")
      search_results.each_with_index do |obj,serial_no|
        fields_hash = {}
        obj.class.columns_hash.collect{|x,y| fields_hash[x]=y.type}
        assocition_methods = self.report_columns.collect(&:association_method).compact.reject(&:empty?)
        row_span_count = assocition_methods.empty? ? 1 : assocition_methods.each_with_object([]) { |i, ar| ar << (obj.send(i).to_a.count == 0 ? 1 : obj.send(i).to_a.count) }.max
        count = 0
        while count < row_span_count
          cols = []
          cols << (count == 0 ? "#{serial_no + 1}" : " ")
          self.report_columns.each do |col|
            unless col.association_method.present?
              value = (count == 0 ? "#{obj.send(col.method)}" : "")
            else
              value = "#{obj.send(col.association_method)[count].nil? ? "" : obj.send(col.association_method)[count].send(col.method)}"
            end
            case fields_hash[col.method]
            when :date
              value = format_date(value)
            when :datetime
              value = format_date(value,:format=>:short_date)
            when :time
              value = format_date(value,:format=>:time)
            end
            cols << value
          end
          count += 1
          csv << cols
        end
      end
    end
    csv
  end

  def model_object
    Kernel.const_get(self.model) unless self.model.nil?
  end
end
  

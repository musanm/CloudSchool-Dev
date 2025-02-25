class CustomReportsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  before_filter :find_and_check_model,:only=>[:generate,:edit]
  def find_and_check_model
   
    @model_name = params[:id].camelize.singularize
    unless ["Student","Employee"].include? @model_name
      flash[:notice] = "#{t(@model_name.underscore)} #{t('report_cannot_be_generated')}"
      redirect_to :action=>:index
      return
    else
      @model = Kernel.const_get(@model_name)
    end
  end  
  def index
    @reports=Report.find(:all,:order =>'name ASC').paginate(:page => params[:page], :per_page => 20)
  end

  def generate    
    @report=Report.new
    @report.model = @model_name
    @model.extend JoinScope
    @model.extend AdditionalFieldScope
    @search_fields = @model.fields_to_search.deep_copy
    make_report_columns
    @search_fields.each do |type,columns|
      case type
      when :string
        columns.each do |col|
          ["like","begins_with","equals"].each do |criteria|
            @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>criteria,:column_type=>type,:field_name=>col)
          end
        end
      when :date
        columns.each do |col|
          ["gte","lte","equals"].each do |criteria|
            @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>criteria,:column_type=>type,:field_name=>col)
          end
        end
      when :association
        columns.each do |col|
          case col
          when Symbol
            @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>"in",:column_type=>type,:field_name=>col)
          when Hash
            @report.report_queries.build(:table_name => @model_name,:column_name=>col.keys.first,:criteria=>"in",:column_type=>type,:field_name=>col.keys.first)
          end
        end
      when :boolean
        columns.each do |col|
          @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>"is",:column_type=>type,:field_name=>col)
        end
      when :integer
        columns.each do |col|
          ["gte","lte","equals"].each do |criteria|
            @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>criteria,:column_type=>type,:field_name=>col)
          end
        end
      end

    end
    @search_fields[:additional]= @model.additional_field_methods
    @model.get_additional_fields.each do |f|
      if f.name.to_i == 0
        ["equals"].each do |criteria|
          @report.report_queries.build(:table_name => @model.additional_detail_model.to_s,:column_name=>f.id,:criteria=>criteria,:column_type=>:additional,:field_name=>( f.name.downcase.gsub(" ","_") + "_additional_fields_" + f.id.to_s))
        end
      end
    end
    @assoc_value = @report.report_queries.select{|rq| rq.column_type == :association}.inject({}){|hash,r| hash.merge(r.column_name.to_s => r.values_for_associations.map{|a| {"label" => a.to_s,"id" => a.id}})}
    if request.post?
      @report = Report.new(params[:report])
      if @report.save
        flash[:notice]="#{t('report_created_successfully')}"
        redirect_to :action => "index"
      else
        render :action => "generate"
      end
    end
    
  end

  def edit
    @report=Report.find params[:id]
    @model_name=@report.model
    @all_columns=@model.fields_to_search
  end

  def show
    @report=Report.find params[:id]
    @report_columns = @report.report_columns
    @report_columns.delete_if{|rc| rc.association_method.nil? and !((@report.model_object.instance_methods+@report.model_object.column_names).include?(rc.method))}
    @report_columns.delete_if{|rc| rc.association_method.present? and @report.model_object.instance_methods.include? rc.association_method and !((rc.association_method_object.instance_methods+rc.association_method_object.column_names).include?(rc.method))}
    @column_type = Hash.new
    @report.model_object.columns_hash.each{|key,val| @column_type[key]=val.type }
    search = @report.model_object.report_search(@report.search_param)
    table_name = Kernel.const_get(@report.model.to_sym).table_name
    @search_results = search.paginate(:include=>@report.include_param,:page=>params[:page],:group => "#{table_name}.id")
  end

  def to_csv
    report=Report.find params[:id]
    report_columns = report.report_columns
    report_columns.delete_if{|rc| rc.association_method.nil? and !((report.model_object.instance_methods+report.model_object.column_names).include?(rc.method))}
    report_columns.delete_if{|rc| rc.association_method.present? and report.model_object.instance_methods.include? rc.association_method and !((rc.association_method_object.instance_methods+rc.association_method_object.column_names).include?(rc.method))}
    csv = report.to_csv
    filename = "#{report.name}-#{Time.now.to_date.to_s}.csv"
    send_data(csv, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end
  
  def delete
    if Report.destroy params[:id]
      flash[:notice]="#{t('report_deleted_successfully')}."
    else
      flash[:notice]="#{t('report_delete_error')}."
    end
    redirect_to :action=>'index'
  end
 

  private

  def make_report_columns
    @model.fields_to_display.each do |col|
      case col
      when Symbol
        @report.report_columns.build(:method=>col,:title=>t(col),:association_method => nil)
      when Hash
        col.each do |key,value|
          value.each do |v|
            @report.report_columns.build(:method=>v,:title=>t((key.to_s + "_" + v.to_s).to_sym), :association_method => key)
          end
        end
      end
    end
    @model.additional_field_methods.each do |col|
      @report.report_columns.build(:method=>col,:title=>col.to_s.titleize)
    end
  end
end

class ImportsController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def new
    @export = Export.find(params[:id])
    @import = @export.imports.build
  end

  if Rails.env.production? or Rails.env.development?
    rescue_from FasterCSV::MalformedCSVError do |exception|
      @import.errors.add_to_base "Wrong file format.Please select a CSV file only to upload"
      respond_to do |format|
        format.html {render :new}
      end
    end
  end

  def create
    @export = Export.find(params[:import][:export_id])
    @import = @export.imports.build(params[:import])
    unless params[:csv_file].nil?
      read_file = FasterCSV.read(params[:csv_file].path)
      if read_file.size <= 251
        @import.csv_save(params[:csv_file])
        @import.reload
        paperclip_var = @import.instance_variable_get :@_paperclip_attachments
        paperclip_var.delete :csv_file
        @import.job_type = "1"
        Delayed::Job.enqueue(@import)
        flash[:notice]="Data import in queue for export <b>#{@export.name}</b>. <a href='/scheduled_jobs/Import/1'>Click Here</a> to view the scheduled job."
        redirect_to imports_path(:export_id => @export.id)
      else
        flash[:error] = "Too large CSV file.Maximum 200 rows can be present."
        redirect_to new_import_path(:id => @export.id)
      end
    else
      @import.errors.add_to_base :no_file_uploaded
      render :new
    end
  end

  def index
    @export = Export.find(params[:export_id])
    @imports = @export.imports.all.paginate :per_page=>20,:page => params[:page], :order => 'created_at DESC'
  end

  def edit
     @export = Export.find(params[:id])
  end

  def create_import_for_edit
   @export = Export.find(params[:import][:export_id])
   @import=@export.imports.editable_imports.build(params[:import])

    unless params[:csv_file].nil?
      read_file = FasterCSV.read(params[:csv_file].path)
      if read_file.size <= 251
        @import.csv_save(params[:csv_file])
        @import.reload
        paperclip_var = @import.instance_variable_get :@_paperclip_attachments
        paperclip_var.delete :csv_file
        @import.job_type = "1"
        Delayed::Job.enqueue(@import)
        flash[:notice]="Data import in queue for export <b>#{@export.name}</b>. <a href='/scheduled_jobs/Import/1'>Click Here</a> to view the scheduled job."
        redirect_to imports_path(:export_id => @export.id)
      else
        flash[:error] = "Too large CSV file.Maximum 200 rows can be present."
        redirect_to edit_import_path(:id => @export.id)
      end
    else
      @import.errors.add_to_base :no_file_uploaded
      render :edit
    end
  end

  def filter
    @export = Export.find(params[:export_id])
    filter_param = params[:filter_imports]
    if filter_param == "all"
      @imports = @export.imports.all.paginate :per_page=>20,:page => params[:imports_page]
    elsif filter_param == "failed"
      @imports = @export.imports.find(:all,:conditions => {:status => "Failed"}).paginate :per_page=>20,:page => params[:imports_page]
    elsif filter_param == "completed"
      @imports = @export.imports.find(:all,:conditions => {:status => "Complete with errors"}).paginate :per_page=>20,:page => params[:imports_page]
    elsif filter_param == "success"
      @imports = @export.imports.find(:all,:conditions => {:status => "Success"}).paginate :per_page=>20,:page => params[:imports_page]
    end
    render :update do |page|
      page.replace_html "list_imports",:partial => "list_imports"
    end
  end
end

class ImportLogDetailsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  def index
    @import = Import.find(params[:import_id])
    @import_log_details_ordered = ImportLogDetail.make_order(@import.import_log_details)
    @import_log_details = @import_log_details_ordered.paginate :per_page=> 20,:page => params[:page]
  end

  def filter
    @import = Import.find(params[:import_id])
    filter_param = params[:filter_import_log_details]
    if filter_param == "all"
      @import_log_details = @import.import_log_details.all.paginate :per_page=>20,:page => params[:import_log_details_page]
    elsif filter_param == "failed"
      @import_log_details = @import.import_log_details.find(:all,:conditions => {:status => "Failed"}).paginate :per_page=>20,:page => params[:import_log_details_page]
    elsif filter_param == "success"
      @import_log_details = @import.import_log_details.find(:all,:conditions => {:status => "Success"}).paginate :per_page=>20,:page => params[:import_log_details_page]
    else
      @import_log_details = @import.import_log_details.all.paginate :per_page=>20,:page => params[:import_log_details_page]
    end
    render :update do |page|
      page.replace_html "list_import_log_details",:partial => "list_import_log_details"
    end
  end

end

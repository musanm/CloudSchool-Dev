class BankDetailsController < ApplicationController
  before_filter :login_required
  layout "application"
  # GET /bank_details
  # GET /bank_details.xml
  
  def index
    # school = School.find_by_name(Configuration.get_config_value('InstitutionName'))
    school = SchoolDetail.first.school
    if school.present? 
      @bank_details = BankDetail.find_all_by_school_id(school.id)
    else
      @bank_details = []
    end
  end

  # GET /bank_details/1
  # GET /bank_details/1.xml
  def show

    @bank_detail = BankDetail.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @bank_detail }
    end
  end

  # GET /bank_details/new
  # GET /bank_details/new.xml
  def new
    #school = School.find_by_name(Configuration.get_config_value('InstitutionName'))
    @bank_detail = BankDetail.new
  end

  # GET /bank_details/1/edit
  def edit
    @bank_detail = BankDetail.find(params[:id])
  end

  # POST /bank_details
  # POST /bank_details.xml
  def create
    @bank_detail = BankDetail.new(params[:bank_detail])
    # school = School.find_by_name(Configuration.get_config_value('InstitutionName'))
    school = SchoolDetail.first.school
    @bank_detail.school_id = school.id
    respond_to do |format|
      if @bank_detail.save
        format.html { redirect_to bank_details_path, :notice => 'BankDetail was successfully created.' }
        format.xml  { render :xml => @bank_detail, :status => :created, :location => @bank_detail }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @bank_detail.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /bank_details/1
  # PUT /bank_details/1.xml
  def update
    @bank_detail = BankDetail.find(params[:id])

    respond_to do |format|
      if @bank_detail.update_attributes(params[:bank_detail])
        format.html { redirect_to bank_details_path, :notice => 'BankDetail was successfully updated.' }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @bank_detail.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /bank_details/1
  # DELETE /bank_details/1.xml
  def destroy
    @bank_detail = BankDetail.find(params[:id])
    @bank_detail.destroy

    respond_to do |format|
      format.html { redirect_to(bank_details_url) }
      format.xml  { head :ok }
    end
  end
end

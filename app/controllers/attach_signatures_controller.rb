class AttachSignaturesController < ApplicationController
  
  layout "application"
  before_filter :login_required
  
  def index
    school = SchoolDetail.first.try(:school)
    # school = School.find_by_name(Configuration.get_config_value('InstitutionName'))
    if school.present? 
      @attach_signatures = school.attach_signatures
    else
      @attach_signatures = []
    end
  end

  def show
    @attach_signature = AttachSignature.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @attach_signature }
    end
  end

  def new
    @attach_signature = AttachSignature.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @attach_signature }
    end
  end

  def edit
    @attach_signature = AttachSignature.find(params[:id])
  end

  def create
    @attach_signature = AttachSignature.new(params[:attach_signature])
    school = SchoolDetail.first.try(:school)
    # school = School.find_by_name(Configuration.get_config_value('InstitutionName'))
    @attach_signature.school_id = school.id
    respond_to do |format|
      if @attach_signature.save
        format.html { redirect_to(attach_signatures_path, :notice => 'AttachSignature was successfully created.') }
        format.xml  { render :xml => @attach_signature, :status => :created, :location => @attach_signature }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @attach_signature.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @attach_signature = AttachSignature.find(params[:id])
    respond_to do |format|
      if @attach_signature.update_attributes(params[:attach_signature])
        format.html { redirect_to(attach_signatures_path, :notice => 'AttachSignature was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @attach_signature.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @attach_signature = AttachSignature.find(params[:id])
    @attach_signature.destroy

    respond_to do |format|
      format.html { redirect_to(attach_signatures_path) }
      format.xml  { head :ok }
    end
  end
end

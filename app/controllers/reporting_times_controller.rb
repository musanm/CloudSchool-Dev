class ReportingTimesController < ApplicationController
  before_filter :login_required
  before_filter :set_school
  layout "application"
  # GET /reporting_times
  # GET /reporting_times.xml
  def index
    @reporting_times = ReportingTime.all
    @in_times = ReportingTime.find(:all, :conditions => {:is_in_time => true, :school_id => @school.id })
    @out_times = ReportingTime.find(:all, :conditions => {:is_in_time => nil, :school_id => @school.id })
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @reporting_times }
    end
  end

  # GET /reporting_times/1
  # GET /reporting_times/1.xml
  def show
    redirect_to reporting_times_path
    @reporting_time = ReportingTime.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @reporting_time }
    end
  end

  # GET /reporting_times/new
  # GET /reporting_times/new.xml
  def new
    @reporting_time = ReportingTime.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @reporting_time }
    end
  end

  # GET /reporting_times/1/edit
  def edit
    @reporting_time = ReportingTime.find(params[:id])
  end

  # POST /reporting_times
  # POST /reporting_times.xml
  def create
    @reporting_time = ReportingTime.new(params[:reporting_time])
    @reporting_time.school_id = @school.id
    respond_to do |format|
      if @reporting_time.save
        format.html { redirect_to(reporting_times_path, :notice => 'ReportingTime was successfully created.') }
        format.xml  { render :xml => @reporting_time, :status => :created, :location => @reporting_time }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @reporting_time.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /reporting_times/1
  # PUT /reporting_times/1.xml
  def update
    @reporting_time = ReportingTime.find(params[:id])
    @reporting_time.school_id = @school.id
    respond_to do |format|
      if @reporting_time.update_attributes(params[:reporting_time])
        format.html { redirect_to(reporting_times_path, :notice => 'ReportingTime was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @reporting_time.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /reporting_times/1
  # DELETE /reporting_times/1.xml
  def destroy
    @reporting_time = ReportingTime.find(params[:id])
    @reporting_time.destroy

    respond_to do |format|
      format.html { redirect_to(reporting_times_url) }
      format.xml  { head :ok }
    end
  end

  private

  def set_school
    @school = SchoolDetail.first.school
  end
end

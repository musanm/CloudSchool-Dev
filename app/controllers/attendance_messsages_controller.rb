class AttendanceMesssagesController < ApplicationController

  layout "application"
  before_filter :login_required
  before_filter :initialize_data

  def index
    redirect_to attendance_messsage_path(@attendance_messsage)
    # @attendance_messsages = AttendanceMesssage.all

    # respond_to do |format|
    #   format.html # index.html.erb
    #   format.xml  { render :xml => @attendance_messsages }
    # end
  end

  def show
    @attendance_messsage = AttendanceMesssage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @attendance_messsage }
    end
  end

  def new
    @attendance_messsage = AttendanceMesssage.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @attendance_messsage }
    end
  end

  def edit
    @attendance_messsage = AttendanceMesssage.find(params[:id])
  end

  def create
    @attendance_messsage = AttendanceMesssage.new(params[:attendance_messsage])

    respond_to do |format|
      if @attendance_messsage.save
        format.html { redirect_to(@attendance_messsage, :notice => 'AttendanceMesssage was successfully created.') }
        format.xml  { render :xml => @attendance_messsage, :status => :created, :location => @attendance_messsage }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @attendance_messsage.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /attendance_messsages/1
  # PUT /attendance_messsages/1.xml
  def update
    @attendance_messsage = AttendanceMesssage.find(params[:id])

    respond_to do |format|
      if @attendance_messsage.update_attributes(params[:attendance_messsage])
        format.html { redirect_to(@attendance_messsage, :notice => 'AttendanceMesssage was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @attendance_messsage.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /attendance_messsages/1
  # DELETE /attendance_messsages/1.xml
  def destroy
    @attendance_messsage = AttendanceMesssage.find(params[:id])
    @attendance_messsage.destroy

    respond_to do |format|
      format.html { redirect_to(attendance_messsages_url) }
      format.xml  { head :ok }
    end
  end

  private

  def initialize_data
    @school = SchoolDetail.first.try(:school)
    @attendance_messsage = AttendanceMesssage.find_by_school_id(@school)
    return if @attendance_messsage.present?
    in_message = "Dear parent: Entrance for [[NAME]] was recorded at [[TIME]]"
    out_message = "Dear parent: Exit for [[NAME]] was recorded at [[TIME]]"
    absent_message = "Dear parent, [[NAME]] is absent on [[TIME]]. Thanks!"
    @attendance_messsage = AttendanceMesssage.create(:in_message => in_message, :out_message => out_message, :absent_message => absent_message, :school_id => @school.id)
    @attendance_messsage.save
  end
end

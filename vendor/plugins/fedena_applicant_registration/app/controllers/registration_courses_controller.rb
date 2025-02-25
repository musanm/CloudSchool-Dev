class RegistrationCoursesController < ApplicationController
  before_filter :login_required
  before_filter :set_precision
  filter_access_to :all


  def index
    @registration_courses = RegistrationCourse.find(:all,:order => "courses.course_name",:joins => :course).paginate(:page => params[:page],:per_page => 30)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @registration_courses }
    end
  end

  # GET /registration_courses/1
  # GET /registration_courses/1.xml
  def show
    @courses = Course.active.select{|c| c.registration_course.nil?}
    @registration_courses = RegistrationCourse.all

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @registration_course }
    end
  end

  # GET /registration_courses/new
  # GET /registration_courses/new.xml
  def new
    @registration_course = RegistrationCourse.new
    @additional_fields = StudentAdditionalField.active
    @courses = Course.active.select{|c| c.registration_course.nil?}

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @registration_course }
    end
  end

  # GET /registration_courses/1/edit
  def edit
    @registration_course = RegistrationCourse.find(params[:id])
    @additional_fields = StudentAdditionalField.active
    @courses = Course.active.select{|c| c.registration_course.nil?}
  end

  # POST /registration_courses
  # POST /registration_courses.xml
  def create
    @courses = Course.active.select{|c| c.registration_course.nil?}
    @registration_course = RegistrationCourse.new(params[:registration_course])
    @additional_fields = StudentAdditionalField.active

    respond_to do |format|
      if @registration_course.save
        @registration_course.manage_pin_system(params[:is_pin_enabled])
        flash[:notice] = t('create_successfully')
        format.html { redirect_to(:action=>"index") }
        format.xml  { render :xml => @registration_course, :status => :created, :location => @registration_course }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @registration_course.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /registration_courses/1
  # PUT /registration_courses/1.xml
  def update
    @courses = Course.active.select{|c| c.registration_course.nil?}
    @registration_course = RegistrationCourse.find(params[:id])
    @additional_fields = StudentAdditionalField.active
    unless params[:registration_course][:additional_field_ids].present?
      params[:registration_course] = params[:registration_course].merge(:additional_field_ids => [])
    end
    respond_to do |format|
      if @registration_course.update_attributes(params[:registration_course])
        @registration_course.manage_pin_system(params[:is_pin_enabled])
        flash[:notice] = t('update_successfully')
        format.html { redirect_to(:action=>"index") }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @registration_course.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /registration_courses/1
  # DELETE /registration_courses/1.xml
  def destroy
    @registration_course = RegistrationCourse.find(params[:id])
    if @registration_course.destroy
      flash[:notice] = t('deleted_successfully')
    else
      flash[:warn_notice] = @registration_course.errors.full_messages.join('. ')
    end
    respond_to do |format|
      format.html { redirect_to(:action=>"index") }
      format.xml  { head :ok }
    end
  end

  def toggle
    @registration_course = RegistrationCourse.find(params[:id])
    @registration_course.update_attributes(:is_active=>!@registration_course.is_active)
    redirect_to(:action=>"index")
  end

  def amount_load
    render :update do |page|
      settings = params[:settings]
      if settings == "0"
        page.replace_html "amount",:partial => "amount"
      elsif settings == "1" or settings.blank?
        page.replace_html "amount",:text => ""
      end
    end
  end

  def settings_load
    render :update do |page|
      settings = params[:settings]
      if settings == "1"
        page.replace_html "extra_settings",:partial => "extra_settings"
      elsif settings == "0" or settings.blank?
        page.replace_html "extra_settings",:text => ""
      end
    end
  end

  def populate_additional_field_list
    @additional_fields = StudentAdditionalField.active
    render :update do |page|
      if params[:settings] == "1"
        page.replace_html "additional_fields",:partial => "student_additional_fields"
      else
        page.replace_html "additional_fields",:text => ""
      end
    end
  end
end

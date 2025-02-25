class TermExamsController < ApplicationController

  layout "application"
  before_filter :login_required
  
  def index
  	@courses = Course.find(:all,:conditions => { :is_deleted => false }, :order => 'course_name asc')
  	@term_exams = @courses.map(&:batches).flatten.map(&:term_exams).flatten
    #@term_exams = TermExam.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @term_exams }
    end
  end

  def show
    @term_exam = TermExam.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @term_exam }
    end
  end

  def new
    @courses = Course.find(:all,:conditions => { :is_deleted => false }, :order => 'course_name asc')
    @batches = @courses.map(&:batches).flatten.map {|b| [b.full_name, b.id]}
    @term_exam = TermExam.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @term_exam }
    end
  end

  def edit
    @courses = Course.find(:all,:conditions => { :is_deleted => false }, :order => 'course_name asc')
    @batches = @courses.map(&:batches).flatten.map {|b| [b.full_name, b.id]}
    @term_exam = TermExam.find(params[:id])
  end

  def create
    @courses = Course.find(:all,:conditions => { :is_deleted => false }, :order => 'course_name asc')
    @batches = @courses.map(&:batches).flatten.map {|b| [b.full_name, b.id]}
    @term_exam = TermExam.new(params[:term_exam])

    respond_to do |format|
      if @term_exam.save
        format.html { redirect_to(term_exams_path, :notice => 'TermExam was successfully created.') }
        format.xml  { render :xml => @term_exam, :status => :created, :location => @term_exam }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @term_exam.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @courses = Course.find(:all,:conditions => { :is_deleted => false }, :order => 'course_name asc')
    @batches = @courses.map(&:batches).flatten.map {|b| [b.full_name, b.id]}
    @term_exam = TermExam.find(params[:id])

    respond_to do |format|
      if @term_exam.update_attributes(params[:term_exam])
        format.html { redirect_to(term_exams_path, :notice => 'TermExam was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @term_exam.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @term_exam = TermExam.find(params[:id])
    @term_exam.destroy

    respond_to do |format|
      format.html { redirect_to(term_exams_url) }
      format.xml  { head :ok }
    end
  end
end

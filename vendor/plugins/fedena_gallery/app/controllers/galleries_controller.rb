class GalleriesController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
    if current_user.employee?
      @privilege=Privilege.find_by_name("Gallery")
      if current_user.privileges.find(:all, :conditions=>{:id=>@privilege.id}).present?
        @has_permission=current_user.privileges.find(@privilege.id)
      end
    end
    if current_user.admin? or @has_permission.present? or current_user.has_gallery_privileges?
      if params[:id]
        @tags=GalleryTag.all(:conditions=>{:member_type=>"Student", :member_id=> params[:id]})
        @images=GalleryPhoto.find(@tags.map {|s| s.gallery_photo_id})
        @categories=GalleryCategory.find(@images.map {|s| s.gallery_category_id})
      else
        @categories=GalleryCategory.find(:all)
      end
    else
      if current_user.student?
        @student=current_user.student_record
        @tags=GalleryTag.all(:conditions=>{:member_type=>"Student", :member_id=> @student.id})
        #@tags=@student.gallery_tags
        @images=GalleryPhoto.find(@tags.map {|s| s.gallery_photo_id})
        @categories=GalleryCategory.find(@images.map {|s| s.gallery_category_id})
      else
        @employee=current_user.employee_record
        @tags=GalleryTag.all(:conditions=>{:member_type=>"Employee", :member_id=> @employee.id})
        #@tags=@employee.gallery_tags
        @images=GalleryPhoto.find(@tags.map {|s| s.gallery_photo_id})
        @categories=GalleryCategory.find(@images.map {|s| s.gallery_category_id})
      end
    end
  end

  def category_new
    @category=GalleryCategory.new
  end

  def category_create
    @category=GalleryCategory.new(params[:category])
    if @category.save
      flash[:notice] ="#{t('category_created')}"
      redirect_to :action=>"category_show", :id=>@category.id
    else
      render 'category_new'
    end
  end

  def category_show
    @category=GalleryCategory.find(params[:id])
    if current_user.employee?
      @privilege=Privilege.find_by_name("Gallery")
      if current_user.privileges.find(:all, :conditions=>{:id=>@privilege.id}).present?
        @has_permission=current_user.privileges.find(@privilege.id)
      end
    end
    if current_user.admin? or @has_permission.present? or current_user.has_gallery_privileges?
      @photos=@category.gallery_photos
    elsif current_user.student?
      @student=current_user.student_record
      @photo_tags=GalleryTag.all(:conditions=>{:member_type=>"Student", :member_id=> @student.id})
      @photos=GalleryPhoto.find(@photo_tags.map {|s| s.gallery_photo_id})
    else
      @employee=current_user.employee_record
      @photo_tags=GalleryTag.all(:conditions=>{:member_type=>"Employee", :member_id=> @employee.id})
      @photos=GalleryPhoto.find(@photo_tags.map {|s| s.gallery_photo_id})
    end
  end

  def category_edit
    @category=GalleryCategory.find(params[:id])
  end

  def category_update
    @category=GalleryCategory.find(params[:id])
    if @category.update_attributes(params[:category])
      flash[:notice] ="#{t('successfully_updated')}"
      redirect_to :action=>"category_show", :id=>@category
    else
      render :action=>"category_edit"
    end
  end

  def category_delete
    @category=GalleryCategory.find(params[:id])
    @category.destroy
    flash[:notice] ="#{t('successfully_deleted')}"
    redirect_to :action=>"index"
  end

  def photo_add
    @categories=GalleryCategory.all
    @photo=GalleryPhoto.new
  end

  def photo_create
    @categories=GalleryCategory.all
#    @photo=GalleryPhoto.new(params[:photo])
    @photo=GalleryPhoto.new(params[:gallery_photo])
    @photo.gallery_category_id=params[:select_category][:category] unless params[:select_category].nil?
    if @photo.save
      recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
      recipients_array.each do |r|
        employee=Employee.find(r)
        GalleryTag.create(:gallery_photo_id => @photo.id, :member => employee)
      end
      recipients_array = params[:recipients1].split(",").collect{ |s| s.to_i }
      recipients_array.each do |r|
        student=Student.find(r)
        GalleryTag.create(:gallery_photo_id => @photo.id, :member => student)
      end
      flash[:notice] = "#{t('photo_uploaded')}"

      redirect_to :action=>"category_show",:id=>@photo.gallery_category_id
    else
      @recipients=Employee.find(params[:recipients].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },:order=>"first_name ASC") if params[:recipients].present?
      @recipients1=Student.active.find(params[:recipients1].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },:order=>"first_name ASC") if params[:recipients1].present?
      render 'photo_add'
    end
  end

  def add_photo
    @category=GalleryCategory.find(params[:id])
    @photo=@category.gallery_photos.build
  end

  def create_photo
    @category=GalleryCategory.find(params[:id])
    @photo=@category.gallery_photos.build(params[:gallery_photo])
    if @photo.save
      recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
      recipients_array.each do |r|
        employee=Employee.find(r)
        GalleryTag.create(:gallery_photo_id => @photo.id, :member => employee)
      end
      recipients_array = params[:recipients1].split(",").collect{ |s| s.to_i }
      recipients_array.each do |r|
        student=Student.find(r)
        GalleryTag.create(:gallery_photo_id => @photo.id, :member => student)
      end
      flash[:notice] = "#{t('photo_uploaded')}"

      redirect_to :action=>"category_show",:id=>@category.id
    else
      @recipients=Employee.find(params[:recipients].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },:order=>"first_name ASC") if params[:recipients].present?
      @recipients1=Student.active.find(params[:recipients1].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },:order=>"first_name ASC") if params[:recipients1].present?
      render 'add_photo'
    end
  end

  def edit_photo
    @photo=GalleryPhoto.find(params[:id])
    @students=Student.find(:all)
    @employees=Employee.find(:all)
    @tags_emp=GalleryTag.find(:all,:conditions=>{:member_type=>"Employee",:gallery_photo_id=>@photo.id}).map{ |s| s.member_id}
    @recipients_emp= @tags_emp.compact.join(',')
    @tags_stu=GalleryTag.find(:all,:conditions=>{:member_type=>"Student",:gallery_photo_id=>@photo.id}).map{ |s| s.member_id}
    @recipients_stu= @tags_stu.compact.join(',')
    @recipients=Employee.find_all_by_id(@recipients_emp.split(",")).sort_by{|a| a.full_name.downcase}
    @recipients1=Student.find_all_by_id(@recipients_stu.split(",")).sort_by{|a| a.full_name.downcase}
    if request.post?
      if @photo.update_attributes(params[:photo])
        @flag=0
        recipients_emp = params[:recipients_emp].split(",").collect{ |s| s.to_i }
        recipients_stu = params[:recipients_stu].split(",").collect{ |s| s.to_i }
        recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
        recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
        recipients_emp.each do |r|
          employee=Employee.find(r)
          tag=GalleryTag.find(:all,:conditions=>{:gallery_photo_id => @photo.id, :member_id => employee,:member_type=>"Employee"}).first
          tag.destroy
        end
        recipients_stu.each do |r|
          student=Student.find(r)
          tag=GalleryTag.find(:all,:conditions=>{:gallery_photo_id => @photo.id, :member_id => student,:member_type=>"Student"}).first
          tag.destroy
        end

        recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
        recipients_array.each do |r|
          employee=Employee.find(r)
          GalleryTag.create(:gallery_photo_id => @photo.id, :member => employee)
        end
        recipients_array = params[:recipients1].split(",").collect{ |s| s.to_i }
        recipients_array.each do |r|
          student=Student.find(r)
          GalleryTag.create(:gallery_photo_id => @photo.id, :member => student)
        end
        flash[:notice] = "#{t('photo_updated')}"
        redirect_to :action=>"category_show",:id=>@photo.gallery_category_id
      else
        @recipients=Employee.find(params[:recipients].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },:order=>"first_name ASC") 
        @recipients1=Student.active.find(params[:recipients1].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },:order=>"first_name ASC")
        render 'edit_photo' 
      end
    end
  end
  def photo_delete
    @photo=GalleryPhoto.find(params[:id])
    @photo.destroy
    flash[:notice] ="#{t('successfully_deleted')}"
    redirect_to :action=>"category_show", :id=>@photo.gallery_category_id
  end

  def download_image
    file=GalleryPhoto.find(params[:id])
    if params[:style].to_s=="thumb"
      send_file file.photo.path(:thumb), :type => file.photo_content_type, :disposition => 'inline'
    else
      send_file file.photo.path, :type => file.photo_content_type, :disposition => 'inline'
    end
  end

  def show_image
    file=GalleryPhoto.find(params[:id])
    send_file file.photo.path(:thumb), :type => file.photo_content_type, :disposition => 'inline'
  end
  def select_employee_department
    @user = current_user
    @departments = EmployeeDepartment.active_and_ordered
    render :partial=>"select_employee_department"
  end

  def select_users
    @user = current_user
    users = User.active.find(:all, :conditions=>"student = false")
    @to_users = users.map { |s| s.id unless s.nil? }
    render :partial=>"to_users", :object => @to_users
  end

  def select_student_course
    @user = current_user
    @batches = Batch.active
    render :partial=> "select_student_course"
  end

  def to_employees
    unless params[:dept_id] == ""
      department = EmployeeDepartment.find(params[:dept_id])
      employees  = department.employees.all(:order => "first_name")
      @to_users = employees.map { |s| s.id unless s.nil? }
      render :update do |page|
        page.replace_html 'to_users', :partial => 'to_users'
      end
    else
      render :update do |page|
        page.replace_html "to_users", :text => ""
      end
    end
  end
  
  def to_students
    unless params[:batch_id] == ""
      batch = Batch.find(params[:batch_id])
      students = batch.students.all(:order => "first_name")
      @to_users = students.map { |s| s.id unless s.nil? }
      @to_users.delete nil
      render :update do |page|
        page.replace_html 'to_users2', :partial => 'to_users_1', :object => @to_users
      end
    else
      render :update do |page|
        page.replace_html "to_users2", :text => ""
      end
    end
  end
  def update_recipient_list
    if params[:recipients]
      @recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
      @recipients = Employee.find_all_by_id(@recipients_array.uniq).sort_by{|a| a.full_name.downcase}
      render :update do |page|
        page.replace_html 'recipient-list', :partial => 'recipient_list'
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end
  
  def update_recipient_list1
    if params[:recipients1]
      @recipients_array = params[:recipients1].split(",").collect{ |s| s.to_i }
      @recipients1 = Student.find(@recipients_array).sort_by{|a| a.full_name.downcase}
      render :update do |page|
        page.replace_html 'recipient-list1', :partial => 'recipient_list_1'
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end

end

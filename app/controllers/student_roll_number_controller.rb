class StudentRollNumberController < ApplicationController
  before_filter :login_required
  filter_access_to :all,:attribute_check=>true, :load_method => lambda { current_user }

  def index
    @courses = Course.active.paginate(:page => params[:page], :per_page => 10)
  end

  def edit_sort_order_warning
  end
  
  def edit_sort_order
    @sort_order = Configuration.find_by_config_key("RollNumberSortOrder")
    render :partial => "select_sort_order"
  end

  def update_sort_order
    if params[:configuration]
      @sort_order = Configuration.find_or_create_by_config_key("RollNumberSortOrder")
      @sort_order.config_value = params[:configuration][:roll_number_order]
      @sort_order.save
    end
    render :update do |page|
      page.reload
    end
  end

  def edit_course_prefix
    @course = Course.find(params[:id])
    @course_prefix = @course.roll_number_prefix
    respond_to do |format|
      format.js { render :action => 'edit_course_prefix' }
    end
  end

  def update_course_prefix
    @course = Course.find(params[:id])
    if params[:course]
      @sort_order = Course.find(params[:id])
      @previous_prefix = @sort_order.roll_number_prefix 
      @sort_order.roll_number_prefix = (params[:course][:roll_number_prefix].empty? ? nil : params[:course][:roll_number_prefix])
      unless @sort_order.save
        @error = true
      end
     
      if @sort_order.save
        batches = @course.batches.find(:all, :conditions => ["roll_number_prefix IS NULL"])
        ActiveRecord::Base.transaction do
          batches.each do |batch|
            if batch.roll_number_generated?
              batch.students.each do |student|
                unless student.roll_number.nil?
                 new_roll_number = student.roll_number
                 new_roll_number = new_roll_number.gsub(@previous_prefix.to_s, @sort_order.roll_number_prefix || "")
                 student.roll_number = new_roll_number
                 student.send :update_without_callbacks
                end
              end
            end
          end
        end
      end
    end
  end
  
  def set_course_prefix
    respond_to do |format|
      format.js { render :action => 'set_course_prefix' }
    end
  end

  def create_course_prefix
    if params[:course]
      @sort_order = Course.find(params[:id])
      @previous_prefix = @sort_order.roll_number_prefix
      @sort_order.roll_number_prefix = (params[:course][:roll_number_prefix].empty? ? nil : params[:course][:roll_number_prefix])
      unless @sort_order.save
        @error = true
      end

      if @sort_order.save
        batches = @sort_order.batches.find(:all, :conditions => ["roll_number_prefix IS NULL"])
        ActiveRecord::Base.transaction do
          batches.each do |batch|
            if batch.roll_number_generated?
              batch.students.each do |student|
                unless student.roll_number.nil?
                 new_roll_number = student.roll_number
                 new_roll_number = new_roll_number.gsub(@previous_prefix.to_s, @sort_order.roll_number_prefix || "")
                 student.roll_number = new_roll_number
                 student.send :update_without_callbacks
                end
              end
            end
          end
        end
      end
    end
  end

  def view_batches
    @course = Course.find(params[:id])
    @batches = @course.batches.active.paginate(:page => params[:page], :per_page => 10)
  end

  def set_roll_numbers
    @batch = Batch.find(params[:id])
    @students = @batch.students.all(:order => Configuration.roll_number_sort_order)
    @roll_number_prefix = @batch.get_roll_number_prefix
    @roll_number_suffix = @batch.get_roll_number_suffix
  end

  def edit_roll_numbers
    @batch = Batch.find(params[:id])
    @students = @batch.students.all(:order => Configuration.roll_number_sort_order)
    @roll_number_prefix = @batch.get_roll_number_prefix
    @roll_number_suffix = @batch.get_roll_number_suffix
  end

  def edit_batch_prefix
    @batch = Batch.find(params[:id])
    @batch_prefix = @batch.get_roll_number_prefix
    respond_to do |format|
      format.js { render :action => 'edit_batch_prefix' }
    end
  end

  def update_batch_prefix
    if params[:id]
      @batch = Batch.find(params[:id])
      @old_prefix = @batch.get_roll_number_prefix
      @batch.roll_number_prefix = (params[:batch][:roll_number_prefix].empty? ? nil : params[:batch][:roll_number_prefix])
    end
    unless @batch.save
      @error = true
    else
      ActiveRecord::Base.transaction do
        @batch.students.each do |s|
          if (s.roll_number.present? and @old_prefix.present?)
            new_roll_number = s.roll_number
            new_roll_number = new_roll_number.gsub(@old_prefix.to_s, @batch.roll_number_prefix.to_s)
            s.roll_number = new_roll_number
            s.send :update_without_callbacks
          end
        end
      end
    end
    @roll_number_prefix = @batch.get_roll_number_prefix
  end

  def reset_batch_to_course_prefix
    @batch = Batch.find(params[:id])
    @old_prefix = @batch.roll_number_prefix
    @batch.roll_number_prefix = nil
    if @batch.save
      @batch.students.each do |s|
        unless s.roll_number.nil?
          new_roll_number = s.roll_number
          new_roll_number = new_roll_number.gsub(@old_prefix.to_s, @batch.course.roll_number_prefix)
          s.roll_number = new_roll_number
          s.send :update_without_callbacks
        end
      end
    end
    render :update do |page|
      page.replace_html "prefix_value",  :text => @batch.course.roll_number_prefix
      page.replace_html "edit_prefix", :partial => "edit_prefix_link"
      page.replace_html "batch_course_text", :text => "#{t('course_prefix_text')}"
    end
  end

  def create_roll_numbers
    @batch = Batch.find(params[:batch_id])
    @students = @batch.students.all(:order => Configuration.roll_number_sort_order)
    @roll_number_prefix = @batch.get_roll_number_prefix || ""
    @roll_number_suffix = @batch.get_roll_number_suffix
    result = StudentRollNumber.save(@roll_number_prefix, params[:batch_id],params[:student] )
    if result.empty?
      redirect_to :action => "view_batches", :id => @batch.course.id
    else
      @errors = result[0]
      @current_values = result[1]
      @err_msg = result[2]
      render "set_roll_numbers"
    end
  end

  def update_roll_numbers
    @batch = Batch.find(params[:batch_id])
    @students = @batch.students.all(:order => Configuration.roll_number_sort_order)
    @roll_number_prefix = @batch.get_roll_number_prefix || ""
    @roll_number_suffix = @batch.get_roll_number_suffix
    result = StudentRollNumber.save(@roll_number_prefix, params[:batch_id],params[:student] )
    result ||= []
    unless result.present?
      redirect_to :action => "view_batches", :id => @batch.course_id
    else
      @errors = result[0]
      @current_values = result[1]
      @err_msg = result[2]
      render "edit_roll_numbers"
    end
  end

  def reset_all_roll_numbers
    @batch = Batch.find(params[:id])
    @batch_strength = @batch.students.count
    @roll_number_prefix = @batch.get_roll_number_prefix
  end

  def regenerate_all_roll_numbers
    @batch = Batch.find(params[:id])
    @batch_strength = @batch.students.count
    @roll_number_prefix = @batch.get_roll_number_prefix
  end

  def update_roll_numbers_to_null
    @batch = Batch.find(params[:id])
    redirect_to :action => "set_roll_numbers", :id => params[:id]
  end

end

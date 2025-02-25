include WeekdayArranger
class ClassroomAllocationsController < ApplicationController
  before_filter :login_required
  after_filter :check_allocation_exist, :only => :delete_allocation
  filter_access_to :all
  before_filter :check_building_defined, :only => [:weekly_allocation,:date_specific_allocation]
  
  def index
    @user = current_user
  end

  def new
    @classroom_allocation = ClassroomAllocation.new
    timetable_entries = TimetableEntry.all.map{|tte| tte.timetable_id }.uniq
    @timetables = Timetable.find(:all, :joins=> :timetable_entries, :select => 'timetables.*', :conditions =>['timetables.id IN (?)', timetable_entries]).uniq
  end

  def view
    timetable_entries = TimetableEntry.all.map{|tte| tte.timetable_id }.uniq
    @timetables = Timetable.find(:all, :joins=> :timetable_entries, :select => 'timetables.*', :conditions =>['timetables.id IN (?)', timetable_entries]).uniq
    @current_timetable=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ?", Time.now.to_date, Time.now.to_date])
    if params[:allocation_type] == "weekly"
      render(:update) do |page|
        page.replace_html "render_partial", :partial => "select_timetable", :locals => {:allocation_type => params[:allocation_type]}
      end
    elsif params[:allocation_type] == "date_specific"
      render(:update) do |page|
        page.replace_html "render_partial", :partial => "select_month_year"
      end
    end
  end

  def weekly_allocation
    unless @building.empty? or @classroom.empty?
      @tte_id = params[:timetable_id]
      @alloc_type = params[:alloc_type]
      if params[:timetable_id].present?
        hsh = make_data_hash
        if hsh["timetable_entries"].empty?
          flash[:notice] = "#{t('no_tte')}"
          render(:update) do|page|
            page.replace_html "flash", :partial => "warning"
          end
          return
        end
        hsh['days'] = weekday_hash
        respond_to do |fmt|
          fmt.json {render :json=> hsh}
        end
      else
        flash[:notice] = "#{t('select_tt')}"
        render(:update) do|page|
          page.replace_html "flash", :partial => "warning"
        end
      end
    else
      flash[:notice] = "#{t('define_building_continue')}"
      render(:update) do|page|
        page.replace_html "flash", :partial => "warning"
      end
    end
  end

  def date_specific_allocation
    unless @building.empty? or @classroom.empty?
      @alloc_type = params[:alloc_type]
      if params[:date].length > 1
        hsh = make_data_hash
        if hsh["timetable_entries"].empty?
          flash[:notice] = "#{t('no_tte')}"
          render(:update) do|page|
            page.replace_html "flash", :partial => "warning"
          end
          return
        end
        hsh['days'] = []
        month = params[:date].split("-")[1]
        year = params[:date].split("-")[0]
        days_of_month = (Date.new(year.to_i,12,31) << (12-month.to_i)).day
        i=1
        while(i<= days_of_month)
          day = Date.parse("#{params[:date]}-#{i}").strftime("%a")
          hsh['days'] << i.to_s + " " + t(day.downcase)
          i+=1
        end
        respond_to do |fmt|
          fmt.json {render :json=> hsh}
        end
      else
        flash[:notice] = "#{t('select_month_year')}"
        render(:update) do|page|
          page.replace_html "flash", :partial => "warning"
        end
      end
    else
      flash[:notice] = "#{t('define_building_continue')}"
      render(:update) do|page|
        page.replace_html "flash", :partial => "warning"
      end
    end
  end

  def render_classrooms
    @buildings =  Building.find(:all, :order => "name")
    @rooms = @buildings.first.classrooms.paginate(:per_page => 21, :page => params[:page])
    render :partial => "classrooms" 
  end

  def display_rooms
    @building = Building.find(params[:building_id])
    @rooms = @building.classrooms.paginate(:per_page => 21, :page => params[:page])
    render :partial => "display_rooms"
  end

  def delete_allocation
    classroom_allocation = ClassroomAllocation.find(:first,:conditions => ["allocation_type = ? and (date = ? or timetable_id = ?)",params[:alloc_type],params[:date],params[:tt_id]])
    AllocatedClassroom.destroy_all("classroom_id = #{params[:room_id]} and subject_id = #{params[:sub_id]} and timetable_entry_id = #{params[:tte_id]} and classroom_allocation_id = #{classroom_allocation.id}")
    respond_to do |fmt|
      fmt.json {render :json=> ""}
    end
  end

  def find_allocations
    allocated_classrooms = AllocatedClassroom.find(:all, :select => "id,classroom_allocation_id,classroom_id,subject_id,timetable_entry_id,date")
    classroom_allocations = ClassroomAllocation.find(:all, :select => "id,allocation_type,timetable_id,date")
    hsh = {:allocations => allocated_classrooms, :classroom_alloc => classroom_allocations}
    respond_to do |fmt|
      fmt.json {render :json => hsh}
    end
  end
  
  def update_allocation_entries
    @flag = true
    timetable_entry = TimetableEntry.find(params[:tte_id]) 
    batch_strength = Batch.find(params[:batch_id]).students.count
    classroom_capacity = Classroom.find(params[:classroom_id]).capacity
    if params[:alloc_type] == "weekly"
      allocation = ClassroomAllocation.find_or_create_by_allocation_type_and_timetable_id(params[:alloc_type],params[:timetable])
    elsif params[:alloc_type] == "date_specific"
      allocation = ClassroomAllocation.find_or_create_by_allocation_type_and_date(params[:alloc_type],params[:date])
    end
    @allocated_warning = []
    validate_allocation(allocation.id,timetable_entry,params[:alloc_type],batch_strength,classroom_capacity) 
    allocation_status = false
    if @allocated_warning.empty? && @flag == true
      if params[:alloc_type] =="weekly"
        create_allocation = AllocatedClassroom.create(:classroom_id => params[:classroom_id], :timetable_entry_id => timetable_entry_id, :classroom_allocation_id => allocation.id, :subject_id => params[:subject_id])
      elsif params[:alloc_type] == "date_specific"
        create_allocation = AllocatedClassroom.create(:classroom_id => params[:classroom_id], :timetable_entry_id => timetable_entry_id, :classroom_allocation_id => allocation.id, :subject_id => params[:subject_id], :date => params[:date])
      end
    end

    if create_allocation.present?
      if create_allocation.save
        allocation_status = true
      end
    end
    respond_to do |fmt|
      fmt.json {render :json=> {:status => allocation_status,:flag => @flag,:msg => @allocated_warning,:classroom => params[:classroom_id], :timetable_entry=> timetable_entry.id, :allocation => allocation.id, :subject => params[:subject_id]}}
    end
  end

  
  def override_allocations
    unless @flag == false
      if params[:alloc_type] == "weekly"
        allocation = AllocatedClassroom.create(:classroom_id => params[:classroom], :timetable_entry_id => params[:timetable_entry], :classroom_allocation_id => params[:allocation], :subject_id => params[:subject])
      elsif params[:alloc_type] == "date_specific"
        allocation = AllocatedClassroom.create(:classroom_id => params[:classroom], :timetable_entry_id => params[:timetable_entry], :classroom_allocation_id => params[:allocation], :subject_id => params[:subject], :date => params[:date])
      end
    end
    
    respond_to do |fmt|
      fmt.json {render :json=> {}}
    end
    
  end

  private

  def check_building_defined
    @building = Building.all
    @classroom = Classroom.all
  end
  
  def check_allocation_exist
    classroom_allocation = ClassroomAllocation.find(:first,:conditions => ["allocation_type = ? and (date = ? or timetable_id = ?)",params[:alloc_type],params[:date],params[:tt_id]])
    allocations = AllocatedClassroom.find(:all,:select => "allocated_classrooms.id", :conditions => {:classroom_allocation_id => "#{classroom_allocation.id}"})
    classroom_allocation.destroy if allocations.empty?
  end
  
  def validate_allocation(alloc_id,timetable_entry,alloc_type,batch_strength,classroom_capacity)
    unless timetable_entry.nil?
      allocation = AllocatedClassroom.find(:all,:select => "allocated_classrooms.id", :conditions => [' timetable_entry_id = ? and subject_id = ? and classroom_allocation_id = ? and classroom_id = ?',timetable_entry.id,params[:subject_id],alloc_id,params[:classroom_id]])
      if allocation.present?
        @flag = false
        @allocated_warning << "#{t('same_room_allocated')}"
        return
      end

      allocation = AllocatedClassroom.find(:all,:select => "allocated_classrooms.id",:joins=> :timetable_entry, :conditions =>"timetable_entries.weekday_id= #{timetable_entry.weekday_id} and timetable_entries.class_timing_id = #{timetable_entry.class_timing_id} and timetable_entries.id != #{timetable_entry.id} and allocated_classrooms.classroom_allocation_id = #{alloc_id} and allocated_classrooms.classroom_id= #{params[:classroom_id]}")
      if allocation.present?
        @allocated_warning << "#{t('same_class_timing_allocation')}"
      end

      allocation = AllocatedClassroom.find(:all,:select => "allocated_classrooms.id",:conditions => ['timetable_entry_id = ? and subject_id = ? and classroom_allocation_id = ?',timetable_entry.id,params[:subject_id],alloc_id])
      if allocation.present?
        @allocated_warning << "#{t('multiple_room_allocation')} "
      end

      allocation = AllocatedClassroom.find(:all,:select => "allocated_classrooms.id", :joins => :classroom_allocation, :conditions => ["allocated_classrooms.timetable_entry_id = ? and allocated_classrooms.subject_id = ? and classroom_allocations.allocation_type = ?",timetable_entry.id,params[:subject_id],'weekly'])
      if allocation.present?
        @allocated_warning << "#{t('allocated_weekly')} "
      end

      @allocated_warning << "#{t('capacity_less')}" if batch_strength > classroom_capacity
      @allocated_warning << "#{t('override')}"
    end
  end

  def make_data_hash
    if @alloc_type == "date_specific"
      last_day = Date.parse(params[:date] + "-01").end_of_month.day
      timetable_entries = TimetableEntry.find(:all,:include =>:subject, :joins => :timetable,:select => "timetable_entries.*",:conditions => ['timetables.start_date between ? and ? or timetables.end_date between ? and ? ', "#{params[:date]}-01","#{params[:date]}" + "-#{last_day}","#{params[:date]}-01", "#{params[:date]}" + "-#{last_day}"],:order => "timetable_entries.batch_id,timetable_entries.class_timing_id").uniq
    elsif @alloc_type == "weekly"
      timetable_entries = TimetableEntry.find(:all,:include =>:subject, :joins => :timetable, :select => "timetable_entries.*", :conditions => ['timetable_entries.timetable_id=?', @tte_id],:order => "timetable_entries.batch_id,timetable_entries.class_timing_id")
    end
  
    subjects = Subject.active.all(:conditions => ["id in (?)",timetable_entries.collect{|x| x.subject_id }])
    tt = Timetable.find(:all, :conditions => ["id in (?)",timetable_entries.collect{|x| x.timetable_id}])
    extra_subjects = []
    subjects.each do |sub|
      if sub.elective_group_id.present?
        extra_subjects << Subject.active.find(:all,:conditions=> "elective_group_id = #{sub.elective_group_id} AND id != #{sub.id}")
      end
    end
    elective_employees = EmployeesSubject.find(:all , :conditions => ["subject_id IN (?)",extra_subjects.flatten.collect(&:id)])
    employee_ids = timetable_entries.map{|tte| tte.employee_id }.uniq + elective_employees.collect(&:employee_id).uniq
    employees = Employee.find(:all, :joins=> :employees_subjects, :select => 'employees.id,employees.first_name,employees.last_name,employees.middle_name')

    class_timing_ids = timetable_entries.map{|tte| tte.class_timing_id}.uniq
    class_timings = ClassTiming.find(:all, :conditions => ["id IN (?)", class_timing_ids ] )

    batches = Batch.find(:all, :conditions =>["id IN (?) and is_active = ?",timetable_entries.map {|tte| tte.batch_id}.uniq,true])
   
    allocated_classrooms = AllocatedClassroom.find(:all,:select => "id,classroom_allocation_id,classroom_id,subject_id,timetable_entry_id,date", :conditions => ["timetable_entry_id IN (?)",timetable_entries.map{|tte| tte.id }.uniq ])
    classrooms = Classroom.find(:all, :select => "id,name")
    classroom_allocations = ClassroomAllocation.find(:all,:select => "id,allocation_type,timetable_id,date", :conditions => ["id IN (?)", allocated_classrooms.map { |ac| ac.classroom_allocation_id  }])

    hash = {'batches'=> {}, 'timetable_entries' => {}, 'subjects' => {}, 'classtimings' => {}, 'classrooms' => {}}

    batches.each do |b|
      hash['batches'][b.id] = b.full_name
      hash['timetable_entries'][b.id] = timetable_entries.select{|tte| tte.batch_id == b.id}
      hash['subjects'][b.id] = b.subjects
    end
    hash['classtimings'] = class_timings
    hash['employees'] = employees
    hash['allocated_classrooms']= allocated_classrooms
    hash['classrooms'] = classrooms
    hash['classroom_allocations'] = classroom_allocations
    hash['elective_subjects'] = extra_subjects
    emp_hsh = {}
    emp_sub = EmployeesSubject.find(:all,:include => [:employee,:subject],:conditions => ["employees_subjects.employee_id IN (?)", employee_ids],:select => "employee_id,subject_id")
    emp_sub.each do |x|
      emp_hsh[x.subject.id] = [] if emp_hsh[x.subject.id].nil?
      emp_hsh[x.subject.id] << x.employee.full_name
    end
    hash['emp_subjects'] = emp_hsh
    hash['tt'] = tt
    return hash
  end

end

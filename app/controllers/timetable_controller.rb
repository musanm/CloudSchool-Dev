#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
include WeekdayArranger
class TimetableController < ApplicationController
  before_filter :login_required
  before_filter :protect_other_student_data
  before_filter :default_time_zone_present_time
  filter_access_to :all
  before_filter :check_status

  def index
    @user = current_user
  end
  def new_timetable
    @timetable=Timetable.new
    if request.post?
      @timetable=Timetable.new(params[:timetable])
      if @timetable.end_date < @timetable.start_date
        @error=true
        @timetable.errors.add_to_base("#{t('start_date_is_lower_than_end_date')}")
      end
      @conflicts=Timetable.find(:all, :conditions => ["(end_date BETWEEN ? AND ? ) OR (start_date BETWEEN ? AND ? ) OR (start_date <= ? AND end_date >= ?)", @timetable.start_date, @timetable.end_date, @timetable.start_date, @timetable.end_date,@timetable.start_date,@timetable.end_date])
      if @conflicts.present?
        @error=true
        @timetable.errors.add_to_base("#{t('timetable_in_between_given_dates')}")
      end
      class_timing_sets=ClassTimingSet.all(:select=>"distinct class_timing_sets.*",:joins=>"INNER JOIN `batch_class_timing_sets` ON batch_class_timing_sets.class_timing_set_id = class_timing_sets.id LEFT OUTER JOIN `class_timings` ON class_timings.class_timing_set_id = class_timing_sets.id",:conditions=>["class_timings.id IS NULL"])
      if class_timing_sets.present?
        @error=true
        @timetable.errors.add_to_base("#{t('assign_class_timings')} #{class_timing_sets.collect(&:name).join(",")}")
      end
      unless @error
        #        @timetable.save_timetable_weekdays
        @timetable.save_timetable_class_timings
        if @timetable.save
          flash[:notice]="#{t('timetable_created_from')} #{format_date(@timetable.start_date,:format=>:long)} - #{format_date(@timetable.end_date,:format=>:long)}"
          redirect_to :controller => :timetable_entries, :action => "new", :timetable_id => @timetable.id
        else
          
          flash[:notice]='error_occured'
          render :action => 'new_timetable'
        end
      else
        render :action => 'new_timetable'
      end
    end
  end

  def update_timetable
    @timetable=Timetable.find(params[:id])
    if request.post?
      @error=false
      new_start_date=params[:start_date].to_date
      new_end_date=params[:end_date].to_date
      if new_end_date < new_start_date
        @error=true
        @timetable.errors.add_to_base("#{t('start_date_is_lower_than_end_date')}")
      end
      @conflicts=Timetable.find(:all, :conditions => ["((end_date BETWEEN ? AND ? ) AND id != ? ) OR ((start_date BETWEEN ? AND ? ) AND id != ? ) OR ((start_date <= ? AND end_date >= ?) AND id !=?)", new_start_date, new_end_date, @timetable.id, new_start_date, new_end_date, @timetable.id,new_start_date, new_end_date, @timetable.id])
      if @conflicts.present?
        @error=true
        @timetable.errors.add_to_base("#{t('timetable_in_between_given_dates')}")
      end
      unless @error
        unless (@timetable.start_date == new_start_date and @timetable.end_date == new_end_date)
          old_end_date=@timetable.end_date
          old_start_date=@timetable.start_date
          ActiveRecord::Base.transaction do
            if (new_start_date < old_end_date and new_end_date > old_end_date)
              if @timetable.update_attributes(:start_date=>new_start_date,:end_date=>old_end_date)
                @new_timetable=Timetable.new(:start_date=>old_end_date+1,:end_date=>new_end_date)
                @new_timetable.save_timetable_classtimings_on_split(@timetable)
                #                @new_timetable.save_timetable_weekdays_on_split(@timetable)
                @new_timetable.save!
                @new_timetable.copy_timetable_entries(@timetable)
                flash[:notice]=t('timetable_updated')
              else
                @save_error=true
              end
            else
              if @timetable.update_attributes(:start_date=>new_start_date,:end_date=>new_end_date)
                flash[:notice]=t('timetable_updated')
              else
                @save_error=true
              end
            end
            @timetable.dependency_delete(old_start_date, new_start_date-1,@timetable.id) if new_start_date.to_date > old_start_date.to_date
            @timetable.dependency_delete(new_end_date+1, old_end_date,@timetable.id) if new_end_date.to_date < old_end_date.to_date
            if @save_error
              raise ActiveRecord::Rollback
              flash[:warn_notice]=t("timetable_update_failure")
            end
          end
          redirect_to :controller => :timetable, :action => :edit_master
        else
          redirect_to :controller => :timetable, :action => :edit_master
        end
      else
        flash[:warn_notice]=@timetable.errors.full_messages unless @timetable.errors.empty?
        render :action => "update_timetable" ,:id=>@timetable.id
      end
    end
  end

  def manage_timetable
    @timetable=Timetable.find params[:id]
    @assigned_batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:time_table_class_timings],:conditions=>["time_table_class_timings.timetable_id=?  AND batches.start_date <= ? AND batches.end_date >= ?",@timetable.id,@timetable.end_date,@timetable.start_date])
    assigned_batch_ids=@assigned_batches.present? ? @assigned_batches.collect(&:id) : [0]
    @available_batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:batch_class_timing_sets=>[:class_timing_set=>:class_timings]],:conditions=>["batches.id NOT IN (?) AND batches.start_date <= ? AND batches.end_date >=?",assigned_batch_ids,@timetable.end_date,@timetable.start_date])
  end

  def add_batch_timetable
    @timetable=Timetable.find params[:id]
    batches=Batch.find_all_by_id(params[:batch_id])
    batches.each do |batch|
      if @timetable.time_table_class_timings.find_all_by_batch_id(batch.id).blank?
        ttct=@timetable.time_table_class_timings.build(:batch_id => batch.id)
        batch.batch_class_timing_sets.each do |cts|
          ttct.time_table_class_timing_sets.build(:batch_id=>batch.id,:class_timing_set_id=>cts.class_timing_set_id,:weekday_id=>cts.weekday_id)
        end
      end
    end
    if @timetable.save
      @assigned_batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:time_table_class_timings],:conditions=>["time_table_class_timings.timetable_id=?  AND batches.start_date <= ? AND batches.end_date >= ?",@timetable.id,@timetable.end_date,@timetable.start_date])
      assigned_batch_ids=@assigned_batches.present? ? @assigned_batches.collect(&:id) : [0]
      @available_batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:batch_class_timing_sets=>[:class_timing_set=>:class_timings]],:conditions=>["batches.id NOT IN (?) AND batches.start_date <= ? AND batches.end_date >=?",assigned_batch_ids,@timetable.end_date,@timetable.start_date])
      render :update do |page|
        page.replace_html 'flash-box',:text=>"<p class='flash-msg'> #{t('batch_timetable_assigned')}</p>"
        page.replace_html 'batch-list',:partial=>'assign_timetable_form'
      end
    else
      render :update do |page|
        page.replace_html 'flash-box',:text=>"<div id='error-box'><ul> <li>#{t('batch_assigned_with_error')}</li></ul></div>"
      end
    end
  end

  def remove_batch_timetable
    @timetable=Timetable.find params[:id]
    timetable_week_days=@timetable.time_table_weekdays.all(:conditions=>{:batch_id=>params[:batch_id]})
    timetable_class_timings=@timetable.time_table_class_timings.all(:conditions=>{:batch_id=>params[:batch_id]})
    ActiveRecord::Base.transaction do
      TimeTableClassTiming.destroy(timetable_class_timings.collect(&:id)) ? error=false : error=true
      #      TimeTableWeekday.destroy(timetable_week_days.collect(&:id)) ? error=false : error=true
      @assigned_batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:time_table_class_timings],:conditions=>["time_table_class_timings.timetable_id=?  AND batches.start_date <= ? AND batches.end_date >= ?",@timetable.id,@timetable.end_date,@timetable.start_date])
      assigned_batch_ids=@assigned_batches.present? ? @assigned_batches.collect(&:id) : [0]
      @available_batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:batch_class_timing_sets=>[:class_timing_set=>:class_timings]],:conditions=>["batches.id NOT IN (?) AND batches.start_date <= ? AND batches.end_date >=?",assigned_batch_ids,@timetable.end_date,@timetable.start_date])
      if error
        raise ActiveRecord::Rollback
        render :update do |page|
          page.replace_html 'flash-box',:text=>"<div id='error-box'><ul> <li>#{t('batch_removed_with_error')}</li></ul></div>"
          page.replace_html 'batch-list',:partial=>'assign_timetable_form'
        end
      else
        render :update do |page|
          page.replace_html 'flash-box',:text=>"<p class='flash-msg'> #{t('batch_timetable_removed')}</p>"
          page.replace_html 'batch-list',:partial=>'assign_timetable_form'
        end
      end
    end
  end

  def view
    @timetables=Timetable.all(:order => "start_date DESC")
    if @timetables.present?
      current_timetable=@timetables.select{|timetable| timetable.start_date <= @local_tzone_time.to_date && timetable.end_date >= @local_tzone_time.to_date}.first
      @current_timetable=current_timetable.present?? current_timetable : @timetables.first
      @batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:time_table_class_timings],:conditions=>["time_table_class_timings.timetable_id=?  AND batches.start_date <= ? AND batches.end_date >=?",@current_timetable.id,@current_timetable.end_date,@current_timetable.start_date])
    end
  end

  def edit_master
    @courses = Batch.active
    @timetables=Timetable.paginate(:order => "end_date DESC", :per_page => 20, :page => params[:page])
  end

  def teachers_timetable
    @timetables=Timetable.all
    ## Prints out timetable of all teachers
    @current=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ?", @local_tzone_time.to_date, @local_tzone_time.to_date])
    if @current
      @timetable_entries = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }
      @all_timetable_entries = @current.timetable_entries.select { |t| t.batch.is_active }.select { |s| s.class_timing.is_deleted==false }
      @all_batches = @all_timetable_entries.collect(&:batch).uniq #.sort!{|a,b| a.class_timing <=> b.class_timing}
      @all_weekdays = @all_timetable_entries.collect(&:weekday_id).uniq.sort
      @all_classtimings = @all_timetable_entries.collect(&:class_timing).uniq.sort! { |a, b| a.start_time <=> b.start_time }
      @all_subjects = @all_timetable_entries.collect(&:subject).uniq
      @all_teachers = @all_timetable_entries.collect(&:employee).uniq
      @all_timetable_entries.each_with_index do |tt, i|
        @timetable_entries[tt.employee_id][tt.weekday_id][tt.class_timing_id][i] = tt
      end
      @all_subjects.each do |sub|
        unless sub.elective_group.nil?
          @all_teachers+=sub.elective_group.subjects.collect(&:employees).flatten
          @elective_teachers=sub.elective_group.subjects.collect(&:employees).flatten
          @current.timetable_entries.find_all_by_subject_id(sub.id).each_with_index do |tt, i|
            @elective_teachers.each do |e|
              unless sub.elective_group.subjects.first == sub && sub.employees.first == e
                @timetable_entries[e.id][tt.weekday_id][tt.class_timing_id][i] = tt
              end
            end
          end
        end
      end
      @all_teachers=@all_teachers.uniq
    else
      @all_timetable_entries=[]
    end
  end

  #    if request.xhr?
  def update_teacher_tt
    if params[:timetable_id].nil?
      @current=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ?", @local_tzone_time.to_date, @local_tzone_time.to_date])
    else
      if params[:timetable_id]==""
        render :update do |page|
          page.replace_html "timetable_view", :text => ""
        end
        return
      else
        @current=Timetable.find(params[:timetable_id])
      end
    end
    @timetable_entries = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }
    @all_timetable_entries = @current.timetable_entries.all(:include=>[:batch,{:subject=>{:elective_group=>{:subjects=>:employees}}},:class_timing,:employee]).select { |t| t.batch.is_active }.select { |s| s.class_timing.is_deleted==false }
    @all_batches = @all_timetable_entries.collect(&:batch).uniq
    @all_weekdays = @all_timetable_entries.collect(&:weekday_id).uniq.sort
    @all_classtimings = @all_timetable_entries.collect(&:class_timing).uniq.sort! { |a, b| a.start_time <=> b.start_time }
    @all_subjects = @all_timetable_entries.collect(&:subject).uniq
    @all_teachers = @all_timetable_entries.collect(&:employee).uniq
    @all_timetable_entries.each_with_index do |tt, i|
      @timetable_entries[tt.employee_id][tt.weekday_id][tt.class_timing_id][i] = tt
    end
    @all_subjects.each do |sub|
      unless sub.elective_group.nil?
        @all_teachers+=sub.elective_group.subjects.collect(&:employees).flatten
        @elective_teachers=sub.elective_group.subjects.collect(&:employees).flatten
        @current.timetable_entries.find_all_by_subject_id(sub.id).each_with_index do |tt, i|
          @elective_teachers.each do |e|
            unless sub.elective_group.subjects.first == sub && sub.employees.first == e
              @timetable_entries[e.id][tt.weekday_id][tt.class_timing_id][i] = tt
            end
          end
        end
      end
    end
    @all_teachers=@all_teachers.uniq
    render :update do |page|
      page.replace_html "timetable_view", :partial => "teacher_timetable"
    end
  end

  def timetable_view_batches
    @timetable=Timetable.find params[:timetable_id]
    @batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:time_table_class_timings],:conditions=>["time_table_class_timings.timetable_id=?  AND batches.start_date <= ? AND batches.end_date >= ?",@timetable.id,@timetable.end_date,@timetable.start_date])
    render :update do |page|
      page.replace_html "timetable_view", :text => ""
      page.replace_html "batches", :partial => "timetable_batches"
    end
  end

  def update_timetable_view
    if params[:batch_id].present?
      @timetable=Timetable.find(params[:timetable_id])
      @batch = Batch.find(params[:batch_id])
      tte_from_batch_and_tt(@timetable.id)
      render :update do |page|
        page.replace_html "timetable_view", :partial => "view_timetable"
      end
    else
      render :update do |page|
        page.replace_html "timetable_view", :text => "<p class='flash-msg'> #{t('select_one_batch')}</p>"
      end
    end
  end

  def destroy
    @timetable=Timetable.find(params[:id])
    ActiveRecord::Base.transaction do
      @timetable.dependency_delete(@timetable.start_date, @timetable.end_date,@timetable.id)
      if @timetable.destroy
        flash[:notice]=t('timetable_deleted')
        redirect_to :action=>"edit_master"
      else
        raise ActiveRecord::Rollback
      end
    end
  end

  def employee_timetable
    @employee=Employee.find(params[:id])
    @blocked=true
    if permitted_to? :employee_timetable, :timetable
      @blocked=false
    elsif @current_user.employee_record==@employee
      @blocked=false
    elsif @current_user.admin?
      @blocked=false
    end
    unless @blocked

      @timetables=Timetable.all
      ## Prints out timetable of all teachers
      @current=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ?", @local_tzone_time.to_date, @local_tzone_time.to_date])
      unless @current.nil?
        @electives=@employee.subjects.group_by(&:elective_group_id)
        @timetable_entries = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }
        @employee_subjects = @employee.subjects
        subjects = @employee_subjects.select { |sub| sub.elective_group_id.nil? }
        electives = @employee_subjects.select { |sub| sub.elective_group_id.present? }
        elective_subjects=electives.map { |x| x.elective_group.subjects.first }
        @employee_timetable_subjects = @employee_subjects.map { |sub| sub.elective_group_id.nil? ? sub : sub.elective_group.subjects.first }
        @entries=[]
        @entries += @current.timetable_entries.find(:all, :conditions => {:subject_id => subjects, :employee_id => @employee.id})
        @entries += @current.timetable_entries.find(:all, :conditions => {:subject_id => elective_subjects})
        @all_timetable_entries = @entries.select { |t| t.batch.is_active }.select { |s| s.class_timing.is_deleted==false }
        @all_batches = @all_timetable_entries.collect(&:batch).uniq
        @all_weekdays = @all_timetable_entries.collect(&:weekday_id).uniq.sort
        @all_classtimings = @all_timetable_entries.collect(&:class_timing).uniq.sort! { |a, b| a.start_time <=> b.start_time }
        @all_teachers = @all_timetable_entries.collect(&:employee).uniq
        @all_timetable_entries.each_with_index do |tt, i|
          @timetable_entries[tt.weekday_id][tt.class_timing_id][i] = tt
        end
      else
        flash[:notice]=t('no_entries_found')
      end
    else
      flash[:notice]=t('flash_msg6')
      redirect_to :controller => :user, :action => :dashboard
    end
  end

  #    if request.xhr?
  def update_employee_tt
    @employee=Employee.find(params[:employee_id])
    if params[:timetable_id].nil?
      @current=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ?", @local_tzone_time.to_date, @local_tzone_time.to_date])
    else
      if params[:timetable_id]==""
        render :update do |page|
          page.replace_html "timetable_view", :text => ""
        end
        return
      else
        @current=Timetable.find(params[:timetable_id])
      end
    end
    @electives=@employee.subjects.group_by(&:elective_group_id)
    @timetable_entries = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }
    @employee_subjects = @employee.subjects
    subjects = @employee_subjects.select { |sub| sub.elective_group_id.nil? }
    electives = @employee_subjects.select { |sub| sub.elective_group_id.present? }
    elective_subjects=electives.map { |x| x.elective_group.subjects.first }
    @employee_timetable_subjects = @employee_subjects.map { |sub| sub.elective_group_id.nil? ? sub : sub.elective_group.subjects.first }
    @entries=[]
    @entries += @current.timetable_entries.find(:all, :conditions => {:subject_id => subjects, :employee_id => @employee.id})
    @entries += @current.timetable_entries.find(:all, :conditions => {:subject_id => elective_subjects})
    @all_timetable_entries = @entries.select { |t| t.batch.is_active }.select { |s| s.class_timing.is_deleted==false }
    @all_batches = @all_timetable_entries.collect(&:batch).uniq
    @all_weekdays = weekday_arrangers(@all_timetable_entries.collect(&:weekday_id).uniq.sort)
    @all_classtimings = @all_timetable_entries.collect(&:class_timing).uniq.sort! { |a, b| a.start_time <=> b.start_time }
    @all_teachers = @all_timetable_entries.collect(&:employee).uniq
    @all_timetable_entries.each_with_index do |tt, i|
      @timetable_entries[tt.weekday_id][tt.class_timing_id][i] = tt
    end
    render :update do |page|
      page.replace_html "timetable_view", :partial => "employee_timetable"
    end
  end

  def student_view
    @student = Student.find(params[:id])
    @batch=@student.batch
    if @batch.weekday_set_id.present?
      timetable_ids=@batch.timetable_entries.collect(&:timetable_id).uniq
      @timetables=Timetable.find timetable_ids
      @current=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ? and id IN (?)", @local_tzone_time.to_date, @local_tzone_time.to_date, timetable_ids])
      @timetable_entries = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }
      unless @current.nil?
        @class_timing_sets=TimeTableClassTiming.find_by_batch_id_and_timetable_id(@batch.try(:id), @current.try(:id)).time_table_class_timing_sets(:joins=>{:class_timing_set=>:class_timings})
        #        @entries=@current.timetable_entries.find(:all, :conditions => {:batch_id => @batch.id, :class_timing_id => @class_timings})
        @entries=TimetableEntry.find(:all,:conditions=>{:batch_id=>@batch.id,:timetable_id=>@current.id},:include=>[{:subject=>:subject_leaves},:employee,:timetable_swaps])
        @all_timetable_entries = @entries.select { |s| s.class_timing.is_deleted==false }
        @all_weekdays = @all_timetable_entries.collect(&:weekday_id).uniq.sort
        #        @all_classtimings = @all_timetable_entries.collect(&:class_timing).uniq.sort! { |a, b| a.start_time <=> b.start_time }
        @all_teachers = @all_timetable_entries.collect(&:employee).uniq
        @all_timetable_entries.each do |tt|
          @timetable_entries[tt.weekday_id][tt.class_timing_id] = tt
        end
      end
    else
      flash[:notice] = t('timetable_not_set')
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def update_student_tt
    @student = Student.find(params[:id])
    @batch=@student.batch
    @all_timetable_entries = Array.new
    if params[:timetable_id].nil?
      @current=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ?", @local_tzone_time.to_date, @local_tzone_time.to_date])
    else
      if params[:timetable_id]==""
        render :update do |page|
          page.replace_html "box", :text => ""
        end
        return
      else
        @current=Timetable.find(params[:timetable_id])
      end
    end
    @timetable_entries = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }
    unless @current.nil?
      ttct = TimeTableClassTiming.find_by_batch_id_and_timetable_id(@batch.try(:id), @current.try(:id))
      if ttct.present?
        @class_timing_sets=TimeTableClassTiming.find_by_batch_id_and_timetable_id(@batch.try(:id), @current.try(:id)).time_table_class_timing_sets(:joins=>{:class_timing_set=>:class_timings})
        #        @entries=@current.timetable_entries.find(:all, :conditions => {:batch_id => @batch.id, :class_timing_id => @class_timings})
        @entries=TimetableEntry.find(:all,:conditions=>{:batch_id=>@batch.id,:timetable_id=>@current.id},:include=>[{:subject=>:subject_leaves},:employee,:timetable_swaps])
        @all_timetable_entries = @entries.select { |s| s.class_timing.is_deleted==false }
        @all_weekdays = weekday_arrangers(@all_timetable_entries.collect(&:weekday_id).uniq.sort)
        #        @all_classtimings = @all_timetable_entries.collect(&:class_timing).uniq.sort! { |a, b| a.start_time <=> b.start_time }
        @all_teachers = @all_timetable_entries.collect(&:employee).uniq
        @all_timetable_entries.each do |tt|
          @timetable_entries[tt.weekday_id][tt.class_timing_id] = tt
        end
      end
    end

    render :update do |page|
      page.replace_html "time_table", :partial => "student_timetable"
    end
  end

  def weekdays
    @batches = Batch.active
  end

  def timetable_pdf
    @tt=Timetable.find(params[:timetable_id])
    @batch = Batch.find(params[:batch_id])
    tte_from_batch_and_tt(@tt.id)
    render :pdf => 'timetable_pdf', :orientation => 'Landscape',:zoom=>1,:margin =>{:top=>5,:bottom=>0,:left=>5,:right=>5},:header => {:html => { :content=> ''}},
      :footer => {:html => { :template=> 'layouts/pdf_footer.html'}}
  end

  def work_allotment
    @employees = Employee.all(:include => [:employee_grade, :employees_subjects, :user])
    @employees.reject! { |e| (e.user.nil? or e.user.admin?) }
    @emp_subs = []
    @employees.map { |employee| (employee[:total_time] = ((employee.max_hours_week).to_i)) }
    if request.post?
      if params[:employee_subjects].present?
        params[:employee_subjects].delete_blank
        success, @error_obj = EmployeesSubject.allot_work(params[:employee_subjects])
        if success
          flash[:notice] = t('work_allotment_success')
        else
          flash[:notice] = t('updated_with_errors')
        end
      else
        flash[:notice] = t('updated_with_errors')
      end
    end
    @batches = Batch.active.scoped :include => [{:subjects => :employees}, :course]
    @subjects = @batches.collect(&:subjects).flatten
  end

  def timetable
    @config = Configuration.available_modules
    @batches = Batch.active.all(:include=>[{:weekday_set=>:weekday_sets_weekdays},{:timetable_entries=>[:timetable,:class_timing,{:subject=>:elective_group},:employee]}])
    @week_day_set_ids=WeekdaySet.common.weekday_ids
    unless params[:next].nil?
      @today = params[:next].to_date
      render (:update) do |page|
        page.replace_html "timetable", :partial => 'table'
      end
    else
      @today = @local_tzone_time.to_date
    end
  end

  private

  def tte_from_batch_and_tt(tt)
    @tt=Timetable.find(tt)
    time_table_class_timings = TimeTableClassTiming.find_by_timetable_id_and_batch_id(@tt.id,@batch.id)
    @class_timing_sets = time_table_class_timings.nil? ? @batch.batch_class_timing_sets(:joins=>{:class_timing_set=>:class_timing}) : time_table_class_timings.time_table_class_timing_sets(:joins=>{:class_timing_set=>:class_timings})
    if @tt.duration >= 7
      @weekday = weekday_arrangers(time_table_class_timings.time_table_class_timing_sets.collect(&:weekday_id))
    else
      weekdays=[]
      (@tt.start_date..@tt.end_date).each {|day| weekdays << day.wday if time_table_class_timings.time_table_class_timing_sets.collect(&:weekday_id).include?(day.wday)}
      @weekday = weekday_arrangers(weekdays)
    end
    timetable_entries=TimetableEntry.find(:all,:conditions=>{:batch_id=>@batch.id,:timetable_id=>@tt.id},:include=>[{:subject=>:subject_leaves},:employee,:timetable_swaps])
    @timetable= Hash.new { |h, k| h[k] = Hash.new(&h.default_proc)}
    timetable_entries.each do |tte|
      @timetable[tte.weekday_id][tte.class_timing_id]=tte
    end
    @subjects = Subject.find_all_by_batch_id(@batch.id, :conditions=>["elective_group_id IS NULL AND is_deleted = false"])
    @ele_subjects = Subject.find_all_by_batch_id(@batch.id, :conditions=>["elective_group_id IS NOT NULL AND is_deleted = false"], :group => "elective_group_id")
  end
end
class Hash
  def delete_blank
    delete_if { |k, v| v.empty? or v.instance_of?(Hash) && v.delete_blank.empty? }
  end
end
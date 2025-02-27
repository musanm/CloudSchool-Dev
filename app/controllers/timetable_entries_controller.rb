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
class TimetableEntriesController < ApplicationController
  before_filter :login_required
  before_filter :default_time_zone_present_time
  filter_access_to :all
  before_filter :check_valid_timetable, :only => [:new,:select_batch,:new_entry,:update_multiple_timetable_entries2,:tt_entry_update2]
  before_filter :check_status

  def new
    @timetable=Timetable.find(params[:timetable_id])
    @batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:time_table_class_timings],:conditions=>["time_table_class_timings.timetable_id=?  AND batches.start_date <= ? AND batches.end_date >= ?",@timetable.id,@timetable.end_date,@timetable.start_date])
    if params[:timetable_type].present? and params[:timetable_type]=="past"
      @timetable.dependency_delete(@timetable.start_date,@timetable.end_date,params[:timetable_type],@timetable.id)
      classroom_alloc_ids = ClassroomAllocation.find(:all, :conditions => {:allocation_type => "weekly"}).collect{|ca| ca.id}
      tte_ids = @timetable.timetable_entries.collect{|tte| tte.id}
      AllocatedClassroom.delete_all(["date IS NULL and classroom_allocation_id IN (?) and timetable_entry_id IN (?)",classroom_alloc_ids,tte_ids])
    end
    
  end

  def select_batch
    @timetable=Timetable.find(params[:timetable_id])
    @batches = Batch.active.reject{|b| b.end_date < @timetable.try(:start_date)}
    if request.post?
      unless params[:timetable_entry][:batch_id].empty?

      else
        flash[:notice]="#{t('select_a_batch_to_continue')}"
        redirect_to :action => "select_batch"
      end
    end
  end

  def new_entry
    @timetable=Timetable.find(params[:timetable_id])
    if params[:batch_id] == ""
      render :update do |page|
        page.replace_html "render_area", :text => ""
      end
      return
    end
    @batch = Batch.find(params[:batch_id])
    tte_from_batch_and_tt(@timetable.id)

    render :update do |page|
      page.replace_html "render_area", :partial => "new_entry"
    end
  end

  def update_employees
    #    @weekday = ["#{t('sun')}", "#{t('mon')}", "#{t('tue')}", "#{t('wed')}", "#{t('thu')}", "#{t('fri')}", "#{t('sat')}"]
    if params[:subject_id] == ""
      render :text => ""
      return
    end
    ele_gp_id=Subject.find_all_by_id(params[:subject_id]).collect(&:elective_group_id).compact
    if ele_gp_id.empty?
      @employees_subject = EmployeesSubject.find_all_by_subject_id(params[:subject_id])
    else
      @employees_subject = EmployeesSubject.find_all_by_subject_id(Subject.find_all_by_elective_group_id(ele_gp_id).collect(&:id))
    end
    render :partial=>"employee_list"
  end

  def delete_employee2
    @errors = {"messages" => []}
    tte=TimetableEntry.find(params[:id])
    batch=tte.batch_id
    #    @timetable = TimetableEntry.find_all_by_batch_id(tte.batch_id)
    @batch=Batch.find batch
    @timetable=Timetable.find(tte.timetable_id)
    unless  tte.destroy
      flash[:warn_notice]=tte.errors.full_messages.first
    end
    tte_from_batch_and_tt(@timetable.id)
    render :update do |page|
      page.replace 'tt_over',:partial=>'new_entry', :batch_id=>batch
    end
  end

  #  for script

  def update_multiple_timetable_entries2
    @timetable=Timetable.find(params[:timetable_id])
    employees_subject = EmployeesSubject.find_all_by_id(params[:emp_sub_id].split(',').sort).first
    sub_ids=params[:emp_sub_id].split(",")
    emp_ids=EmployeesSubject.find_all_by_id(sub_ids).collect(&:employee_id)
    tte_ids = params[:tte_ids].split(",").each {|x| x}
    @batch = employees_subject.subject.batch
    timetable_class_timings=[]
    TimeTableClassTiming.find_by_batch_id_and_timetable_id(@batch.id,@timetable.id).time_table_class_timing_sets.each do |ttcts|
      timetable_class_timings += ttcts.class_timing_set.class_timings.timetable_timings.map(&:id)
    end
    timetable_class_timings.uniq!
    subject = employees_subject.subject
    employee = employees_subject.employee
    emp_s=employee.subjects.collect(&:elective_group_id).compact
    @validation_problems = {}
    tte_ids.each do |tte_id|
      co_ordinate=tte_id.split("_")
      weekday=co_ordinate[0].to_i
      class_timing=co_ordinate[1].to_i
      overlap= TimetableEntry.find(:all,:conditions=>{:employee_id=>emp_ids,:timetable_id=>@timetable.id,:class_timing_id=>class_timing,:weekday_id=>weekday},:joins=>"INNER JOIN subjects ON timetable_entries.subject_id = subjects.id INNER JOIN batches ON subjects.batch_id = batches.id AND batches.is_active = 1 AND batches.is_deleted = 0")
      unless overlap.empty?
        tte = TimetableEntry.find_by_weekday_id_and_class_timing_id_and_batch_id_and_timetable_id(weekday,class_timing,@batch.id,@timetable.id)
        errors = { "info" => {"sub_id" => employees_subject.subject_id, "emp_id"=> overlap[0].employee_id,"tte_id" => tte_id},
          "messages" => [] }
        @overlap = overlap
        overlap.each do |overlap|
          errors["messages"] << "#{t('class_overlap')} #{overlap.batch.full_name} #{t('for_text')} #{overlap.subject.name}"
        end
      else
        tte = TimetableEntry.find_by_weekday_id_and_class_timing_id_and_batch_id_and_timetable_id(weekday,class_timing,@batch.id,@timetable.id)
        errors = { "info" => {"sub_id" => employees_subject.subject_id, "emp_id"=> employees_subject.employee_id,"tte_id" => tte_id},
          "messages" => [] }
      end
      if errors.empty?
        unless emp_s.empty?
          emp_subs=Subject.find_all_by_elective_group_id(emp_s).collect(&:id)
          overlap_elective=TimetableEntry.find(:all,:conditions=>{:subject_id=>emp_subs,:timetable_id=>@timetable.id,:class_timing_id=>class_timing,:weekday_id=>weekday},:joins=>"INNER JOIN subjects ON timetable_entries.subject_id = subjects.id INNER JOIN batches ON subjects.batch_id = batches.id AND batches.is_active = 1 AND batches.is_deleted = 0")
          unless overlap_elective.empty?
            overlap_elective.each do |overlap|
              errors["messages"] << "#{t('class_overlap')} #{overlap.batch.full_name}  #{t('for_text')} #{overlap.subject.name}"
            end

          end
        end
      end

      errors["messages"] << "#{t('weekly_limit_reached')} " + (subject.elective_group_id.present? ? "#{subject.elective_group.name}" : "#{subject.name}") \
        if subject.max_weekly_classes <= TimetableEntry.find(:all,:conditions =>{:subject_id=>subject.id,:timetable_id=>@timetable.id, :class_timing_id => timetable_class_timings}).count unless subject.max_weekly_classes.nil?
      employee = subject.lower_day_grade unless subject.elective_group_id.nil?
      errors["messages"] << "#{t('max_hour_exceeded_day')}" \
        if employee.max_hours_per_day <= TimetableEntry.find(:all,:conditions => "timetable_entries.timetable_id=#{@timetable.id} AND timetable_entries.employee_id = #{employee.id} AND weekday_id = #{weekday}",:joins=>"INNER JOIN subjects ON timetable_entries.subject_id = subjects.id INNER JOIN batches ON subjects.batch_id = batches.id AND batches.is_active = 1 AND batches.is_deleted = 0").select{|tt| timetable_class_timings.include? tt.class_timing_id}.count unless employee.max_hours_per_day.nil?

      # check for max hours per week
      employee = subject.lower_week_grade unless subject.elective_group_id.nil?
      errors["messages"] << "#{t('max_hour_exceeded_week')}" \
        if employee.max_hours_per_week <= TimetableEntry.find(:all,:conditions => "timetable_entries.timetable_id=#{@timetable.id} AND timetable_entries.employee_id = #{employee.id}",:joins=>"INNER JOIN subjects ON timetable_entries.subject_id = subjects.id INNER JOIN batches ON subjects.batch_id = batches.id AND batches.is_active = 1 AND batches.is_deleted = 0").select{|tt| timetable_class_timings.include? tt.class_timing_id}.count unless employee.max_hours_per_week.nil?

      if errors["messages"].empty?
        unless tte.nil?
          TimetableEntry.update(tte.id, :subject_id => subject.id, :employee_id=>employee.id,:timetable_id=>@timetable.id)
          AllocatedClassroom.destroy_all("timetable_entry_id = #{tte.id}")
        else
          TimetableEntry.new(:weekday_id=>weekday,:class_timing_id=>class_timing, :subject_id => subject.id, :employee_id=>employee.id,:batch_id=>@batch.id,:timetable_id=>@timetable.id).save
        end
      else
        @validation_problems[tte_id] = errors
      end
    end
    
    tte_from_batch_and_tt(@timetable.id)
    render :update do |page|
      page.replace 'tt_over',:partial=>'new_entry'
    end
    #    render :partial => "new_entry"
  end

  def tt_entry_update2
    @errors = {"messages" => []}
    @timetable=Timetable.find(params[:timetable_id])
    @batch=Batch.find(params[:batch_id])
    subject = Subject.find(params[:sub_id])
    co_ordinate=params[:tte_id].split("_")
    weekday=co_ordinate[0].to_i
    class_timing=co_ordinate[1].to_i
    #      tte = TimetableEntry.find(tte_id)
    overlapped_tte = TimetableEntry.find_all_by_weekday_id_and_class_timing_id_and_employee_id_and_timetable_id(weekday,class_timing,params[:emp_id],@timetable.id)
    if overlapped_tte.nil?
      tte = TimetableEntry.find_by_weekday_id_and_class_timing_id_and_batch_id_and_timetable_id(weekday,class_timing,@batch.id,@timetable.id)
      unless tte.nil?
        TimetableEntry.update(tte.id, :subject_id => params[:sub_id], :employee_id => params[:emp_id])
      else
        TimetableEntry.new(:weekday_id=>weekday,:class_timing_id=>class_timing, :subject_id => params[:sub_id], :employee_id => params[:emp_id],:batch_id=>@batch.id,:timetable_id=>@timetable.id).save
      end
    else
      overlapped_tte.each {|d| d.destroy } if params[:overwrite].present?
      tte = TimetableEntry.find_by_weekday_id_and_class_timing_id_and_batch_id_and_timetable_id(weekday,class_timing,@batch.id,@timetable.id)
      unless tte.nil?
        TimetableEntry.update(tte.id, :subject_id => params[:sub_id], :employee_id => params[:emp_id])
      else
        TimetableEntry.new(:weekday_id=>weekday,:class_timing_id=>class_timing, :subject_id => params[:sub_id], :employee_id => params[:emp_id],:batch_id=>@batch.id,:timetable_id=>@timetable.id).save
      end
    end
    tte_from_batch_and_tt(@timetable.id)
    render :update do |page|
      page.replace_html "box", :partial=> "timetable_box"
      page.replace_html "subjects-select", :partial=> "employee_select"
      page.replace_html "error_div_#{params[:tte_id]}", :text => "<div class='allotted'></div><div class='msg_text'>#{t('allocated')}</div><div id='problem_ct1'>#{WeekdaySet.default_weekdays[params[:week_day].to_s]},#{format_date(ClassTiming.find(params[:class_timing]).start_time,:format=>:time)}-#{format_date(ClassTiming.find(params[:class_timing]).end_time,:format=>:time)}</div>#{params[:overwrite].present? ? "<div id='descr_msg'>" + t('removed') + ' ' + @batch.name + ' ' + t('for_text') + ' ' + subject.name + "</div>" : ''}"
    end
    #    render :partial => "new_entry"
  end

  def tt_entry_noupdate2
    render :update do |page|
      page.replace_html "error_div_#{params[:tte_id]}", :text => "<div class='cancelled'></div><div class='msg_text'>#{t('cancelled_allocation')}</div><div id='problem_ct1'>#{WeekdaySet.default_weekdays[params[:week_day].to_s]},#{format_date(ClassTiming.find(params[:class_timing]).start_time,:format=>:time)}-#{format_date(ClassTiming.find(params[:class_timing]).end_time,:format=>:time)}</div>"
    end
  end



  #  for script

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
  
  def check_valid_timetable
    @timetable=Timetable.find_by_id(params[:timetable_id])

    if @timetable.nil?
      flash[:notice] = t('former_timetable')
      redirect_to :controller => "user", :action => "dashboard"
    end
  end
end

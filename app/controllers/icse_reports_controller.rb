class IcseReportsController < ApplicationController
  before_filter [:login_required,:protect_other_student_data]
  filter_access_to :all, :except=>[:index,:generate_reports,:student_transcript,:student_wise_report,:student_report,:student_report_pdf,:student_transcript,:subject_wise_report,:student_report_pdf,:student_transcript,:subject_wise_report,:list_batches,:list_subjects,:list_exam_groups,:subject_wise_generated_report,:internal_and_external_mark_pdf,:detailed_internal_and_external_mark_pdf,:internal_and_external_mark_csv,:detailed_internal_and_external_mark_csv,:consolidated_report,:consolidated_generated_report,:consolidated_report_csv]
  filter_access_to [:index,:generate_reports,:student_transcript,:student_wise_report,:student_report,:student_report_pdf,:student_transcript,:subject_wise_report,:student_report_pdf,:student_transcript,:subject_wise_report,:list_batches,:list_subjects,:list_exam_groups,:subject_wise_generated_report,:internal_and_external_mark_pdf,:detailed_internal_and_external_mark_pdf,:internal_and_external_mark_csv,:detailed_internal_and_external_mark_csv,:consolidated_report,:consolidated_generated_report,:consolidated_report_csv],:attribute_check=>true, :load_method => lambda { current_user }
  helper_method :to_grade
  helper_method :to_grade_icse
  def index
    
  end

  def generate_reports
    @courses = Course.icse
    if request.post?
      unless params[:course][:batch_ids].blank?
        errors = []
        batches = Batch.find_all_by_id(params[:course][:batch_ids])
        #        batches.each do |batch|
        #          batch.delete_icse_reports
        #          batch.generate_icse_reports
        #        end
        batches.each do |batch|
          batch.job_type = "4"
          Delayed::Job.enqueue(batch)
        end
        flash[:notice]="Report generation in queue for batches #{batches.collect(&:full_name).join(", ")}. <a href='/scheduled_jobs/Batch/4'>Click Here</a> to view the scheduled job."
        flash[:error]=errors
      else
        flash[:notice]="No batch selected"
      end
    end
  end

  def batches_ajax
    if request.xhr?
      @course = Course.find_by_id(params[:course_id]) unless params[:course_id].blank?
      @batches = @course.batches.active if @course
      if params[:type]=="list"
        render :partial=>"list"
      end
    end
  end

  def student_wise_report
    @batches=Batch.icse
    if request.post?
      @batch=Batch.find(params[:batch_id]) if params[:batch_id].present?
      if @batch.present?
        @grading_level_list=@batch.grading_level_list
        @students=@batch.students.all(:order=>"first_name ASC")
        @student = @students.first
        if @student
          @exam_groups=@batch.exam_groups.all(:joins=>:icse_exam_category)
          fetch_data
        end
        render(:update) do |page|
          page.replace_html   'student_list', :partial=>"student_list",   :object=>@students
          @student.nil? ? (page.replace_html   'report', :text=>"") : (page.replace_html   'report', :partial=>"student_report")
          page.replace_html   'hider', :text=>""
          page.replace_html   'flash', :text=>""
        end
      else
        render(:update) do |page|
          page.replace_html   'student_list', :text=>""
          page.replace_html 'report', :text=>''
          page.replace_html   'hider', :text=>''
          page.replace_html   'flash', :text=>'<div id="flash-box"><p class="flash-msg"> Select a Batch. </p></div>'
        end
      end
    end
  end

  def student_report
    @batch=Batch.find(params[:batch_id])
    @grading_level_list=@batch.grading_level_list
    @student = Student.find params[:student_id]
    if @student
      @exam_groups=@batch.exam_groups.all(:joins=>:icse_exam_category)
      fetch_data
    end
    render(:update) do |page|
      @student.nil? ? (page.replace_html   'report', :text=>"") : (page.replace_html   'report', :partial=>"student_report")
      page.replace_html   'hider', :text=>""
    end
  end

  def student_report_pdf
    @batch=Batch.find(params[:batch_id])
    @grading_level_list=@batch.grading_level_list
    @student= (params[:type]=="former" ? ArchivedStudent.find(params[:student_id]) : Student.find(params[:student_id]))
    if @student
      if current_user.student? or current_user.parent?
        @exam_groups=@batch.exam_groups.all(:joins=>:icse_exam_category,:conditions=>{"result_published"=>true})
      else
        @exam_groups=@batch.exam_groups.all(:joins=>:icse_exam_category)
      end
      fetch_data
    end
    render :pdf => "#{@student.first_name}-ICSE_Report"
  end

  def student_report_csv
    @batch=Batch.find(params[:batch_id])
    @grading_level_list=@batch.grading_level_list
    @student= (params[:type]=="former" ? ArchivedStudent.find(params[:student_id]) : Student.find(params[:student_id]))
    if @student
      if current_user.student? or current_user.parent?
        @exam_groups=@batch.exam_groups.all(:joins=>:icse_exam_category,:conditions=>{"result_published"=>true})
      else
        @exam_groups=@batch.exam_groups.all(:joins=>:icse_exam_category)
      end
      fetch_data
    end
    csv_string=FasterCSV.generate do |csv|
      cols=[]
      cols << "Name"
      cols << "#{@student.full_name}"
      csv << cols
      cols=[]
      cols << "Admission Number"
      cols << "#{@student.admission_no}"
      csv << cols
      if Configuration.enabled_roll_number?
        cols=[]
        cols << "Roll No"
        cols << "#{@student.roll_number}"
        csv << cols
      end
      cols=[]
      cols << "#{t('course')}"
      cols << "#{@batch.course.full_name}"
      csv << cols
      cols =[]
      cols << "Batch"
      cols << @batch.name
      csv << cols
      cols=[]
      csv << cols
      cols=[]
      cols << "Overall Report"
      csv<< cols
      cols=[]
      cols << ""
      cols << " "
      @exam_groups.each do |eg|
        if eg.icse_exam_category.is_detailed_report?
          cols << eg.icse_exam_category.name
          cols << ""
          cols << ""
        else
          cols << eg.icse_exam_category.name
        end
      end
      csv << cols
      cols=[]
      cols << ""
      cols << "Subjects"
      @exam_groups.each_with_index do |eg,i|
        if eg.icse_exam_category.is_detailed_report?
          cols << "IA"
          cols << "EA"
          cols << "Total"
        else
          cols << "Total"
        end
      end
      csv << cols
      @subjects.each_with_index do |s,i|
        cols=[]
        cols << i+1
        cols << s.name
        @exam_groups.each do |eg|
          icse_weightage= s.icse_weightages.select{|w| w.icse_exam_category_id == eg.icse_exam_category_id}.first
          grade_type=icse_weightage.present? ? icse_weightage.grade_type : ""
          unless grade_type=="Mark"
            @grade_show=true
          end
          if grade_type=="Mark" or grade_type=="GradeAndMark"
            @total_show=true
          end 
          if icse_weightage.present? and icse_weightage.is_co_curricular?
            if eg.icse_exam_category.is_detailed_report?
              cols << "#{@score_hash[s.id.to_s].present?? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s].present?? to_grade_icse(@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["ia_score"].to_f,@grading_level_list,icse_weightage.grade_type,@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["ia_mark"]) : "-" : "-"  }"
              cols << " "
              cols << "#{@score_hash[s.id.to_s].present?? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s].present?? to_grade_icse(@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["total_score"].to_f,@grading_level_list,icse_weightage.grade_type,@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["total_score"]) : "-" : "-"  }"
            else
              cols << "#{@score_hash[s.id.to_s].present?? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s].present?? to_grade_icse(@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["total_score"].to_f,@grading_level_list,icse_weightage.grade_type,@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["total_score"]) : "-" : "-" }"
            end
          elsif icse_weightage.present? 
            if eg.icse_exam_category.is_detailed_report?
              cols << "#{@score_hash[s.id.to_s].present?? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s].present?? to_grade_icse(@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["ia_score"].to_f,@grading_level_list,icse_weightage.grade_type,@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["ia_mark"]) : "-" : "-" }"
              cols << "#{@score_hash[s.id.to_s].present?? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s].present?? to_grade_icse(@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["ea_score"].to_f,@grading_level_list,icse_weightage.grade_type,@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["ea_mark"]) : "-" : "-" }"
              cols << "#{@score_hash[s.id.to_s].present?? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s].present?? to_grade_icse(@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["total_score"].to_f,@grading_level_list,icse_weightage.grade_type,@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["total_score"]) : "-" : "-"  }"
            else
              cols << "#{@score_hash[s.id.to_s].present?? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s].present?? to_grade_icse(@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["total_score"].to_f,@grading_level_list,icse_weightage.grade_type,@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["total_score"]) : "-" : "-"  }"
            end
          else
            if eg.icse_exam_category.is_detailed_report?
              cols << "#{@score_hash[s.id.to_s].present?? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s].present?? precision_label(@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["ia_mark"]) : "-" : "-" }"
              cols << "#{@score_hash[s.id.to_s].present?? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s].present?? precision_label(@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["ea_mark"]) : "-" : "-" }"
              cols << "#{@score_hash[s.id.to_s].present?? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s].present?? precision_label(@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["total_score"]) : "-" : "-"  }"
            else
              cols << "#{@score_hash[s.id.to_s].present?? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s].present?? precision_label(@score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["total_score"]) : "-" : "-"  }"
            end
          end
        end
        csv << cols
      end
      if @total_show
        cols=[]
        csv << cols
        cols=[]
        cols << "Overall Details"
        csv << cols
        cols =[]
        cols << ""
        @exam_groups.each do |eg|
          cols << eg.icse_exam_category.name
        end
        csv << cols
        cols=[]
        cols << "Total"
        @exam_groups.each do |eg|
          cols << "#{@total_score_details[eg.id].present? ? @total_score_details[eg.id][:total_score] : "-"}"
        end
        csv << cols
        cols =[]
        cols << "Percentage"
        @exam_groups.each do |eg|
          cols << "#{@total_score_details[eg.id].present? ? @total_score_details[eg.id][:percentage] : "-" }"
        end
        csv << cols
      end
      cols=[]
      csv << cols
      cols=[]
      cols << "Attendance Report"
      csv << cols
      cols =[]
      @exam_groups.each do |eg|
        cols << eg.icse_exam_category.name
      end
      csv << cols
      cols=[]
      @exam_groups.each do |eg|
        cols << "#{@attendance_hash[eg.id]["leaves"]}/#{@attendance_hash[eg.id]["academic_days"]} (#{precision_label(@attendance_hash[eg.id]["percent"].to_f)}%)"
      end
      csv << cols
      cols=[]
      csv << cols
      cols << "Remarks"
      csv<< cols
      if @remarks.present?
        @remarks.each do |val|
          cols=[]
          cols << "#{ val.remarked_by.present? ? val.remarked_by : '-'}"
          cols << "#{val.remark_body.present? ? val.remark_body : '-'}"
          cols << "#{val.user.present? ? val.user.first_name : t('deleted_user')} on #{format_date(val.updated_at)}"
          csv << cols
        end
      end
      if @grade_show
        cols=[]
        csv << cols
        cols=[]
        cols << "Grading Levels"
        csv << cols
        cols=[]
        cols << "Grade"
        cols << "Minimum score"
        cols << "Remarks"
        csv << cols
        @grading_levels.each do |gl|
          cols=[]
          cols << gl.name
          cols << gl.min_score
          cols << gl.description
          csv << cols
        end
      end
    end
    filename = "#{@student.full_name}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end


  def student_transcript
    @student= (params[:type]=="former" ? ArchivedStudent.find(params[:id]) : Student.find(params[:id]))
    @batch=(params[:batch_id].blank? ? @student.batch : Batch.find(params[:batch_id]))
    @batches=@student.all_batches.reverse unless request.xhr?
    @grading_level_list=@batch.grading_level_list
    if current_user.student? or current_user.parent?
      @exam_groups=@batch.exam_groups.all(:joins=>:icse_exam_category,:conditions=>{"result_published"=>true})
    else
      @exam_groups=@batch.exam_groups.all(:joins=>:icse_exam_category)
    end
    fetch_data
    if request.xhr?
      render(:update) do |page|
        page.replace_html   'report', :partial=>"student_report"
      end
    end
  end

  def subject_wise_report
    @courses=Course.icse
    @batches=[]
    @subjects=[]
    @student_category=StudentCategory.active
    @exam_groups=[]
    @report_types=["internal_mark","external_mark","internal_and_external_mark","detailed_internal_mark","detailed_internal_and_external_mark"]
  end

  def list_batches
    if params[:course_id].present?
      course = Course.find(params[:course_id])
      @batches=course.batches
      params[:type]=="consolidated_report"? @action="list_exam_groups" : @action="list_subjects"
    else
      @batches=[]
    end
    @exam_groups=[]
    render(:update) do |page|
      page.replace_html 'batch_select', :partial=>'list_batches'
      unless params[:type]=="consolidated_report"
        @subjects=[]
        page.replace_html 'subject_select', :partial=>'list_subjects'
      end
      page.replace_html 'exam_group_select', :partial=>'list_exam_groups'
    end
  end

  def list_subjects
    if params[:batch_id].present?
      batch=Batch.find params[:batch_id]
      @subjects=batch.subjects.active
    else
      @subjects=[]
    end
    @exam_groups=[]
    render(:update) do |page|
      page.replace_html 'subject_select', :partial=>'list_subjects'
      page.replace_html 'exam_group_select', :partial=>'list_exam_groups'
    end
  end

  def list_exam_groups
    if params[:subject_id].present? 
      subject=Subject.find params[:subject_id]
      @exam_groups=subject.exams.all(:select=>"exam_groups.*",:joins=>[:exam_group=>:icse_exam_category])
    elsif  params[:batch_id].present?
      batch=Batch.find params[:batch_id]
      @exam_groups=batch.exam_groups(:joins=>:icse_exam_category)
    else
      @exam_groups=[]
    end
    render(:update) do |page|
      page.replace_html 'exam_group_select', :partial=>'list_exam_groups'
    end
  end

  def subject_wise_generated_report
    report=params[:subject_report]
    unless report[:batch_id].blank?
      unless report[:subject_id].blank?
        @batch_id=report[:batch_id]
        @subject=Subject.find report[:subject_id]
        subject_weighage
        @student_category_id=report[:student_category_id]
        @gender= report[:gender]
        @exam_groups=report[:exam_group_id].present?? ExamGroup.find_all_by_id(report[:exam_group_id]) : @subject.exams.all(:select=>"exam_groups.*",:joins=>[:exam_group=>:icse_exam_category])
        batch=Batch.find @batch_id
        @grading_level_list=batch.grading_level_list
        students
        @report_type=report[:report_type]
        if report[:report_type]=="internal_and_external_mark" or report[:report_type]=="internal_mark" or report[:report_type]=="external_mark"
          internal_and_external_mark
          render(:update) do |page|
            page.replace_html 'hider', :text=>''
            page.replace_html 'report_table', :partial=>'internal_and_external_mark'
          end
        else
          detailed_internal_and_external_mark
          render(:update) do |page|
            page.replace_html 'hider', :text=>''
            page.replace_html 'report_table', :partial=>'detailed_internal_and_external_mark'
          end
        end
      else
        error=true
        flash[:warn_notice]="Select one subject"
      end
    else
      error=true
      flash[:warn_notice]="Select one Batch"
    end
    if error
      render(:update) do |page|
        page.replace_html 'hider', :partial=>'error'
        page.replace_html 'report_table', :text=>''
      end
    end
  end

  def internal_and_external_mark_pdf
    common_data
    internal_and_external_mark
    if params[:report_type]=="internal_and_external_mark"
      render :pdf => "#{@subject.name}-ICSE_Report",:orientation => 'Landscape'
    else
      render :pdf => "#{@subject.name}-ICSE_Report",:margin=>{:left=>10,:right=>10}
    end
  end

  def detailed_internal_and_external_mark_pdf
    common_data
    detailed_internal_and_external_mark
    render :pdf => "#{@subject.name}-ICSE_Report",:orientation => 'Landscape'
  end

  def internal_and_external_mark_csv
    common_data
    internal_and_external_mark
    csv_string=FasterCSV.generate do |csv|
      cols=[]
      cols << "Batch"
      cols << "#{@batch.full_name}"
      csv << cols
      cols=[]
      cols << "Subject"
      cols << "#{@subject.name}"
      csv << cols
      cols=[]
      cols << "Exam group"
      cols << "#{@exam_groups.map(&:name).join("|") if @exam_groups.present?}"
      csv  << cols
      cols=[]
      cols << "Report type"
      cols << "#{@report_type.gsub("_", " ").camelize}"
      csv << cols
      cols=[]
      cols << "Gender"
      cols << "#{params[:gender].present?? params[:gender]=="m" ? "Male" : "Female" : "All"}"
      csv << cols
      cols=[]
      cols << "Student category"
      cols << "#{@student_category.present? ? @student_category.name : "All"}"
      csv << cols
      cols=[]
      cols << ""
      @exam_groups.each do |eg|
        cols << eg.name
        if @report_type=="internal_and_external_mark"
          cols << ""
          cols << ""
        end
      end
      csv << cols
      cols=[]
      cols << "Students"
      @exam_groups.each do |eg|
        if @report_type=="internal_and_external_mark"
          cols << "IA (#{@weightage_hash[eg.icse_exam_category_id.to_i].present?? @weightage_hash[eg.icse_exam_category_id.to_i]["ia_weightage"] : "-"})"
          cols << "EA (#{@weightage_hash[eg.icse_exam_category_id.to_i].present?? @weightage_hash[eg.icse_exam_category_id.to_i]["ea_weightage"] : "-"})"
          cols << "IA+EA (100)"
        elsif @report_type=="internal_mark"
          cols << "IA (#{@weightage_hash[eg.icse_exam_category_id.to_i].present?? @weightage_hash[eg.icse_exam_category_id.to_i]["ia_weightage"]  : "-"})"
        elsif @report_type=="external_mark"
          cols << "EA (#{@weightage_hash[eg.icse_exam_category_id.to_i].present?? @weightage_hash[eg.icse_exam_category_id.to_i]["ea_weightage"] : "-"})"
        end
      end
      csv << cols
      @students.each do |student|
        cols=[]
        student_text = "#{student.full_name}(#{student.admission_no})"
        student_text = (student.roll_number.present? ? "#{student.roll_number} -" : '') + "#{student.full_name}" if Configuration.enabled_roll_number?
        cols << student_text
        @exam_groups.each do |eg|
          if @report_type=="internal_and_external_mark"
            cols << "#{@report_hash[student.id].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["ia_score"].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["ia_score"] : " " : " " : " "}"
            cols << "#{@report_hash[student.id].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["ea_score"].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["ea_score"] : " " : " " : " "}"
            cols << "#{@report_hash[student.id].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["total_score"].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["total_score"] : " " : " " : " "}"
          elsif @report_type=="internal_mark"
            cols <<  "#{@report_hash[student.id].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["ia_score"].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["ia_score"] : " " : " " : " "}"
          elsif @report_type=="external_mark"
            cols << "#{@report_hash[student.id].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["ea_score"].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["ea_score"] : " " : " " : " "}"
          end
        end
        csv << cols.flatten
      end
    end
    filename = "#{@subject.name}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def detailed_internal_and_external_mark_csv
    common_data
    detailed_internal_and_external_mark
    csv_string=FasterCSV.generate do |csv|
      cols=[]
      cols << "Batch"
      cols << "#{@batch.full_name}"
      csv << cols
      cols=[]
      cols << "Subject"
      cols << "#{@subject.name}"
      csv << cols
      cols=[]
      cols << "Exam group"
      cols << "#{@exam_groups.map(&:name).join("|") if @exam_groups.present?}"
      csv  << cols
      cols=[]
      cols << "Report type"
      cols << "#{@report_type.gsub("_", " ").camelize}"
      csv << cols
      cols=[]
      cols << "Gender"
      cols << "#{params[:gender].present?? params[:gender]=="m" ? "Male" : "Female" : "All"}"
      csv << cols
      cols=[]
      cols << "Student category"
      cols << "#{@student_category.present? ? @student_category.name : "All"}"
      csv << cols
      cols=[]
      cols << " "
      @exam_groups.each do |eg|
        if @ia_indicators[eg.icse_exam_category_id.to_i].present?
          count=0
          count=@ia_indicators[eg.icse_exam_category_id.to_i].count
          @report_type=="detailed_internal_mark"? count=count : count=count+2
          cols << eg.name
          count.times.each do
            cols << " "
          end
        end
      end
      csv << cols
      cols=[]
      cols << "Students"
      @exam_groups.each do |eg|
        if @report_type=="detailed_internal_and_external_mark"
          if @ia_indicators[eg.icse_exam_category_id.to_i].present?
            @ia_indicators[eg.icse_exam_category_id.to_i].each do |indicator|
              cols << "#{indicator.name}(#{indicator.max_mark})"
            end
          end
          cols << "IA (#{@weightage_hash[eg.icse_exam_category_id.to_i].present?? @weightage_hash[eg.icse_exam_category_id.to_i]["ia_weightage"] : " "})"
          cols << "EA (#{@weightage_hash[eg.icse_exam_category_id.to_i].present?? @weightage_hash[eg.icse_exam_category_id.to_i]["ea_weightage"] : " "})"
          cols << "IA+EA (100)"
        elsif @report_type=="detailed_internal_mark"
          if @ia_indicators[eg.icse_exam_category_id.to_i].present?
            @ia_indicators[eg.icse_exam_category_id.to_i].each do |indicator|
              cols << "#{indicator.name}(#{indicator.max_mark})"
            end
          end
          cols << "IA (#{@weightage_hash[eg.icse_exam_category_id.to_i].present? ? @weightage_hash[eg.icse_exam_category_id.to_i]["ia_weightage"] : " "})"
        end
      end
      csv << cols
      @students.each do |student|
        cols=[]
        student_text = "#{student.full_name}(#{student.admission_no})"
        student_text = (student.roll_number.present? ? "#{student.roll_number} -" : '') + "#{student.full_name}" if Configuration.enabled_roll_number?
        cols << student_text
        @exam_groups.each do |eg|
          if @report_type=="detailed_internal_and_external_mark"
            if @ia_indicators[eg.icse_exam_category_id.to_i].present?
              @ia_indicators[eg.icse_exam_category_id.to_i].each do |indicator|
                cols << "#{@ia_score_hash[student.id.to_i].present?? @ia_score_hash[student.id.to_i][eg.icse_exam_category_id.to_s].present?? @ia_score_hash[student.id.to_i][eg.icse_exam_category_id.to_s][indicator.id].present?? @ia_score_hash[student.id.to_i][eg.icse_exam_category_id.to_s][indicator.id]["mark"] : " " : " " :" "}"
              end
            end
            cols << "#{@report_hash[student.id].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["ia_score"] : " " : " "}"
            cols << "#{@report_hash[student.id].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["ea_score"] : " " : " "}"
            cols << "#{@report_hash[student.id].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["total_score"] : " " : " " }"
          elsif @report_type=="detailed_internal_mark"
            if @ia_indicators[eg.icse_exam_category_id.to_i].present?
              @ia_indicators[eg.icse_exam_category_id.to_i].each do |indicator|
                cols << "#{@ia_score_hash[student.id.to_i].present?? @ia_score_hash[student.id.to_i][eg.icse_exam_category_id.to_s].present?? @ia_score_hash[student.id.to_i][eg.icse_exam_category_id.to_s][indicator.id].present?? @ia_score_hash[student.id.to_i][eg.icse_exam_category_id.to_s][indicator.id]["mark"] : " " : " " :" "}"
              end
            end
            cols << "#{@report_hash[student.id].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][eg.icse_exam_category_id.to_s]["ia_score"] : " " : " "}"
          end
        end
        csv << cols.flatten
      end
    end
    filename = "#{@subject.name}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def consolidated_report
    @courses=Course.icse
    @batches=[]
    @student_category=StudentCategory.active
    @exam_groups=[]
    @report_types=["internal_and_external","internal","external","total"]
  end

  def consolidated_generated_report
    report=params[:subject_report]
    unless report[:batch_id].blank?
      @batch_id=report[:batch_id]
      @student_category_id=report[:student_category_id]
      @gender= report[:gender]
      batch=Batch.find @batch_id
      @exam_groups=report[:exam_group_id].present?? ExamGroup.find_all_by_id(report[:exam_group_id]) : batch.exam_groups(:joins=>:icse_exam_category)
      @grading_level_list=batch.grading_level_list
      @subjects=batch.subjects
      @students=Student.search(:batch_id_equals=>@batch_id,:gender_like=>@gender,:student_category_id_equals=>@student_category_id)
      @report_type=report[:report_type]
      consolidated_data
      render(:update) do |page|
        page.replace_html 'hider', :text=>''
        page.replace_html 'report_table', :partial=>'consolidated_report'
      end
    else
      error=true
      flash[:warn_notice]="Select one Batch"
    end
    if error
      render(:update) do |page|
        page.replace_html 'hider', :partial=>'error'
        page.replace_html 'report_table', :text=>''
      end
    end
  end

  def consolidated_report_csv
    @batch_id=params[:batch_id]
    @student_category_id=params[:student_category_id]
    @gender= params[:gender]
    batch=Batch.find @batch_id
    @exam_groups=params[:exam_group_id].present?? ExamGroup.find_all_by_id(params[:exam_group_id]) : batch.exam_groups(:joins=>:icse_exam_category)
    @grading_level_list=batch.grading_level_list
    @subjects=batch.subjects
    @students=Student.search(:batch_id_equals=>@batch_id,:gender_like=>@gender,:student_category_id_equals=>@student_category_id)
    @report_type=params[:report_type]
    student_category=StudentCategory.find params[:student_category_id] if params[:student_category_id].present?
    consolidated_data
    csv_string=FasterCSV.generate do |csv|
      cols=[]
      cols << "Batch"
      cols << "#{batch.full_name}"
      csv << cols
      cols=[]
      cols << "Exam group"
      cols << "#{@exam_groups.map(&:name).join("|") if @exam_groups.present?}"
      csv  << cols
      cols=[]
      cols << "Report type"
      cols << "#{@report_type.gsub("_", " ").camelize}"
      csv << cols
      cols=[]
      cols << "Gender"
      cols << "#{params[:gender].present?? params[:gender]=="m" ? "Male" : "Female" : "All"}"
      csv << cols
      cols=[]
      cols << "Student category"
      cols << "#{student_category.present? ? student_category.name : "All"}"
      csv << cols
      cols=[]
      cols << " "
      exam_group_count=@exam_groups.count
      @subjects.each do |subject|
        cols << subject.name
        exam_group_count==1 && @report_type=="internal_and_external" ? count=2 : exam_group_count==1 ? count=0 : exam_group_count!=1 && @report_type!="internal_and_external" ? count=1 : count=5
        count.times do
          cols << ""
        end
      end
      csv << cols
      cols=[]
      cols << ""
      @subjects.each do |subject|
        @exam_groups.each do |eg|
          cols << eg.name
          if @report_type=="internal_and_external"
            2.times do
              cols << ""
            end
          end
        end

      end
      csv << cols
      cols=[]
      cols << "Students"
      @subjects.each do |subject|
        @exam_groups.each do |eg|
          if @report_type=="internal_and_external"
            cols<<"IA (#{@weightage_hash[subject.id.to_s].present? ? @weightage_hash[subject.id.to_s][eg.icse_exam_category_id.to_s].present?? @weightage_hash[subject.id.to_s][eg.icse_exam_category_id.to_s]["ia_weightage"] : "-": "-"})"
            cols << "EA (#{@weightage_hash[subject.id.to_s].present? ? @weightage_hash[subject.id.to_s][eg.icse_exam_category_id.to_s].present?? @weightage_hash[subject.id.to_s][eg.icse_exam_category_id.to_s]["ea_weightage"] : "-": "-"})"
            cols << "IA+EA (100)"
          elsif @report_type=="internal"
            cols << "IA (#{@weightage_hash[subject.id.to_s].present? ? @weightage_hash[subject.id.to_s][eg.icse_exam_category_id.to_s].present?? @weightage_hash[subject.id.to_s][eg.icse_exam_category_id.to_s]["ia_weightage"] : "-": "-"})"
          elsif @report_type=="external"
            cols << "EA (#{@weightage_hash[subject.id.to_s].present? ? @weightage_hash[subject.id.to_s][eg.icse_exam_category_id.to_s].present?? @weightage_hash[subject.id.to_s][eg.icse_exam_category_id.to_s]["ea_weightage"] : "-": "-"})"
          elsif @report_type=="total"
            cols << "Total"
          end
        end
      end
      csv << cols
      @students.each do |student|
        cols=[]
        student_text = "#{student.full_name}(#{student.admission_no})"
        student_text = (student.roll_number.present? ? "#{student.roll_number} -" : '') + "#{student.full_name}" if Configuration.enabled_roll_number?
        cols << student_text
        @subjects.each do |subject|
          @exam_groups.each do |eg|
            if @report_type=="internal_and_external"
              cols << "#{@report_hash[student.id].present?? @report_hash[student.id][subject.id.to_s].present?? @report_hash[student.id][subject.id.to_s][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][subject.id.to_s][eg.icse_exam_category_id.to_s]["ia_mark"] : " " : " " : " "}"
              cols << "#{@report_hash[student.id].present?? @report_hash[student.id][subject.id.to_s].present?? @report_hash[student.id][subject.id.to_s][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][subject.id.to_s][eg.icse_exam_category_id.to_s]["ea_mark"] : " " : " " : " "}"
              cols << "#{@report_hash[student.id].present?? @report_hash[student.id][subject.id.to_s].present?? @report_hash[student.id][subject.id.to_s][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][subject.id.to_s][eg.icse_exam_category_id.to_s]["total_score"] : " " : " " : " "}"
            elsif @report_type=="internal"
              cols << "#{@report_hash[student.id].present?? @report_hash[student.id][subject.id.to_s].present?? @report_hash[student.id][subject.id.to_s][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][subject.id.to_s][eg.icse_exam_category_id.to_s]["ia_mark"] : " " : " " : " "}"
            elsif @report_type=="external"
              cols << "#{@report_hash[student.id].present?? @report_hash[student.id][subject.id.to_s].present?? @report_hash[student.id][subject.id.to_s][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][subject.id.to_s][eg.icse_exam_category_id.to_s]["ea_mark"] : " " : " " : " "}"
            elsif @report_type=="total"
              cols << "#{@report_hash[student.id].present?? @report_hash[student.id][subject.id.to_s].present?? @report_hash[student.id][subject.id.to_s][eg.icse_exam_category_id.to_s].present?? @report_hash[student.id][subject.id.to_s][eg.icse_exam_category_id.to_s]["total_score"] : " " : " " : " "}"
            end
          end
        end
        csv << cols
      end
      
    end
    filename = "#{batch.full_name}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def to_grade(score,grading_level_list)
    if /^[\d]+(\.[\d]+){0,1}$/ === score.to_s
      grading_level_list.to_a.select{|g| g.min_score <= score.to_f.round(2).round}.first.try(:name) || ""
    end
  end
  def to_grade_icse(score,grading_level_list,grade_type,mark)
    if /^[\d]+(\.[\d]+){0,1}$/ === score.to_s
      grade=grading_level_list.to_a.select{|g| g.min_score <= score.to_f.round(2).round}.first.try(:name) || ""
      if grade_type=="Grade"
        str=grade
      elsif grade_type=="GradeAndMark"
        str=mark.present? ? "#{grade}(#{mark})" : "-"
      else
        str=mark.present? ? mark : "-"
      end
      return str
    end
  end

  private

  def fetch_data
    student_id=@student.class.name=="ArchivedStudent"? @student.former_id : @student.id
    @student_id=student_id
    @remarks= RemarkMod.generate_common_remark_form("icse_student_wise_general",@student.id,nil,1,{:batch_id=>@batch.id,:student_id=>student_id})
    @grading_levels=GradingLevel.for_batch(@batch.id).present? ? GradingLevel.for_batch(@batch.id) : GradingLevel.default
    @score_hash={}
    normal_subjects=@batch.subjects.all(:conditions=>{:elective_group_id=>nil},:include=>[:exams,:icse_weightages])
    elective_subjects=@student.subjects.all(:conditions=>{:batch_id=>@batch.id,:is_deleted=>false},:include=>[:exams,:icse_weightages])
    @subjects=(normal_subjects+elective_subjects).uniq.select{|x| x.exams.present?}
    @student.icse_reports.all(:select=>"icse_reports.*,exam_groups.icse_exam_category_id,subject_id,subjects.code as sub_code",:joins=>{:exam=>[:exam_group,:subject]},:conditions=>{:batch_id=>@batch.id}).group_by(&:subject_id).each do |subject_id,val|
      @score_hash[subject_id]={}
      val.group_by(&:icse_exam_category_id).each do |icse_exam_category_id,val2|
        score=val2[0]
        @score_hash[subject_id][icse_exam_category_id]={"ea_mark"=>score.ea_mark,"ia_mark"=>score.ia_mark,"ea_score"=>score.ea_score,"ia_score"=>score.ia_score,"total_score"=>score.total_score}
      end
    end
    @total_score_details={}
    if @score_hash.present?
      @exam_groups.each do |eg|
        @total_score_details[eg.id]={}
        total_score=0.0
        subject_number=0
        @subjects.each do |s|
          icse_weightage= s.icse_weightages.select{|w| w.icse_exam_category_id == eg.icse_exam_category_id}.first
          if icse_weightage.present? and !icse_weightage.is_co_curricular?
            @no_total=@score_hash[s.id.to_s].present? ? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s].present? ? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["total_score"].present? ? false : true : false : false
            total_score+=@score_hash[s.id.to_s].present? ? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s].present? ? @score_hash[s.id.to_s][eg.icse_exam_category_id.to_s]["total_score"].to_f : 0 : 0
            subject_number+=1
          end
        end
        if subject_number >0 and !@no_total
          @total_score_details[eg.id]={:total_score=>"#{total_score.to_f.round}/#{subject_number*100}",:percentage=>(total_score/subject_number).round}
        end
      end
    end
    @attendance_hash={}
    config=Configuration.find_by_config_key('StudentAttendanceType')
    @exam_groups.each_with_index do |eg,i|
      unless config.config_value == 'Daily'
        i==0? month_date=@batch.start_date.to_date : month_date=(@exam_groups[i-1].exam_date.to_date+1).to_date
        end_date=eg.exam_date.to_date
        academic_days=@batch.subject_hours(month_date, end_date, 0).values.flatten.compact.count
        student_attendance= SubjectLeave.find(:all,:select=>"(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date BETWEEN '#{month_date}' AND '#{end_date}' and subject_leaves.batch_id=#{@batch.id},subject_leaves.id,NULL))) as leaves,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date BETWEEN '#{month_date}' AND '#{end_date}' and subject_leaves.batch_id=#{@batch.id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent",:conditions=>{:batch_id=>@batch.id,:student_id=>student_id}).first
        @attendance_hash[eg.id]={"percent"=>student_attendance.percent,"leaves"=>student_attendance.leaves.to_f,"academic_days"=>academic_days.to_f}
      else
        i==0? month_date=@batch.start_date.to_date : month_date=(@exam_groups[i-1].exam_date.to_date+1).to_date
        end_date=eg.exam_date.to_date
        working_days=@batch.date_range_working_days(month_date,end_date)
        academic_days=  working_days.select{|v| v<=end_date}.count
        student_attendance= Attendance.find(:all,:select => "(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{@batch.id} and `attendances`.`month_date` BETWEEN '#{month_date}' AND '#{end_date}',attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{@batch.id} and `attendances`.`month_date` BETWEEN '#{month_date}' AND '#{end_date}',attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{@batch.id} and `attendances`.`month_date` BETWEEN '#{month_date}' AND '#{end_date}',attendances.id,NULL))))) as leaves,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{@batch.id} and `attendances`.`month_date` BETWEEN '#{month_date}' AND '#{end_date}',attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{@batch.id} and `attendances`.`month_date` BETWEEN '#{month_date}' AND '#{end_date}',attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{@batch.id} and `attendances`.`month_date` BETWEEN '#{month_date}' AND '#{end_date}',attendances.id,NULL)))))/#{academic_days}*100 as percent",:conditions => {:batch_id => @batch.id,:student_id=>student_id}).first
        @attendance_hash[eg.id]={"percent"=>student_attendance.percent,"leaves"=>student_attendance.leaves.to_f,"academic_days"=>academic_days.to_f}
      end
    end
  end

  def common_data
    @batch_id=params[:batch_id]
    @subject=Subject.find params[:subject_id]
    subject_weighage
    @student_category_id=params[:student_category_id]
    @gender= params[:gender]
    @exam_groups=params[:exam_group_id].present?? ExamGroup.find_all_by_id(params[:exam_group_id]) : @subject.exams.all(:select=>"exam_groups.*",:joins=>[:exam_group=>:icse_exam_category])
    batch=Batch.find @batch_id
    @grading_level_list=batch.grading_level_list
    students
    @report_type=params[:report_type]
    @batch=Batch.find @batch_id
    @student_category=StudentCategory.find params[:student_category_id] if params[:student_category_id].present?
  end

  def subject_weighage
    @weightage_hash={}
    @subject.icse_weightages.group_by(&:icse_exam_category_id).each do |icse_exam_category_id,result|
      weightage=result[0]
      @weightage_hash[icse_exam_category_id]={"ea_weightage"=>weightage.ea_weightage,"ia_weightage"=>weightage.ia_weightage,"is_co_curricular"=>weightage.is_co_curricular}
    end
  end

  def students
    if @subject.students.empty?
      @students=Student.search(:batch_id_equals=>@batch_id,:gender_like=>@gender,:student_category_id_equals=>@student_category_id)
    else
      @students= Student.send :with_scope,:find=>{:conditions=>{:students_subjects=>{:subject_id=>@subject.id}} ,:joins=>"INNER JOIN `students_subjects` ON `students`.id = `students_subjects`.student_id"} do Student.search(:batch_id_equals=>@batch_id,:gender_like=>@gender,:student_category_id_equals=>@student_category_id) end
    end
  end
  
  def internal_and_external_mark
    @report_hash={}
    subject_weightages=@subject.icse_weightages
    IcseReport.all(:select=>"icse_reports.*,exam_groups.icse_exam_category_id,subject_id,subjects.code as sub_code",:joins=>{:exam=>[:exam_group,:subject]},:conditions=>["icse_reports.batch_id=? and subject_id=? and exam_groups.id IN (?)",@batch_id,@subject.id,@exam_groups.collect(&:id)]).group_by(&:student_id).each do |student_id,val|
      @report_hash[student_id]={}
      val.group_by(&:icse_exam_category_id).each do |icse_exam_category_id,val1|
        score=val1[0]
        weightage=subject_weightages.select{|sub| sub.icse_exam_category_id == icse_exam_category_id.to_i}.first
        if weightage.is_co_curricular?
          @report_hash[student_id][icse_exam_category_id]={"ia_score"=>"#{score.ia_mark}","ea_score"=>"-","total_score"=>score.total_score.present? ? "#{score.total_score}(#{to_grade(score.total_score,@grading_level_list)})" : "-"}
        else
          @report_hash[student_id][icse_exam_category_id]={"ia_score"=>"#{score.ia_mark}","ea_score"=>score.ea_mark.present? ? "#{score.ea_mark}" : "-","total_score"=>score.total_score.present? ? "#{score.total_score}(#{to_grade(score.total_score,@grading_level_list)})" : "-"}
        end
      end
    end
  end

  def detailed_internal_and_external_mark
    @report_hash={}
    @ia_score_hash={}
    @ia_indicators=@subject.ia_groups.all(:select=>"ia_indicators.*,icse_exam_category_id",:joins=>:ia_indicators).group_by(&:icse_exam_category_id)
    IaScore.all(:select=>"ia_scores.*,icse_exam_category_id",:joins=>{:ia_indicator=>:ia_group},:conditions=>["ia_scores.batch_id=? and ia_scores.exam_id IN (?) and ia_groups.icse_exam_category_id IN (?)",@batch_id,@subject.exams.collect(&:id),@exam_groups.collect(&:icse_exam_category_id)]).group_by(&:student_id).each do |student_id,val|
      @ia_score_hash[student_id]={}
      val.group_by(&:icse_exam_category_id).each do |icse_exam_category_id,val2|
        @ia_score_hash[student_id][icse_exam_category_id]={}
        val2.group_by(&:ia_indicator_id).each do |ia_indicator_id,val3|
          @ia_score_hash[student_id][icse_exam_category_id][ia_indicator_id]={"mark"=>val3[0].mark}
        end
      end
    end
    subject_weightages=@subject.icse_weightages
    IcseReport.all(:select=>"icse_reports.*,exam_groups.icse_exam_category_id,subject_id,subjects.code as sub_code",:joins=>{:exam=>[:exam_group,:subject]},:conditions=>["icse_reports.batch_id=? and subject_id=? and exam_groups.id IN (?)",@batch_id,@subject.id,@exam_groups.collect(&:id)]).group_by(&:student_id).each do |student_id,val|
      @report_hash[student_id]={}
      val.group_by(&:icse_exam_category_id).each do |icse_exam_category_id,val1|
        score=val1[0]
        weightage=subject_weightages.select{|sub| sub.icse_exam_category_id == icse_exam_category_id.to_i}.first
        if weightage.is_co_curricular?
          @report_hash[student_id][icse_exam_category_id]={"ia_score"=>"#{score.ia_mark}","ea_score"=>"-","total_score"=>score.total_score.present? ? "#{score.total_score}(#{to_grade(score.total_score,@grading_level_list)})" : "-"}
        else
          @report_hash[student_id][icse_exam_category_id]={"ia_score"=>"#{score.ia_mark}","ea_score"=>score.ea_mark.present? ? "#{score.ea_mark}" : "-","total_score"=>score.total_score.present? ? "#{score.total_score}(#{to_grade(score.total_score,@grading_level_list)})": "-"}
        end
      end
    end
   
  end

  def consolidated_data
    @weightage_hash={}
    @subjects.all(:select=>"DISTINCT icse_weightages.*,subjects.id as subject_id",:joins=>:icse_weightages).group_by(&:subject_id).each do |subject_id,value|
      @weightage_hash[subject_id]={}
      value.group_by(&:icse_exam_category_id).each do |icse_exam_category_id,result|
        weightage=result[0]
        @weightage_hash[subject_id][icse_exam_category_id]={"ea_weightage"=>weightage.ea_weightage,"ia_weightage"=>weightage.ia_weightage,"is_co_curricular"=>weightage.is_co_curricular}
      end
    end
    @report_hash={}
    IcseReport.all(:select=>"icse_reports.*,exam_groups.icse_exam_category_id,subject_id",:joins=>{:exam=>[:exam_group,:subject]},:conditions=>["icse_reports.batch_id=? and exam_groups.id IN (?)",@batch_id,@exam_groups.collect(&:id)]).group_by(&:student_id).each do |student_id, val|
      @report_hash[student_id]={}
      val.group_by(&:subject_id).each do |subject_id,val2|
        @report_hash[student_id][subject_id]={}
        val2.group_by(&:icse_exam_category_id).each do |icse_exam_category_id,val3|
          score=val3[0]
          if @weightage_hash[subject_id.to_s][icse_exam_category_id.to_s]["is_co_curricular"]=="1"
            @report_hash[student_id][subject_id][icse_exam_category_id]={"ia_mark"=>score.ia_mark,"ea_mark"=>"-","total_score"=>score.total_score.present? ? "#{score.total_score}(#{to_grade(score.total_score.to_f,@grading_level_list)})" : "-"}
          else
            @report_hash[student_id][subject_id][icse_exam_category_id]={"ia_mark"=>score.ia_mark,"ea_mark"=>score.ea_mark.present? ? score.ea_mark : "-","total_score"=>score.total_score.present? ? "#{score.total_score}(#{to_grade(score.total_score.to_f,@grading_level_list)})" : "-"}
          end
        end
      end
    end
  end

  
  def precision_label(val)
    if defined? val and val != '' and !val.nil?
      return sprintf("%0.#{precision_count}f",val)
    else
      return
    end
  end
  def precision_count
    precision_count = Configuration.get_config_value('PrecisionCount')
    precision = precision_count.to_i < 2 ? 2 : precision_count.to_i > 9 ? 8 : precision_count.to_i
    precision
  end
  
end

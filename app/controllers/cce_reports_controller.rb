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

class CceReportsController < ApplicationController
  before_filter :login_required
  #  before_filter :load_cce_report, :only=>[:show_student_wise_report]
  filter_access_to :all, :except=>[:index,:student_wise_report,:student_report_pdf,:student_transcript,:student_report,
    :assessment_wise_report,:list_batches,:generated_report,:generated_report_csv,:generated_report_pdf,:subject_wise_report,
    :subject_wise_batches,:list_subjects,:subject_wise_generated_report,
    :subject_wise_generated_report_csv,:subject_wise_generated_report_pdf]
  #  filter_access_to :show_student_wise_report, :attribute_check => true

  filter_access_to [:index,:student_wise_report,:student_report_pdf,:student_transcript,:student_report,
    :assessment_wise_report,:list_batches,:generated_report,:generated_report_csv,:generated_report_pdf,:subject_wise_report,
    :subject_wise_batches,:list_subjects,:subject_wise_generated_report,
    :subject_wise_generated_report_csv,:subject_wise_generated_report_pdf], :attribute_check=>true, :load_method => lambda { current_user }

  def index

  end

  def create_reports
    @courses = Course.cce
    if request.post?
      unless params[:course][:batch_ids].blank?
        errors = []
        batches = Batch.find_all_by_id(params[:course][:batch_ids])
        batches.each do |batch|
          if batch.check_credit_points
            batch.job_type = "3"
            Delayed::Job.enqueue(batch)
            batch.delete_student_cce_report_cache
          else
            errors += ["Incomplete grading level credit points for #{batch.full_name}, report generation failed."]
          end
        end
        flash[:notice]="Report generation in queue for batches #{batches.collect(&:full_name).join(", ")}. <a href='/scheduled_jobs/Batch/3'>Click Here</a> to view the scheduled job."
        flash[:error]=errors
      else
        flash[:notice]="No batch selected"
      end
    end

  end

  def student_wise_report
    @all_batches=[]
    @batches=[]
    if @current_user.has_exam_privileges?
      @batches=Batch.cce
    elsif @current_user.has_required_batches?
      @current_user.employee_record.batches.each do |batch|
        @batches<<batch if batch.course.grading_type=="3" and batch.course.is_deleted==false
      end
    elsif @current_user.has_required_subjects?
      @current_user.employee_record.subjects.each do |subject|
        @all_batches<<subject.batch if subject.batch.course.grading_type=="3" and subject.batch.course.is_deleted==false
      end
      @all_batches.uniq.each do |batch|
        @batches<<batch
      end
    else
      @batches=[]
    end
    if request.post?
      if params[:batch_id].present?
        @batch=Batch.find(params[:batch_id])
        @students=@batch.students.all(:order=>"first_name ASC")
        @student = @students.first
        if @student
          fetch_report
        end
        render(:update) do |page|
          page.replace_html   'student_list', :partial=>"student_list",   :object=>@students
          @student.nil? ? (page.replace_html   'report', :text=>"") : (page.replace_html   'report', :partial=>"student_report")
          page.replace_html   'hider', :text=>""
        end
      else
        render(:update) do |page|
          page.replace_html   'student_list', :text=>""
          page.replace_html   'report', :text=>""
          page.replace_html   'hider', :text=>""
        end
      end
    end
  end

  def student_report
    @student = Student.find(params[:student])
    @batch=@student.batch
    fetch_report
    render(:update) do |page|
      page.replace_html   'report', :partial=>"student_report"
    end
  end

  def student_report_pdf
    @data_hash = CceReport.fetch_student_wise_report(params)
    render :pdf => "#{@data_hash[:student].first_name}-CCE_Report"
  end

  def student_transcript
    @student= (params[:type]=="former" ? ArchivedStudent.find(params[:id]) : Student.find(params[:id]))
    @type= params[:type] || "regular"
    @batch=(params[:batch_id].blank? ? @student.batch : Batch.find(params[:batch_id]))
    @batches=@student.all_batches.reverse unless request.xhr?
    @student.batch_in_context_id = @batch.id
    fetch_report
    if request.xhr?
      render(:update) do |page|
        page.replace_html   'report', :partial=>"student_report"
      end
    end
  end
  def assessment_wise_report
    @courses=[]
    @batches=[]
    if @current_user.has_exam_privileges?
      @courses=Course.cce
    elsif @current_user.has_required_batches?
      @current_user.employee_record.batches.each do |batch|
        @courses<<batch.course if batch.course.grading_type=="3" and batch.course.is_deleted==false
      end
    elsif @current_user.has_required_subjects?
      @current_user.employee_record.subjects.each do |subject|
        @batches<<subject.batch if subject.batch.course.grading_type=="3" and subject.batch.course.is_deleted==false
      end
      @batches.uniq.each do |batch|
        @courses<<batch.course
      end
    else
      @courses=[]
    end
    
    @assessment_groups=['FA1','FA2','FA3','FA4','SA1','SA2']
    @student_category=StudentCategory.active
  end
  def list_batches
    unless params[:course_id].blank?
      course = Course.find(params[:course_id])
      if @current_user.has_exam_privileges?
        @batches=course.batches
      elsif @current_user.has_required_batches?
        @batches=@current_user.employee_record.batches.all(:conditions=>["course_id=?",course.id])
      elsif @current_user.has_required_subjects?

        @batches=[]
        @current_user.employee_record.subjects.each do |subject|
          @batches<<subject.batch if subject.batch.course_id==course.id
        end
      else
        @batches=[]
      end

    else
      @batches=[]
    end
    render(:update) do |page|
      page.replace_html 'batch_select', :partial=>'batch_list'
    end
  end

  def generated_report
    unless params[:assessment][:batch_id].blank?
      unless params[:assessment][:assessment_group].blank?
        @batch_id=params[:assessment][:batch_id]
        @student_category_id=params[:assessment][:student_category_id]
        @gender=params[:assessment][:gender]
        @assessment_group=params[:assessment][:assessment_group]
        fetch_assessment_data
        render(:update) do |page|
          page.replace_html 'hider', :text=>''
          page.replace_html 'report_table', :partial=>'assessment_report'
        end
      else
        flash[:warn_notice]="Select one Assessment Group"
        error=true
      end
    else
      flash[:warn_notice]="Select one Batch"
      error=true
    end
    if error
      render(:update) do |page|
        page.replace_html 'hider', :partial=>'error'
        page.replace_html 'report_table', :text=>''
      end
    end
  end

  def generated_report_csv
    @batch_id=params[:batch_id]
    @student_category_id=params[:student_category_id]
    @gender=params[:gender]
    @assessment_group=params[:assessment_group]
    fetch_assessment_data
    csv_string=FasterCSV.generate do |csv|
      cols=[]
      cols << 'Student'
      heads=[]
      @subjects.collect(&:name).each{|h| heads << h ; heads << ""}
      cols<< heads
      cols=cols.flatten
      csv << cols
      cols=[]
      cols << ""
      @subjects.each{|s| cols<< "Grade" ; cols << "Mark(%)"}
      csv << cols
      @students.each do |s|
        col=[]
        student_text = "#{s.full_name}(#{s.admission_no})"
        if Configuration.enabled_roll_number?
          student_text = (s.roll_number.present? ? "#{s.roll_number} -" : '') + "#{s.full_name}"
        end
        col<< student_text
        st=@fa_score_hash.find{|c,v| c==s.id}
        if st
          @subjects.each do |sub|
            sc=@fa_score_hash[s.id][sub.id.to_s]
            if sc
              col << @fa_score_hash[s.id][sub.id.to_s]['grade']
              col << @fa_score_hash[s.id][sub.id.to_s]['mark']
            else
              col << "-"
              col << "-"
            end
          end
        else
          @subjects.each do |s|
            col << "-"
            col << "-"
          end
        end
        col=col.flatten
        csv<< col
      end
    end
    filename = "#{@batch.full_name}-#{params[:assessment_group]}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end
  def generated_report_pdf
    @batch_id=params[:batch_id]
    @student_category_id=params[:student_category_id]
    @gender=params[:gender]
    @assessment_group=params[:assessment_group]
    fetch_assessment_data
    render :pdf=>'generated_report_pdf',:orientation => 'Landscape',:margin=>{:left=>10,:right=>10}
  end

  def subject_wise_report
    @batches=[]
    @courses=[]
    @subjects=[]
    @student_category=StudentCategory.active
    if @current_user.has_exam_privileges?
      @courses=Course.cce
    elsif @current_user.has_required_batches?
      @current_user.employee_record.batches.each do |batch|
        @courses<<batch.course if batch.course.grading_type=="3" and batch.course.is_deleted==false
      end
    elsif @current_user.has_required_subjects?
      @current_user.employee_record.subjects.each do |subject|
        @batches<<subject.batch if subject.batch.course.grading_type=="3" and subject.batch.course.is_deleted==false
      end
      @batches.uniq.each do |batch|
        @courses<<batch.course
      end
    else
      @courses=[]
    end
  end

  def subject_wise_batches
    unless params[:course_id].blank?
      course = Course.find(params[:course_id])
      if @current_user.has_exam_privileges?
        @batches=course.batches
      elsif @current_user.has_required_batches?
        @batches=@current_user.employee_record.batches.all(:conditions=>["course_id=?",course.id])
      elsif @current_user.has_required_subjects?

        @batches=[]
        @current_user.employee_record.subjects.each do |subject|
          @batches<<subject.batch if subject.batch.course_id==course.id
        end
      else
        @batches=[]
      end

    else
      @batches=[]
    end
    render(:update) do |page|
      page.replace_html 'batch_select', :partial=>'subject_wise_batches'
    end
  end

  def list_subjects
    unless params[:batch_id].blank?
      batch=Batch.find params[:batch_id]
      if @current_user.has_exam_privileges?
        @subjects=batch.subjects.active_and_has_exam
      elsif @current_user.has_required_batches?
        @subjects=batch.subjects.active_and_has_exam
      elsif @current_user.has_required_subjects?
        @subjects=@current_user.employee_record.subjects.active.all(:conditions=>{:batch_id=>batch.id,:no_exams=>false})
      else
        @subjects=[]
      end
    else
      @subjects=[]
    end
    render(:update) do |page|
      page.replace_html 'subject_select', :partial=>'list_subjects'
    end
  end

  def subject_wise_generated_report
    unless params[:subject_report][:batch_id].blank?
      unless params[:subject_report][:subject_id].blank?
        @batch_id=params[:subject_report][:batch_id]
        @subject_id=params[:subject_report][:subject_id]
        @student_category_id=params[:subject_report][:student_category_id]
        @gender= params[:subject_report][:gender]
        fetch_subject_wise_report
        render(:update) do |page|
          page.replace_html 'hider', :text=>''
          page.replace_html 'report_table', :partial=>'subject_wise_generated_report'
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

  def subject_wise_generated_report_csv
    @batch_id=params[:batch_id]
    @subject_id=params[:subject_id]
    @student_category_id=params[:student_category_id]
    @gender= params[:gender]
    fetch_subject_wise_report
    csv_string=FasterCSV.generate do |csv|
      cols=['Student','FA1','','FA2','','FA3','','FA4','','SA1','','SA2','']
      csv << cols
      cols=[]
      cols << ""
      6.times do
        cols << "Grade"
        cols << "Mark(%)"
      end
      csv << cols
      @students.each do |s|
        col=[]
        student_text = "#{s.full_name}(#{s.admission_no})"
        if Configuration.enabled_roll_number?
          student_text = (s.roll_number.present? ? "#{s.roll_number} -" : '') + "#{s.full_name}"
        end
        col<< student_text
        st=@score_hash.find{|c,v| c==s.id}
        if st
          if @score_hash[s.id][@fa1.to_s].nil?
            col<< "-"
            col<< "-"
          else
            col<< @score_hash[s.id][@fa1.to_s]['grade']
            col<< @score_hash[s.id][@fa1.to_s]['mark']
          end
          if @score_hash[s.id][@fa2.to_s].nil?
            col<< "-"
            col<< "-"
          else
            col<< @score_hash[s.id][@fa2.to_s]['grade']
            col<< @score_hash[s.id][@fa2.to_s]['mark']
          end
          if @score_hash[s.id][@fa3.to_s].nil?
            col<< "-"
            col<< "-"
          else
            col<< @score_hash[s.id][@fa3.to_s]['grade']
            col<< @score_hash[s.id][@fa3.to_s]['mark']
          end
          if @score_hash[s.id][@fa4.to_s].nil?
            col<< "-"
            col<< "-"
          else
            col<< @score_hash[s.id][@fa4.to_s]['grade']
            col<< @score_hash[s.id][@fa4.to_s]['mark']
          end
          if @score_hash[s.id][@sa1.to_s].nil?
            col<< "-"
            col<< "-"
          else
            col<< @score_hash[s.id][@sa1.to_s]['grade']
            col<< @score_hash[s.id][@sa1.to_s]['mark']
          end
          if @score_hash[s.id][@sa2.to_s].nil?
            col<< "-"
            col<< "-"
          else
            col<< @score_hash[s.id][@sa2.to_s]['grade']
            col<< @score_hash[s.id][@sa2.to_s]['mark']
          end
        else
          12.times.each do
            col << "-"
          end
        end
        col=col.flatten
        csv<< col
      end
    end
    filename = "#{@batch.full_name}-#{@subject.name}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def subject_wise_generated_report_pdf
    @batch_id=params[:batch_id]
    @subject_id=params[:subject_id]
    @student_category_id=params[:student_category_id]
    @gender= params[:gender]
    fetch_subject_wise_report
    render :pdf=>'generated_report_pdf',:orientation => 'Landscape'
  end


  private

  def fetch_report
    @report=@student.individual_cce_report_cached
    @subjects=@student.all_subjects.select{|x| x.exams.present?}
    @exam_groups=ExamGroup.find_all_by_id(@report.exam_group_ids, :include=>:cce_exam_category)
    coscholastic=@report.coscholastic
    @observation_group_ids=coscholastic.collect(&:observation_group_id)
    @observation_groups=ObservationGroup.find_all_by_id(@observation_group_ids).collect(&:name)
    @co_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @obs_groups=@batch.observation_groups.to_a
    @og=@obs_groups.group_by(&:observation_kind)
    @co_hashi = {}
    @og.each do |kind, ogs|
      @co_hashi[kind]=[]
      coscholastic.each{|cs| @co_hashi[kind] << cs if ogs.collect(&:id).include? cs.observation_group_id}
    end
  end
  def fetch_assessment_data
    hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    fa_obtained_score_hash={}
    @batch=Batch.find @batch_id
    fa_groups=['FA1','FA2','FA3','FA4']
    @students=Student.search(:batch_id_equals=>@batch_id,:gender_like=>@gender,:student_category_id_equals=>@student_category_id)
    unless @students.nil?
      student_ids=@students.collect(&:id)
    end
    @subjects=@batch.subjects.active_and_has_exam
    grades=@batch.grading_level_list
    if fa_groups.include? @assessment_group
      exams = []
      exams=Exam.find_all_by_subject_id_and_exam_group_id(@subjects.collect(&:id),@batch.exam_groups.collect(&:id),:include=>{:subject=>:fa_groups})
      fa_group_ids=[]
      exams.each do |exam|
        fa_group=exam.subject.fa_groups.select{|s| s.name.split.last==@assessment_group}.first
        unless fa_group.nil?
          fa_group_ids << fa_group.id
        end
      end
      exam_ids=exams.collect(&:id)
      @fa_score_hash={}
      CceReport.scholastic.all(:select=>"cce_reports.*,exams.subject_id,student_id,fa_criterias.fa_group_id,fa_criterias.max_marks as max_marks,fa_groups.criteria_formula as c_formula,fa_criterias.formula_key as c_key",:joins=>[{:fa_criteria=>:fa_group},:exam], :conditions=>{:student_id=>student_ids,:exam_id=>exam_ids,:fa_groups=>{:id=>fa_group_ids}}).group_by(&:student_id).each do |k,v|
        @fa_score_hash[k]={}
        v.group_by(&:subject_id).each do |k1,v1|
          v1.group_by(&:fa_group_id).each do |k2,v2|
            fa_formula=v2.collect(&:c_formula).uniq.first
            if fa_formula.present?
              v2.group_by(&:c_key).each do |indicator,mark|
                hsh1={indicator=>(mark[0].grade_string.to_f)}
                fa_obtained_score_hash.merge!hsh1
              end
              assign_values=[]
              fa_obtained_score_hash.each{|fas,m| assign_values << "#{fas}=#{m}"}
              assign_values.each{|s| instance_eval(s.gsub("`",""))}
              fa_obtained_mark=begin 
                instance_eval(fa_formula)
              rescue
                0
              end
              fa_max_score_hash={}
              v2.group_by(&:c_key).each do |indicator,mark|
                hsh1={indicator=>100.0}
                fa_max_score_hash.merge!hsh1
              end
              assign_values=[]
              fa_max_score_hash.each{|fas,m| assign_values << "#{fas}=#{m}"}
              assign_values.each{|s| instance_eval(s.gsub("`",""))}
              fa_max_mark=begin 
                instance_eval(fa_formula)
              rescue
                1
              end
              grade_value=(fa_obtained_mark/fa_max_mark)*100
              grade=grades.to_a.find{|g| g.min_score <= grade_value.round(2).round}.try(:name) || "-"
              grade_mark= grade=="-"? "-" : grade_value.round(2)
              @fa_score_hash[k][k1]={'grade'=>grade , 'mark'=>grade_mark}
            else
              grade_value = v1.count > 0 ? v1.sum{|e| e.grade_string.to_f}/v1.count: 0
              grade=grades.to_a.find{|g| g.min_score <= grade_value.round(2).round}.try(:name) || "-"
              grade_mark= grade=="-"? "-" : grade_value.round(2)
              @fa_score_hash[k][k1]={'grade'=>grade , 'mark'=>grade_mark}
            end
          end
        end
      end
    else
      if @assessment_group=='SA1'
        @fa_score_hash={}
        cce=@batch.fa_groups.select{|s| s.name.split.last=="FA1" or s.name.split.last=="FA2"}
        unless cce.blank?
          cce_id=cce.first.cce_exam_category_id
          exam_group=@batch.exam_groups.find_by_cce_exam_category_id(cce_id)
          exams= Exam.find_all_by_subject_id_and_exam_group_id(@subjects.collect(&:id),exam_group.id)
          ExamScore.all(:select=>'exam_scores.*,student_id,subject_id,exams.maximum_marks',:conditions=>{:exam_id=>exams.collect(&:id)},:joins=>[:exam],:include=>:grading_level).group_by(&:student_id).each do |k,v|
            @fa_score_hash[k]={}
            v.group_by(&:subject_id).each do |k1,v1|
              grade=v1.first.grading_level ? v1.first.grading_level.name : '-'
              grade_mark=v1[0].maximum_marks.to_f!=0?  grade=="-"? "-" : (v1[0].marks.to_f/v1 [0].maximum_marks.to_f)*100 : "-"

              grade_mark=grade_mark.round(2) unless grade_mark=="-"
              @fa_score_hash[k][k1]={'grade'=>grade , 'mark'=>grade_mark}
            end
          end
        end
      else
        @fa_score_hash={}
        cce=@batch.fa_groups.select{|s| s.name.split.last=="FA3" or s.name.split.last=="FA4"}
        unless cce.blank?
          cce_id=cce.first.cce_exam_category_id
          exam_group=@batch.exam_groups.find_by_cce_exam_category_id(cce_id)
          exams= Exam.find_all_by_subject_id_and_exam_group_id(@subjects.collect(&:id),exam_group.id)
          ExamScore.all(:select=>'exam_scores.*,student_id,subject_id,exams.maximum_marks',:conditions=>{:exam_id=>exams.collect(&:id)},:joins=>[:exam]).group_by(&:student_id).each do |k,v|
            @fa_score_hash[k]={}
            v.group_by(&:subject_id).each do |k1,v1|
              grade=v1.first.grading_level ? v1.first.grading_level.name : '-'
              grade_mark=v1[0].maximum_marks.to_f!=0 ? grade=="-"? "-" : (v1[0].marks.to_f/v1[0].maximum_marks.to_f)*100 : "-"
              grade_mark=grade_mark.round(2) unless grade_mark=="-"
              @fa_score_hash[k][k1]={'grade'=>grade , 'mark'=>grade_mark}
            end
          end
        end
      end
    end
  end
  def avg(*args)
    count=args.length
    total=0
    args.each{|s| total+=s.to_f}
    return (total.to_f/count.to_f)
  end

  def best(*args)
    count=args[0]
    scores=args-args[0].to_a
    order=scores.sort_by{|d| d.to_f}.reverse
    values=order[0..(count-1)]
    total=0
    values.each{|s| total+=s.to_f}
    return total
  end
  def fetch_subject_wise_report
    hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    fa_obtained_score_hash={}
    @batch=Batch.find @batch_id
    @subject=Subject.find @subject_id
    fa_groups=@subject.fa_groups
    grades=@batch.grading_level_list
    exam_ids=Exam.find_all_by_subject_id(@subject_id).collect(&:id)
    if @subject.students.empty?
      @students=Student.search(:batch_id_equals=>@batch_id,:gender_like=>@gender,:student_category_id_equals=>@student_category_id)
    else
      @students= Student.send :with_scope,:find=>{:conditions=>{:students_subjects=>{:subject_id=>@subject_id}} ,:joins=>"INNER JOIN `students_subjects` ON `students`.id = `students_subjects`.student_id"} do Student.search(:batch_id_equals=>@batch_id,:gender_like=>@gender,:student_category_id_equals=>@student_category_id) end
    end
    unless @students.nil?
      student_ids=@students.collect(&:id)
    end
    @fa1=fa_groups.select{|s| s.name.split.last=='FA1'}.first ? fa_groups.select{|s| s.name.split.last=='FA1'}.first.id : 0
    @fa2=fa_groups.select{|s| s.name.split.last=='FA2'}.first ? fa_groups.select{|s| s.name.split.last=='FA2'}.first.id : 0
    @fa3=fa_groups.select{|s| s.name.split.last=='FA3'}.first ? fa_groups.select{|s| s.name.split.last=='FA3'}.first.id : 0
    @fa4=fa_groups.select{|s| s.name.split.last=='FA4'}.first ? fa_groups.select{|s| s.name.split.last=='FA4'}.first.id : 0
    @sa1=0
    @sa2=0
    cce=fa_groups.select{|s| s.name.split.last=="FA1" or s.name.split.last=="FA2"}
    unless cce.blank?
      cce_id=cce.first.cce_exam_category_id
      exam_group=@batch.exam_groups.find_by_cce_exam_category_id(cce_id)
      @sa1 = exam_group.present? ? exam_group.id : 0
    end
    cce=fa_groups.select{|s| s.name.split.last=="FA3" or s.name.split.last=="FA4"}
    unless cce.blank?
      cce_id=cce.first.cce_exam_category_id
      exam_group=@batch.exam_groups.find_by_cce_exam_category_id(cce_id)
      @sa2 = exam_group.present? ? exam_group.id : 0
    end
    fa_score_hash={}
    CceReport.scholastic.all(:select=>"cce_reports.*,exams.subject_id,student_id,fa_criterias.fa_group_id,fa_criterias.max_marks as max_marks,fa_groups.criteria_formula as c_formula,fa_criterias.formula_key as c_key",:joins=>[{:fa_criteria=>:fa_group},:exam], :conditions=>{:exam_id=>exam_ids,:student_id=>student_ids}).group_by(&:student_id).each do |k,v|
      fa_score_hash[k]={}
      v.group_by(&:fa_group_id).each do |k1,v1|
        fa_formula=v1.collect(&:c_formula).uniq.first
        if fa_formula.present?
          v1.group_by(&:c_key).each do |indicator,mark|
            hsh1={indicator=>(mark[0].grade_string.to_f)}
            fa_obtained_score_hash.merge!hsh1
          end
          assign_values=[]
          fa_obtained_score_hash.each{|fas,m| assign_values << "#{fas}=#{m}"}
          assign_values.each{|s| instance_eval(s.gsub("`",""))}
          fa_obtained_mark=begin
            instance_eval(fa_formula)
          rescue
            0
          end
          fa_max_score_hash={}
          v1.group_by(&:c_key).each do |indicator,mark|
            hsh1={indicator=>100.0}
            fa_max_score_hash.merge!hsh1
          end
          assign_values=[]
          fa_max_score_hash.each{|fas,m| assign_values << "#{fas}=#{m}"}
          assign_values.each{|s| instance_eval(s.gsub("`",""))}
          fa_max_mark=begin
            instance_eval(fa_formula)
          rescue
            1
          end
          grade_value=(fa_obtained_mark/fa_max_mark)*100
          grade=grades.to_a.find{|g| g.min_score <= grade_value.to_f.round(2).round}.try(:name) || "-"
          grade_mark= grade=="-"? "-" : grade_value.to_f.round(2)
          fa_score_hash[k][k1]={'grade'=>grade , 'mark'=>grade_mark}
        else
          grade_value = v1.count > 0 ? v1.sum{|e| e.grade_string.to_f}/v1.count: 0
          grade=grades.to_a.find{|g| g.min_score <= grade_value.to_f.round(2).round}.try(:name) || "-"
          grade_mark= grade=="-"? "-" : grade_value.to_f.round(2)
          fa_score_hash[k][k1]={'grade'=>grade , 'mark'=>grade_mark}
        end
      end
    end
    exam_score_hash={}
    ExamScore.all(:select=>'exam_scores.*,student_id,exam_group_id,exams.maximum_marks',:conditions=>{:exam_id=>exam_ids,:student_id=>student_ids},:joins=>[:exam],:include=>:grading_level).group_by(&:student_id).each do |k,v|
      exam_score_hash[k]={}
      v.group_by(&:exam_group_id).each do |k1,v1|
        grade=v1.first.grading_level ? v1.first.grading_level.name : '-'
        grade_mark=v1[0].maximum_marks.to_f!=0 ? grade=="-"? "-"  : (v1[0].marks.to_f/v1[0].maximum_marks.to_f)*100 :"-"
        grade_mark=grade_mark.round(2) unless grade_mark=="-"
        exam_score_hash[k][k1]={'grade'=>grade , 'mark'=>grade_mark}
      end
    end
    @score_hash=fa_score_hash.merge(exam_score_hash){|key,v1,v2| v1.merge(v2) }
  end

end

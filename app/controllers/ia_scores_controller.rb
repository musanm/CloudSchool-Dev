class IaScoresController < ApplicationController
  before_filter [:login_required,:check_icse_configuration]
  filter_access_to [:ia_scores,:update_ia_score],:attribute_check=>true, :load_method => lambda { Exam.find params[:exam_id] }

  def ia_scores
    fa_score_data
    if @subject.elective_group_id.nil?
      @students=@batch.students.all(:order=>"first_name ASC")
    else
      @students=@subject.students.all(:order=>"first_name ASC")
    end
    if params[:student_id].present?
      @student=Student.find params[:student_id]
    else
      @student=@students.first
    end
    @ia_scores=IaScore.all(:select=>"ia_indicator_id,mark",:conditions=>{:student_id=>@student.id,:exam_id=>@exam.id}).group_by(&:ia_indicator_id)
    if request.xhr?
      render :update do |page|
        page.replace_html 'fa_sheet', :partial=>"ia_sheet"
        page.replace_html 'flash-box',:text=>""
        page.replace_html 'form-errors',:text=>""
      end
    end
  end

  def update_ia_score
    fa_score_data
    @student=Student.find params[:student_id]
    ia_scores=params[:ia_scores]
    ActiveRecord::Base.transaction do
      ia_scores.each do |indicator_id,mark|
        @ia_score=IaScore.find(:first,:conditions=>{:exam_id=>params[:exam_id],:batch_id=>params[:batch_id],:student_id=>params[:student_id],:ia_indicator_id=>indicator_id})
        if @ia_score.present?
          if @ia_score.update_attributes(:mark=>mark)
          else
            @error=true
            break
          end
        else
          @ia_score=IaScore.new(:exam_id=>params[:exam_id],:batch_id=>params[:batch_id],:student_id=>params[:student_id],:ia_indicator_id=>indicator_id,:mark=>mark)
          unless @ia_score.save
            @error=true
            break
          end
        end
      end
      if @error
        raise ActiveRecord::Rollback
      end
    end
    @ia_scores=IaScore.all(:select=>"ia_indicator_id,mark",:conditions=>{:student_id=>@student.id,:exam_id=>@exam.id}).group_by(&:ia_indicator_id)
    render :update do |page|
      unless @error
        page.replace_html 'fa_sheet', :partial=>"ia_sheet"
        page.replace_html 'form-errors',:text=>""
        page.replace_html 'flash-box',:text=>'<div id="flash-box"><p class="flash-msg"> IA Score saved successfully </p></div>'
      else
        page.replace_html 'flash-box',:text=>""
        page.replace_html 'form-errors', :partial => 'errors', :object => @ia_score
      end
    end
  end

  private

  def fa_score_data
    @exam=Exam.find params[:exam_id]
    @subject=@exam.subject
    @ia_group=@subject.ia_groups.select{|s| s.icse_exam_category_id==@exam.exam_group.icse_exam_category_id}.first
    @batch=@subject.batch
    unless @ia_group.present?
      assign_ia_group
    end
    unless @subject.icse_weightages.present?
      assign_icse_weightage
    end
    @ia_indicators=@ia_group.ia_indicators.all(:order=>"id") if @ia_group.present?
  end

  def assign_ia_group
    batch_subject = Subject.find(:first,:joins=>:batch, :conditions=>{:batches=>{:course_id=>@batch.course_id},:is_deleted=>false,:code=>@subject.code},:group=>:code)
    if batch_subject.present?
      @subject.ia_groups=batch_subject.ia_groups
      if @subject.save
        @ia_group=@subject.ia_groups.select{|s| s.icse_exam_category_id==@exam.exam_group.icse_exam_category_id}.first
      end
    end
  end
  
  def assign_icse_weightage
    batch_subject = Subject.find(:first,:joins=>:batch, :conditions=>{:batches=>{:course_id=>@batch.course_id},:is_deleted=>false,:code=>@subject.code},:group=>:code)
    if batch_subject.present?
      @subject.icse_weightages=batch_subject.icse_weightages
      unless @subject.save
        @icse_weightage_error=true
      end
    else
      @icse_weightage_error=true
    end
  end

  private
  
  def check_icse_configuration
    unless Configuration.icse_enabled?
      redirect_to :controller => 'user', :action => 'dashboard'
      flash[:notice] = "#{t('flash_msg4')}"
    end
  end
end

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

module CceReportMod

  MasterCceReport = Struct.new(:student_id, :coscholastic, :scholastic, :exam_ids,:exam_group_ids)
  ScholasticReport = Struct.new(:subject_id, :exams, :fa, :sa, :overall, :grade_point)
  ScholasticExam = Struct.new(:exam_id, :fa, :exam_group_id,:fa_group_ids, :sa, :overall,:fa_names)
  CoScholasticReport = Struct.new(:observation_group_id, :observations, :sort_order)
  CoScholasticObservation = Struct.new(:observation_id, :grade, :observation_name, :sort_order)

  def self.included(base)
    base.instance_eval do
      unloadable
      attr_accessor_with_default(:batch_in_context_id) {batch_id}
      include InstanceMethods
    end
  end

  module InstanceMethods

    #    def after_initialize
    #      begin
    #        self.batch_in_context_id = batch_id
    #      rescue ActiveRecord::MissingAttributeError
    #
    #      end
    #
    #    end

    def batch_in_context
      @batch_in_context = Batch.find_by_id(batch_in_context_id)
    end

    def batch_in_context=(arg)
      if arg.class == Batch || arg == nil
        @batch_in_context = arg
        @batch_in_context_id = (arg ? arg.id : nil)
      else
        raise "type miss match, should be batch object"
      end
      @batch_in_context
    end


    def individual_cce_report
      get_exam_group_ids
      cr = MasterCceReport.new(:student_id=>id)
      sch_report = make_scholastic_report
      puts sch_report.inspect
      puts "**********************************************"
      cr.coscholastic = make_coscholastic_report
      puts cr.coscholastic
      cr.scholastic = sch_report[:scholastic]
      cr.exam_ids = sch_report[:exam_ids]
      cr.exam_group_ids = sch_report[:exam_group_ids]

      cr
    end

    def individual_cce_report_cached
      get_exam_group_ids
      Rails.cache.fetch(cce_report_cache_key){individual_cce_report}
    end

    def delete_individual_cce_report_cache
      Rails.cache.delete("cce_report/unpublished/batch/#{self.batch_in_context_id}/#{self.class.name}/#{self.id}")
      Rails.cache.delete("cce_report/batch/#{self.batch_in_context_id}/#{self.class.name}/#{self.id}")
    end

    def all_subjects
      (batch_in_context.subjects.all(:conditions=>{:elective_group_id=>nil})+elective_subjects).uniq
    end

    def elective_subjects
      subjects.all(:conditions=>{:batch_id=>batch_in_context_id,:is_deleted=>false})
    end

    def get_descriptive_indicators(observation_id)
      dis=Observation.find_by_id(observation_id).descriptive_indicators.all(:joins=>"LEFT OUTER JOIN assessment_scores ac on ac.descriptive_indicator_id=descriptive_indicators.id",:conditions=>["ac.student_id=? and descriptive_indicators.show_in_report=1",self.id],:order=>"ac.grade_points DESC")
      dis.collect(&:name).join(', ')
    end

    private

    def subject_fa_scores
      hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      fa_obtained_score_hash={}
      CceReport.scholastic.all(:select=>"cce_reports.*,exams.subject_id,fa_criterias.fa_group_id,fa_criterias.max_marks as max_marks,fa_groups.criteria_formula as c_formula,fa_criterias.formula_key as c_key",:joins=>[{:fa_criteria=>:fa_group},:exam], :conditions=>["exams.exam_group_id in (?) and batch_id=? and student_id=?", @valid_exam_group_ids, batch_in_context_id,self.id]).group_by(&:subject_id).each do |key,val|
        val.group_by(&:exam_id).each do |e_id,e_val|
          e_val.group_by(&:fa_group_id).each do |fag_id,fag_val|
            fa_formula=fag_val.collect(&:c_formula).uniq.first
            if fa_formula.present?
              fag_val.group_by(&:c_key).each do |indicator,mark|
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
              fag_val.group_by(&:c_key).each do |indicator,mark|
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
              fa_mark=(fa_obtained_mark/fa_max_mark)*100
              hsh[key.to_i][e_id][fag_id.to_i] = fa_mark
            else
              hsh[key.to_i][e_id]={}
              e_val.group_by(&:fa_group_id).each{|k,v| hsh[key.to_i][e_id][k.to_i] = (v.count > 0 ? (v.sum{|e| e.grade_string.to_f}/v.count): 0);}
            end
          end
        end
      end
      return hsh
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

    def make_scholastic_report
      @grades = batch_in_context.grading_level_list
      fg_ids = []
      exam_ids = []
      exam_group_ids = []
      sub_fa_scores = subject_fa_scores
      all_weightages = CceWeightage.all(:joins=>:courses, :conditions=>{:courses=>{:id=>batch_in_context.course_id}})
      sub_fa_scores.each{|k1,v1| v1.each{|k2, v2| fg_ids<<v2.keys}; exam_ids << v1.keys}
      examscores = exam_scores.all(:joins=>{:exam=>:exam_group},:conditions=>{:exam_id=>exam_ids.flatten.uniq,:exam_groups=>{:id=>@valid_exam_group_ids,:batch_id=>batch_in_context_id}}, :include=>{:exam=>:exam_group})
      fgs= FaGroup.find_all_by_id(fg_ids.flatten.uniq)
      exams=Exam.find_all_by_id(exam_ids.flatten.uniq)
      s_arr = []
      unless all_weightages.blank?
        sub_fa_scores.each do |subject_id,subval|
          max_fa = max_sa = max_overall = 0
          fa_count= sa_count=0
          sc = ScholasticReport.new(subject_id,[],0.0,0.0,0.0,'')
          subval.each do |exam_id,examval|
            se = ScholasticExam.new(exam_id, {}, nil, [],nil,nil,{})
            examval.each do |fg_id, score|
              se.fa_group_ids << fg_id
              fg = fgs.find{|f| f.id == fg_id}
              se.fa_names[fg.name.split.last]=fg.id
              unless fg.nil?
                se.fa[fg_id]= score
                #                se.fa[fg_id]= score * fg.max_marks/max_credit_point
              end
            end
            exam_group_id=exams.find_by_id(exam_id).exam_group_id
            exam_group_ids << exam_group_id
            se.exam_group_id = exam_group_id
            examscore = examscores.find{|e| e.exam_id == exam_id}
            if examscore and examscore.marks.present?
              se.sa = examscore.marks.to_f*100/examscore.exam.maximum_marks.to_f
              fa_weight = all_weightages.find{|w| w.cce_exam_category_id == (examscore.exam.exam_group.cce_exam_category_id || 1) and w.criteria_type=="FA"}
              sa_weight = all_weightages.find{|w| w.cce_exam_category_id == (examscore.exam.exam_group.cce_exam_category_id || 1) and w.criteria_type=="SA"}
              if fa_weight.nil? or sa_weight.nil?
                @error=true
              else
                se.overall = se.fa.values.sum{|v| v*fa_weight.weightage/100} + (se.sa*sa_weight.weightage/100 )
                sc.fa += se.fa.values.sum{|v| v*fa_weight.weightage/100}
                # overall marks calculations
                
                sc.sa += (se.sa*sa_weight.weightage/100 )
                max_sa += sa_weight.weightage
                sc.overall += se.overall
                max_overall += (fa_weight.weightage * 2) + sa_weight.weightage
                # converting to grade of each exam fa
                examval.each do |fg_id, score|
                  fa_count+=1
                  max_fa += fa_weight.weightage
                  se.fa[fg_id]= to_grade(se.fa[fg_id])
                end
                # converting to grade of sa and overall
                se.sa = to_grade(se.sa)
                if se.fa.count==2 and se.sa.present?
                  sa_count+=1
                  se.overall = to_grade(se.overall * 100/((fa_weight.weightage * 2) + sa_weight.weightage))
                else
                  se.overall=""
                end
              end

            else
              fa_weight = all_weightages.find{|w| w.cce_exam_category_id == (ExamGroup.find_by_id(exam_group_id).cce_exam_category_id || 1) and w.criteria_type=="FA"}
              if fa_weight.nil?
                @error=true
              else
                sc.fa += se.fa.values.sum{|v| v*fa_weight.weightage/100}
                examval.each do |fg_id, score|
                  fa_count+=1
                  max_fa+=fa_weight.weightage
                  se.fa[fg_id]= to_grade(se.fa[fg_id])
                end
              end
            end

            sc.exams << se

          end
          # converting to grade of over all marks
          if fa_count==4 and sa_count==2
            sc.fa = to_grade(sc.fa*100/max_fa)
            sc.grade_point = credit_point(sc.overall*100/max_overall)
            sc.overall = to_grade(sc.overall*100/max_overall)
            sc.sa = to_grade(sc.sa*100/max_sa)
          else
            sc.fa = ""
            sc.grade_point = ""
            sc.overall = ""
            sc.sa = ""
          end
        

          s_arr << sc
        end
      end
      if @error
        {:scholastic=>[],:exam_ids=>[], :exam_group_ids=>[]}
      else
        {:scholastic=>s_arr,:exam_ids=>exam_ids.flatten.uniq, :exam_group_ids=>exam_group_ids.uniq}
      end
    end

    def coscholastic_scores
      hsh=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      cce_reports.coscholastic.all(:select=>"cce_reports.*,observations.observation_group_id,observations.name AS o_name, observations.sort_order,observation_groups.sort_order as s_order",:joins=>'INNER JOIN observations ON cce_reports.observable_id = observations.id INNER JOIN observation_groups on observation_groups.id=observations.observation_group_id', :conditions=>["batch_id=?", batch_in_context_id], :order=>"observations.sort_order ASC").group_by(&:observation_group_id).each do |key,val|
        hsh[key.to_i][:s_order]= val.first[:s_order]
        val.group_by(&:observable_id).each do |k,v|
          hsh[key.to_i][:observations][k][:grade] = v.find{|r| r.grade_string}.try(:grade_string)
          hsh[key.to_i][:observations][k][:observation_name] = v.find{|r| r.grade_string}.try(:o_name)
          hsh[key.to_i][:observations][k][:sort_order] = v.find{|r| r.grade_string}.try(:sort_order)
        end
        
      end
      hsh
    end

    def make_coscholastic_report
      c_arr = []
      coscholastic_scores.each do |obs_grp_id,observations|
        cs = CoScholasticReport.new(obs_grp_id, [],observations[:s_order])
        observations[:observations].each do |obs_id, obs_v|
          co = CoScholasticObservation.new(obs_id,obs_v[:grade],obs_v[:observation_name],obs_v[:sort_order].to_i)
          cs.observations << co
        end
        c_arr << cs
      end
      c_arr
    end

    def to_grade(score)
      if /^[\d]+(\.[\d]+){0,1}$/ === score.to_s
        @grades.to_a.find{|g| g.min_score <= score.to_f.round(2).round}.try(:name) || ""
      end
    end

    def credit_point(score)
      if /^[\d]+(\.[\d]+){0,1}$/ === score.to_s
        @grades.to_a.find{|g| g.min_score <= score.to_f.round(2).round}.try(:credit_points) || ""
      end
    end

    def get_exam_group_ids
      @all_exam_groups ||= ExamGroup.all(:select=>'id, result_published',:conditions=>['cce_exam_category_id is not null and batch_id = ?',batch_in_context_id])
      @unpublished_exam_group_ids ||= @all_exam_groups.collect{|eg| eg.id if !eg.result_published}.compact
      @valid_exam_group_ids =  if (Authorization.current_user.has_required_batches? or (Authorization.current_user.try(:role_symbols)||[]) & [:admin, :examination_control,:enter_results,:view_results]).present? && @unpublished_exam_group_ids.present?
        @all_exam_groups.collect(&:id)
      else
        @all_exam_groups.collect(&:id) - @unpublished_exam_group_ids
      end
    end

    def cce_report_cache_key
      if ((Authorization.current_user.try(:role_symbols)||[]) & [:admin, :examination_control,:enter_results,:view_results]).present? && @unpublished_exam_group_ids.present?
        "cce_report/unpublished/batch/#{self.batch_in_context_id}/#{self.class.name}/#{self.id}"
      else
        "cce_report/batch/#{self.batch_in_context_id}/#{self.class.name}/#{self.id}"
      end
    end
    
  end

end

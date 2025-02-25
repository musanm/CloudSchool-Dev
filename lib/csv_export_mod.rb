module CsvExportMod

  def self.included(base)
    base.instance_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    def student_advanced_search(params)      
      params = params[:params] if params.key?(:params)
      data_hash ||= Hash.new
      data_hash[:method] = "student_advanced_search"
      search = Student.search(params[:search])
      unless params[:search]
        batches = Batch.all
      else
        if params[:search].present?
          students = Array.new
          if params[:advv_search].present? and params[:advv_search][:course_id].present?
            unless params[:search][:batch_id_equals].present?
              params[:search][:batch_id_in] = Batch.find_all_by_course_id(params[:advv_search][:course_id]).collect{|b|b.id}
            end
          end
          if params[:search][:is_active_equals]=="true"
            students = Student.ascend_by_first_name.search(params[:search])
          elsif params[:search][:is_active_equals]=="false"
            students = ArchivedStudent.ascend_by_first_name.search(params[:search])
          else
            students1 = Student.ascend_by_first_name.search(params[:search]).all
            students2 = ArchivedStudent.ascend_by_first_name.search(params[:search]).all
            students = students1 + students2
          end
          data_hash[:students] = students
          searched_for = ''
          searched_for += "#{t('name')}: " + params[:search][:first_name_or_middle_name_or_last_name_like].to_s if params[:search][:first_name_or_middle_name_or_last_name_like].present?
          searched_for += "#{t('admission_no')}: " + params[:search][:admission_no_equals].to_s if params[:search][:admission_no_equals].present?
          if params[:advv_search] and params[:advv_search][:course_id].present?
            course = Course.find(params[:advv_search][:course_id])
            batch = Batch.find(params[:search][:batch_id_equals]) unless (params[:search][:batch_id_equals]).blank?
            searched_for += "#{t('course_text')}: " + course.full_name
            searched_for += "#{t('batch')}: " + batch.full_name unless batch.nil?
          end
          searched_for += "#{t('category')}: " + StudentCategory.find(params[:search][:student_category_id_equals]).name.to_s if params[:search][:student_category_id_equals].present?
          if  params[:search][:gender_equals].present?
            if  params[:search][:gender_equals] == 'm'
              searched_for += "#{t('gender')}: #{t('male')}"
            elsif  params[:search][:gender_equals] == 'f'
              searched_for += " #{t('gender')}: #{t('female')}"
            else
              searched_for += " #{t('gender')}: #{t('all')}"
            end
          end
          searched_for += "#{t('blood_group')}: " + params[:search][:blood_group_like].to_s if params[:search][:blood_group_like].present?
          searched_for += "#{t('nationality')}: " + Country.find(params[:search][:nationality_id_equals]).name.to_s if params[:search][:nationality_id_equals].present?
          searched_for += "#{t('year_of_admission')}: " +  params[:advv_search][:doa_option].to_s + ' '+ params[:adv_search][:admission_date_year].to_s if params[:advv_search].present? and  params[:advv_search][:doa_option].present?
          searched_for += "#{t('year_of_birth')}: " +  params[:advv_search][:dob_option].to_s + ' ' + params[:adv_search][:birth_date_year].to_s if params[:advv_search].present? and  params[:advv_search][:dob_option].present?
          if params[:search][:is_active_equals]=="true"
            searched_for += " #{t('present_student')} "
          elsif params[:search][:is_active_equals]=="false"
            searched_for += " #{t('former_student')} "
          else
            searched_for += " #{t('all_students')} "
          end
        end
      end
      data_hash[:parameters] = params
      data_hash[:searched_for] = searched_for
      find_report_type(data_hash)
    end

    def timetable_data_csv(data_hash)
      data ||= Array.new
      tt=Timetable.find(data_hash[:parameters][:tt_id])
      batch = Batch.find(data_hash[:parameters][:batch_id])
      data << "#{t('timetable_text')} #{format_date(tt.start_date)} - #{format_date(tt.end_date)} #{t('for').downcase} #{batch.full_name}"
      data << ""
      time_table_class_timings = TimeTableClassTiming.find_by_timetable_id_and_batch_id(tt.id,batch.id)
      class_timing_sets = time_table_class_timings.nil? ? batch.batch_class_timing_sets(:joins=>{:class_timing_set=>:class_timing}) : time_table_class_timings.time_table_class_timing_sets(:joins=>{:class_timing_set=>:class_timings})
      if tt.duration >= 7
        weekday = weekday_arrangers(time_table_class_timings.time_table_class_timing_sets.collect(&:weekday_id))
      else
        weekdays=[]
        (tt.start_date..tt.end_date).each {|day| weekdays << day.wday if time_table_class_timings.time_table_class_timing_sets.collect(&:weekday_id).include?(day.wday)}
        weekday = weekday_arrangers(weekdays)
      end
      timetable_entries=TimetableEntry.find(:all,:conditions=>{:batch_id=>batch.id,:timetable_id=>tt.id},:include=>[{:subject=>:subject_leaves},:employee,:timetable_swaps])
      timetable= Hash.new { |h, k| h[k] = Hash.new(&h.default_proc)}
      timetable_entries.each do |tte|
        timetable[tte.weekday_id][tte.class_timing_id]=tte
      end
      unless weekday.blank?
        weekday.each do |week|
          col1=[""]
          col3=[""]
          col2 = ["#{WeekdaySet.weekday_name(week.to_s).titleize}"]
          class_timings=class_timing_sets.find_by_weekday_id(week).class_timing_set.class_timings
          if class_timings.present?
            class_timings.each do |ct|
              tte = timetable[week][ct.id]
              if (tte.is_a? TimetableEntry and !ct.is_break?)
                col1 << "#{format_date(ct.start_time,:format=>:time)}-#{format_date(ct.end_time,:format=>:time)}"
                unless tte.subject.nil?
                  unless tte.subject.elective_group_id.nil?
                    col2<< tte.subject.elective_group.name.to_s
                  else
                    col2<< tte.subject.code.to_s
                  end
                end
                unless tte.subject.nil?
                  unless tte.subject.elective_group_id.nil?
                    col3<< t('elective')
                  else
                    if tte.employee.present?
                      col3<<  tte.employee.first_name
                    else
                      col3<< t('no_teacher')
                    end
                  end
                end
              else
                col1 <<  "#{format_date(ct.start_time,:format=>:time)}-#{format_date(ct.end_time,:format=>:time)}"
                col2 <<  ""
                col3 <<  ""
              end
            end
          else
            col1 <<  "#{format_date(ct.start_time,:format=>:time)}-#{format_date(ct.end_time,:format=>:time)}"
            col2 <<  ""
            col3 <<  ""
          end
          data << col1
          data << col2
          data << col3
        end
      end
      
      return data
    end

    def student_attendance_report(params)
      config = Configuration.find_by_config_key('StudentAttendanceType')
      batch = Batch.find(params[:batch])
      students = batch.students.by_first_name
      start_date = params[:start_date].to_date
      end_date = params[:end_date].to_date
      params.has_key?("range") ? range = params[:range] : range = ""
      params.has_key?("value") ? value = params[:value] : value = ""
      leaves=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      mode=params[:report_type]
      working_days=batch.working_days(start_date.to_date)
      unless config.config_value == 'Daily'
        if mode == 'Overall'
          unless params[:subject] == '0'
            subject = Subject.find params[:subject]
            unless subject.elective_group_id.nil?
              students = subject.students.by_first_name
            end
            academic_days=batch.subject_hours(start_date, end_date, params[:subject].to_i).values.flatten.compact.count
            grouped = subject.subject_leaves.find(:all, :conditions =>{:month_date => start_date..end_date}).group_by(&:student_id)
            students.each do |s|
              if grouped[s.id].nil?
                leaves[s.id]['leave']=0
              else
                leaves[s.id]['leave']=grouped[s.id].count
              end
              leaves[s.id]['total'] = (academic_days - leaves[s.id]['leave'])
              leaves[s.id]['percent'] = (leaves[s.id]['total'].to_f/academic_days)*100 unless academic_days == 0
            end
          else
            academic_days=batch.subject_hours(start_date, end_date, 0).values.flatten.compact.count
            grouped = batch.subject_leaves.find(:all,  :conditions =>{:month_date => start_date..end_date}).group_by(&:student_id)
            students.each do |s|
              if grouped[s.id].nil?
                leaves[s.id]['leave']=0
              else
                leaves[s.id]['leave']=grouped[s.id].count
              end
              leaves[s.id]['total'] = (academic_days - leaves[s.id]['leave'])
              leaves[s.id]['percent'] = (leaves[s.id]['total'].to_f/academic_days)*100 unless academic_days == 0
            end
          end
        else
          unless params[:subject] == '0'
            subject = Subject.find params[:subject]
            unless subject.elective_group_id.nil?
              students = subject.students.by_first_name
            end
            academic_days=batch.subject_hours(start_date, end_date, params[:subject].to_i).values.flatten.compact.count
            grouped = SubjectLeave.find_all_by_subject_id(subject.id,  :conditions =>{:batch_id=>batch.id,:month_date => start_date..end_date}).group_by(&:student_id)
            batch.students.by_first_name.each do |s|
              if grouped[s.id].nil?
                leaves[s.id]['leave']=0
              else
                leaves[s.id]['leave']=grouped[s.id].count
              end
              leaves[s.id]['total'] = (academic_days - leaves[s.id]['leave'])
              leaves[s.id]['percent'] = (leaves[s.id]['total'].to_f/academic_days)*100 unless academic_days == 0
            end
          else
            academic_days=batch.subject_hours(start_date, end_date, 0).values.flatten.compact.count
            grouped = batch.subject_leaves.find(:all,  :conditions =>{:month_date => start_date..end_date}).group_by(&:student_id)
            batch.students.by_first_name.each do |s|
              if grouped[s.id].nil?
                leaves[s.id]['leave']=0
              else
                leaves[s.id]['leave']=grouped[s.id].count
              end
              leaves[s.id]['total'] = (academic_days - leaves[s.id]['leave'])
              leaves[s.id]['percent'] = (leaves[s.id]['total'].to_f/academic_days)*100 unless academic_days == 0
            end
          end
        end
      else
        if mode=='Overall'
          academic_days=batch.academic_days.count
        else
          working_days=batch.working_days(start_date.to_date)
          academic_days=  working_days.select{|v| v<=end_date}.count
        end
        students = batch.students.by_first_name
        leaves_forenoon=Attendance.count(:all,:conditions=>{:batch_id=>batch.id,:forenoon=>true,:afternoon=>false,:month_date => start_date..end_date},:group=>:student_id)
        leaves_afternoon=Attendance.count(:all,:conditions=>{:batch_id=>batch.id,:forenoon=>false,:afternoon=>true,:month_date => start_date..end_date},:group=>:student_id)
        leaves_full=Attendance.count(:all,:conditions=>{:batch_id=>batch.id,:forenoon=>true,:afternoon=>true,:month_date => start_date..end_date},:group=>:student_id)
        students.each do |student|
          leaves[student.id]['total']=academic_days-leaves_full[student.id].to_f-(0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
          leaves[student.id]['percent'] = (leaves[student.id]['total'].to_f/academic_days)*100 unless academic_days == 0
        end
      end
      data_hash = {:leaves => leaves, :students => students,:academic_days => academic_days,:parameters => params, :method => "student_attendance_report",:config => config,:course => batch.course.full_name,:batch => batch.full_name,:subject => subject, :range => range, :value => value}
      find_report_type(data_hash)
    end

    def day_wise_report(params)
      cur_user = Authorization.current_user
      if cur_user.admin? or (cur_user.employee? and cur_user.privileges.map{|p| p.name}.include?('StudentAttendanceView'))
        if params[:course_id].present?
          @batches =  Batch.all(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
            :order => "courses.course_name,batches.id",
            :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{params[:date]}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id",
            :include => :course,:conditions => ["'#{params[:date]}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batches.course_id = #{params[:course_id]}"],
            :group => "batches.id")
        else
          @batches =  Batch.all(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
            :order => "courses.course_name,batches.id",:joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{params[:date]}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id",
            :include => :course,:conditions => ["'#{params[:date]}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0"],
            :group => "batches.id")
        end
      else
        if params[:course_id].present?
          @batches = Batch.all(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
            :order => "courses.course_name,batches.id",
            :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{params[:date]}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id LEFT OUTER JOIN batch_tutors ON batches.id = batch_tutors.batch_id",
            :include => :course,:conditions => ["'#{params[:date]}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batch_tutors.employee_id = #{cur_user.employee_record.id} AND batches.course_id = #{params[:course_id]}"],
            :group => "batches.id")
        else
          @batches = Batch.all(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
            :order => "courses.course_name,batches.id",
            :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{params[:date]}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id LEFT OUTER JOIN batch_tutors ON batches.id = batch_tutors.batch_id",
            :include => :course,:conditions => ["'#{params[:date]}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batch_tutors.employee_id = #{cur_user.employee_record.id}"],
            :group => "batches.id")
        end
      end
      data_hash = {:date => params[:date],:method => "day_wise_report",:parameters => params}
      data_hash[:leave_count] =  Attendance.all(:joins => ["INNER JOIN batches ON batches.id = attendances.batch_id INNER JOIN students ON attendances.student_id = students.id AND students.batch_id = batches.id"],
        :conditions=>{:month_date => "#{params[:date]}",:'batches.is_deleted' => false,:'batches.is_active' => true}).count
      data_hash[:students_count] = Student.active.count
      data_hash[:report] = @batches.to_a.group_by{|b| b.course_name}
      find_report_type(data_hash)
    end

    def student_ranking_per_subject(params)
      data_hash ||= Hash.new
      data_hash[:method] = "student_ranking_per_subject"
      data_hash[:parameters] = params
      subject = Subject.find(params[:subject_id])
      data_hash[:subject] = subject
      batch = subject.batch
      data_hash[:batch_name] = batch.name
      data_hash[:course] = batch.course.full_name
      students = batch.students.by_first_name
      data_hash[:students] = students
      unless subject.elective_group_id.nil?
        students.reject!{|s| !StudentsSubject.exists?(:student_id=>s.id,:subject_id=>subject.id)}
      end
      exam_groups = ExamGroup.find(:all,:conditions=>{:batch_id=>batch.id}, :include => [:exams => :exam_scores])
      data_hash[:exam_groups] = exam_groups
      exam_groups.reject!{|e| e.exam_type=="Grades"}
      ranks = []
      exam_groups.each do |exam_group|
        rank_exam = exam_group.exams.select {|x| x.subject_id == subject.id and x.exam_group_id == exam_group.id}
        unless rank_exam.empty?
          exam_scores = rank_exam[0].exam_scores.select {|x| x.exam_id == rank_exam[0].id}
          ordered_marks = exam_scores.map{|m| m.marks}.compact.uniq.sort.reverse
          ranks << [exam_group.id,ordered_marks]
        end
      end
      data_hash[:ranks] = ranks
      find_report_type(data_hash)
    end

    def timetable_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "timetable_data"
      data_hash[:parameters] = params
      find_report_type(data_hash)
    end

    def student_ranking_per_batch(params)
      data_hash ||= Hash.new
      data_hash[:method] = "student_ranking_per_batch"
      batch = Batch.find(params[:batch_id], :include => [:students])
      data_hash[:batch] = batch.name
      data_hash[:course] = batch.course.full_name
      students = batch.students
      grouped_exams = GroupedExam.find_all_by_batch_id(batch.id)
      ranked_students = batch.find_batch_rank
      data_hash[:parameters] = params
      data_hash[:ranked_students] = ranked_students
      find_report_type(data_hash)
    end

    def student_ranking_per_course(params)
      data_hash ||= Hash.new
      data_hash[:method] = "student_ranking_per_course"
      course = Course.find(params[:course_id])
      data_hash[:course] = course
      if course.has_batch_groups_with_active_batches
        batch_group = BatchGroup.find(params[:batch_group_id])
        data_hash[:batch_group] = batch_group
        batches = batch_group.batches
      else
        batches = course.active_batches
      end
      students = Student.find_all_by_batch_id(batches)
      grouped_exams = GroupedExam.find_all_by_batch_id(batches)
      sort_order=""
      unless !params[:sort_order].present?
        sort_order=params[:sort_order]
      end
      ranked_students = course.find_course_rank(batches.collect(&:id),sort_order)
      data_hash[:ranked_students] =ranked_students
      data_hash[:parameters] = params
      data_hash[:sort_order] = sort_order
      find_report_type(data_hash)
    end

    def student_ranking_per_school(params)
      params = params[:params] if params.key?(:params)
      data_hash ||= Hash.new
      data_hash[:method] = "student_ranking_per_school"
      courses = Course.all(:conditions=>{:is_deleted=>false})
      batches = Batch.all(:conditions=>{:course_id=>courses,:is_deleted=>false,:is_active=>true})
      students = Student.find_all_by_batch_id(batches)
      grouped_exams = GroupedExam.find_all_by_batch_id(batches)
      sort_order = ""
      unless !params[:sort_order].present?
        sort_order=params[:sort_order]
      end
      data_hash[:sort_order] = sort_order
      unless courses.empty?
        ranked_students = courses.first.find_course_rank(batches.collect(&:id),sort_order)
      else
        ranked_students = []
      end
      data_hash[:ranked_students] = ranked_students
      data_hash[:parameters] = params
      find_report_type(data_hash)
    end

    def student_ranking_per_attendance(params)
      batch = Batch.find(params[:batch_id])
      students = Student.find_all_by_batch_id(batch.id)
      start_date = params[:start_date].to_date
      end_date = params[:end_date].to_date
      ranked_students = batch.find_attendance_rank(start_date,end_date)
      data_hash = {:method => "student_ranking_per_attendance", :batch => batch, :students => students, :start_date => start_date, :end_date => end_date, :ranked_students => ranked_students, :parameters => params}
      find_report_type(data_hash)
    end

    def employee_advance_search(params)
      params = params[:params] if params.key?(:params)
      employee_ids = params[:result]
      searched_for = params[:for]
      status = params[:status]
      employees = []
      if params[:status] == 'true'
        search = Employee.ascend_by_first_name.search(params[:search])
        employees += search.all
      elsif params[:status] == 'false'
        search = ArchivedEmployee.ascend_by_first_name.search(params[:search])
        employees += search.all
      else
        search1 = Employee.ascend_by_first_name.search(params[:search]).all
        search2 = ArchivedEmployee.ascend_by_first_name.search(params[:search]).all
        employees+=search1+search2
      end
      data_hash = {:method => "employee_advance_search", :parameters => params, :searched_for => searched_for, :employees => employees}
      find_report_type(data_hash)
    end

    def employee_attendance_data(params)
      params = params[:params] if params.key?(:params)
      leave_types = EmployeeLeaveType.find(:all, :conditions => "status = true", :order => "name ASC")
      employee_leave = EmployeeLeave.all
      unless (params[:department]== "All Departments")
        employees = Employee.find_all_by_employee_department_id(params[:department])
        department = EmployeeDepartment.find_by_id(params[:department])
        department_name=department.name if department.present?
      else
        employees = Employee.all
        department_name = t('all_departments')
      end
      data_hash = {:method => "employee_attendance_data", :parameters => params, :employees => employees, :leave_types => leave_types, :department_name => department_name}
      find_report_type(data_hash)
    end

    def subject_wise_data(params)
      subject = Subject.find(params[:subject_id])
      batch = subject.batch
      students = batch.students
      exam_groups = ExamGroup.find(:all,:conditions=>{:batch_id=>batch.id})
      data_hash = {:method => "subject_wise_data",:parameters => params,:subject => subject,:batch => batch,:exam_groups => exam_groups,:students => students}
      find_report_type(data_hash)
    end

    def consolidated_exam_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "consolidated_exam_data"
      exam_group = ExamGroup.find(params[:exam_group], :include => :exams)
      data_hash[:exam_group] = exam_group
      data_hash[:exams] = exam_group.exams
      batch = exam_group.batch
      data_hash[:batch] = batch
      if batch.gpa_enabled?
        data_hash[:grade_type] = "GPA"
      elsif batch.cwa_enabled?
        data_hash[:grade_type] = "CWA"
      else
        data_hash[:grade_type] = "normal"
      end
      data_hash[:parameters] = params
      find_report_type(data_hash)
    end

    def ranking_level(params)
      data_hash ||= Hash.new
      data_hash[:method] = "ranking_level"
      data_hash[:parameters] = params
      ranking_level = RankingLevel.find(params[:ranking_level_id])
      mode = params[:mode]
      if mode=="batch"
        batch = Batch.find(params[:batch_id])
        report_type = params[:report_type]
        if report_type=="subject"
          students = batch.students(:conditions=>{:is_active=>true,:is_deleted=>true})
          subject = Subject.find(params[:subject_id])
          scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>students.collect(&:id),:batch_id=>batch.id,:subject_id=>subject.id,:score_type=>"s"})
          if batch.gpa_enabled?
            scores.reject!{|s| !((s.marks < ranking_level.gpa if ranking_level.marks_limit_type=="upper") or (s.marks >= ranking_level.gpa if ranking_level.marks_limit_type=="lower") or (s.marks == ranking_level.gpa if ranking_level.marks_limit_type=="exact"))}
          else
            scores.reject!{|s| !((s.marks < ranking_level.marks if ranking_level.marks_limit_type=="upper") or (s.marks >= ranking_level.marks if ranking_level.marks_limit_type=="lower") or (s.marks == ranking_level.marks if ranking_level.marks_limit_type=="exact"))}
          end
        else
          students = batch.students(:conditions=>{:is_active=>true,:is_deleted=>true})
          unless ranking_level.subject_count.nil?
            unless ranking_level.full_course==true
              subjects = batch.subjects
              scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>students.collect(&:id),:batch_id=>batch.id,:subject_id=>subjects.collect(&:id),:score_type=>"s"})
            else
              scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>students.collect(&:id),:score_type=>"s"})
            end
            if batch.gpa_enabled?
              scores.reject!{|s| !((s.marks < ranking_level.gpa if ranking_level.marks_limit_type=="upper") or (s.marks >= ranking_level.gpa if ranking_level.marks_limit_type=="lower") or (s.marks == ranking_level.gpa if ranking_level.marks_limit_type=="exact"))}
            else
              scores.reject!{|s| !((s.marks < ranking_level.marks if ranking_level.marks_limit_type=="upper") or (s.marks >= ranking_level.marks if ranking_level.marks_limit_type=="lower") or (s.marks == ranking_level.marks if ranking_level.marks_limit_type=="exact"))}
            end
          else
            unless ranking_level.full_course==true
              scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>students.collect(&:id),:batch_id=>batch.id,:score_type=>"c"})
            else
              scores = []
              students.each do|student|
                total_student_score = 0
                avg_student_score = 0
                marks = GroupedExamReport.find_all_by_student_id_and_score_type(student.id,"c")
                unless marks.empty?
                  marks.map{|m| total_student_score+=m.marks}
                  avg_student_score = total_student_score.to_f/marks.count.to_f
                  marks.first.marks = avg_student_score
                  scores.push marks.first
                end
              end
            end
            if batch.gpa_enabled?
              scores.reject!{|s| !((s.marks < ranking_level.gpa if ranking_level.marks_limit_type=="upper") or (s.marks >= ranking_level.gpa if ranking_level.marks_limit_type=="lower") or (s.marks == ranking_level.gpa if ranking_level.marks_limit_type=="exact"))}
            else
              scores.reject!{|s| !((s.marks < ranking_level.marks if ranking_level.marks_limit_type=="upper") or (s.marks >= ranking_level.marks if ranking_level.marks_limit_type=="lower") or (s.marks == ranking_level.marks if ranking_level.marks_limit_type=="exact"))}
            end
          end
        end
      else
        course = Course.find(params[:course_id])
        if course.has_batch_groups_with_active_batches
          batch_group = BatchGroup.find(params[:batch_group_id])
          batches = batch_group.batches
        else
          batches = course.active_batches
        end
        students = Student.find_all_by_batch_id(batches.collect(&:id))
        unless ranking_level.subject_count.nil?
          scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>students.collect(&:id),:score_type=>"s"})
        else
          unless ranking_level.full_course==true
            scores = GroupedExamReport.find(:all,:conditions=>{:student_id=>students.collect(&:id),:score_type=>"c"})
          else
            scores = []
            students.each do|student|
              total_student_score = 0
              avg_student_score = 0
              marks = GroupedExamReport.find_all_by_student_id_and_score_type(student.id,"c")
              unless marks.empty?
                marks.map{|m| total_student_score+=m.marks}
                avg_student_score = total_student_score.to_f/marks.count.to_f
                marks.first.marks = avg_student_score
                scores.push marks.first
              end
            end
          end
        end
        if ranking_level.marks_limit_type=="upper"
          scores.reject!{|s| !(((s.marks < ranking_level.gpa unless ranking_level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks < ranking_level.marks unless ranking_level.marks.nil?))}
        elsif ranking_level.marks_limit_type=="exact"
          scores.reject!{|s| !(((s.marks == ranking_level.gpa unless ranking_level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks == ranking_level.marks unless ranking_level.marks.nil?))}
        else
          scores.reject!{|s| !(((s.marks >= ranking_level.gpa unless ranking_level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks >= ranking_level.marks unless ranking_level.marks.nil?))}
        end
      end
      if mode=="batch"
        unless scores.empty?
          if report_type=="subject"
            ranked_students = Student.find_all_by_id(scores.collect(&:student_id))
            ranked_students = ranked_students.reject{|st| st.has_higher_priority_ranking_level(ranking_level.id,"subject",subject.id)==true}
          else
            unless ranking_level.subject_count.nil?
              sub_count = ranking_level.subject_count
              ranked_students = []
              students.each do|student|
                student_scores = scores.dup
                student_scores.reject!{|s| !(s.student_id==student.id)}
                if ranking_level.subject_limit_type=="upper"
                  if student_scores.count < sub_count
                    ranked_students << student
                  end
                elsif ranking_level.subject_limit_type=="exact"
                  if student_scores.count == sub_count
                    ranked_students << student
                  end
                else
                  if student_scores.count >= sub_count
                    ranked_students << student
                  end
                end
              end
            else
              ranked_students = Student.find_all_by_id(scores.collect(&:student_id))
            end
            ranked_students = ranked_students.reject{|st| st.has_higher_priority_ranking_level(ranking_level.id,"overall","")==true}
          end
          data_hash[:ranked_students] = ranked_students
          data_hash[:ranking_level] = ranking_level
          find_report_type(data_hash)
        end
      else
        unless scores.empty?
          unless ranking_level.subject_count.nil?
            sub_count = ranking_level.subject_count
            ranked_students = []
            unless ranking_level.full_course==true
              students.each do|student|
                student_scores = scores.dup
                student_scores.reject!{|s| !(s.student_id==student.id)}
                batch_ids = student_scores.collect(&:batch_id)
                batch_ids.each do|batch_id|
                  unless batch_ids.empty?
                    count = batch_ids.count(batch_id)
                    if ranking_level.subject_limit_type=="upper"
                      if count < sub_count
                        unless student.has_higher_priority_ranking_level(ranking_level.id,"course","")
                          ranked_students << [student.id,batch_id]
                        end
                      end
                    elsif ranking_level.subject_limit_type=="exact"
                      if count == sub_count
                        unless student.has_higher_priority_ranking_level(ranking_level.id,"course","")
                          ranked_students << [student.id,batch_id]
                        end
                      end
                    else
                      if count >= sub_count
                        unless student.has_higher_priority_ranking_level(ranking_level.id,"course","")
                          ranked_students << [student.id,batch_id]
                        end
                      end
                    end
                    batch_ids.delete(batch_id)
                  end
                end
              end
            else
              students.each do|student|
                student_scores = scores.dup
                student_scores.reject!{|s| !(s.student_id==student.id)}
                if ranking_level.subject_limit_type=="upper"
                  if student_scores.count < sub_count
                    unless student.has_higher_priority_ranking_level(ranking_level.id,"course","")
                      ranked_students << [student.id,student.batch.id]
                    end
                  end
                elsif ranking_level.subject_limit_type=="exact"
                  if student_scores.count == sub_count
                    unless student.has_higher_priority_ranking_level(ranking_level.id,"course","")
                      ranked_students << [student.id,student.batch.id]
                    end
                  end
                else
                  if student_scores.count >= sub_count
                    unless student.has_higher_priority_ranking_level(ranking_level.id,"course","")
                      ranked_students << [student.id,student.batch.id]
                    end
                  end
                end
              end
            end
          else
            ranked_students = []
            scores.each do|score|
              unless score.student.has_higher_priority_ranking_level(ranking_level.id,"course","")
                ranked_students << [score.student_id,score.batch_id]
              end
            end
          end
          data_hash[:ranked_students] = ranked_students
          data_hash[:ranking_level] = ranking_level
          find_report_type(data_hash)
        end
      end
    end

    def finance_payslip_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "finance_payslip_data"
      data_hash[:parameters] = params
      if params[:department_id] == "All"
        department = EmployeeDepartment.ordered
        employees = Employee.find(:all)
        data_hash[:department_name] = t('all_departments')
      else
        department = EmployeeDepartment.find(params[:department_id])
        employees = Employee.find_all_by_employee_department_id(department.id)
        data_hash[:department_name] = department.name
      end
      data_hash[:salary_month] = Date.parse(params[:salary_date]).strftime("%B %Y")
      if params[:salary_date].present? and params[:department_id].present?
        payslips = MonthlyPayslip.find_and_filter_by_department(params[:salary_date],params[:department_id])
        data_hash[:payslips] = payslips
      end
      currency_type = Configuration.find_by_config_key("CurrencyType").config_value
      salary_date = params[:salary_date] if params[:salary_date]
      if payslips[:monthly_payslips].present? or payslips[:individual_payslip_category].present?
        grouped_monthly_payslips = payslips[:monthly_payslips] unless payslips[:monthly_payslips].blank?
        data_hash[:grouped_monthly_payslips] = grouped_monthly_payslips
        grouped_individual_payslip_categories = payslips[:individual_payslip_category] unless payslips[:individual_payslip_category].blank?
        data_hash[:grouped_individual_payslip_categories]  = grouped_individual_payslip_categories
        find_report_type(data_hash)
      end
    end


    def finance_transaction_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "finance_transaction_data"
      data_hash[:parameters] = params
      cat_names = ['Fee','Salary','Donation']
      plugin_cat = []
      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        cat_names << "#{category[:category_name]}"
        plugin_cat << "#{category[:category_name]}"
      end
      fixed_cat_ids = FinanceTransactionCategory.find(:all,:conditions=>{:name=>cat_names}).collect(&:id)
      hr = Configuration.find_by_config_value("HR")
      data_hash[:hr] = hr
      start_date = (params[:start_date]).to_date
      data_hash[:start_date] = start_date
      end_date = (params[:end_date]).to_date
      data_hash[:end_date] = end_date
      transactions = FinanceTransaction.find(:all,
        :order => 'transaction_date desc', :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'"])
      other_transaction_categories = FinanceTransactionCategory.find(:all, :conditions => ["finance_transactions.transaction_date >= '#{start_date}' and finance_transactions.transaction_date <= '#{end_date}'and finance_transaction_categories.id NOT IN (#{fixed_cat_ids.join(",")})"],:joins=>[:finance_transactions]).uniq
      data_hash[:other_transaction_categories] = other_transaction_categories
      transactions_fees = FinanceTransaction.total_fees(start_date,end_date).map{|t| t.transaction_total.to_f}.sum
      data_hash[:transactions_fees] = transactions_fees
      salary = FinanceTransaction.sum('amount',:conditions=>{:title=>"Monthly Salary",:transaction_date=>start_date..end_date}).to_f
      data_hash[:salary] = salary
      donations_total = FinanceTransaction.donations_triggers(start_date,end_date)
      data_hash[:donations_total] = donations_total
      grand_total = FinanceTransaction.grand_total(start_date,end_date)
      data_hash[:grand_total] = grand_total
      category_transaction_totals = {}
      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        category_transaction_totals["#{category[:category_name]}"] =   FinanceTransaction.total_transaction_amount(category[:category_name],start_date,end_date)
      end
      data_hash[:category_transaction_totals] = category_transaction_totals
      find_report_type(data_hash)
    end

    def employee_payslip_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "employee_payslip_data"
      data_hash[:parameters] = params
      if params[:department_id] == "All"
        department = EmployeeDepartment.ordered
        employees = Employee.find(:all)
        data_hash[:department_name] = t('all_departments')
      else
        department = EmployeeDepartment.find(params[:department_id])
        employees = Employee.find_all_by_employee_department_id(department.id)
        data_hash[:department_name] = department.name
      end
      data_hash[:salary_month] = Date.parse(params[:salary_date]).strftime("%B %Y")
      if params[:salary_date].present? and params[:department_id].present?
        payslips = MonthlyPayslip.find_and_filter_by_department(params[:salary_date],params[:department_id])
      end
      currency_type = Configuration.find_by_config_key("CurrencyType").config_value
      salary_date = params[:salary_date] if params[:salary_date]
      if payslips[:monthly_payslips].present? or payslips[:individual_payslip_category].present?
        grouped_monthly_payslips = payslips[:monthly_payslips] unless payslips[:monthly_payslips].blank?
        data_hash[:grouped_monthly_payslips] = grouped_monthly_payslips
        grouped_individual_payslip_categories = payslips[:individual_payslip_category] unless payslips[:individual_payslip_category].blank?
        data_hash[:grouped_individual_payslip_categories]  = grouped_individual_payslip_categories
        find_report_type(data_hash)
      end
    end

    def student_wise_report(params)
      data_hash ||= Hash.new
      data_hash[:method] = "student_wise_report"
      student= (params[:type]=="former" ? ArchivedStudent.find(params[:id]) : Student.find(params[:id]))
      data_hash[:student] = student
      type= params[:type] || "regular"
      batch=Batch.find(params[:batch_id])
      data_hash[:batch] = batch
      student.batch_in_context_id = batch.id
      report=student.individual_cce_report_cached
      data_hash[:report] = report
      subjects=student.all_subjects.select{|x| x.exams.present?}
      data_hash[:subjects] = subjects
      exam_groups=ExamGroup.find_all_by_id(report.exam_group_ids, :include=>:cce_exam_category)
      data_hash[:exam_groups] = exam_groups
      coscholastic=report.coscholastic
      observation_group_ids=coscholastic.collect(&:observation_group_id)
      observation_groups=ObservationGroup.find_all_by_id(observation_group_ids).collect(&:name)
      co_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      obs_groups=batch.observation_groups.to_a
      data_hash[:obs_groups] = obs_groups
      og=obs_groups.group_by(&:observation_kind)
      co_hashi = {}
      og.each do |kind, ogs|
        co_hashi[kind]=[]
        coscholastic.each{|cs| co_hashi[kind] << cs if ogs.collect(&:id).include? cs.observation_group_id}
      end
      data_hash[:co_hashi] = co_hashi
      data_hash[:parameters] = params
      find_report_type(data_hash)
    end

    def grouped_exam(params)
      params = params[:params] if params.key?(:params)
      data_hash ||= Hash.new
      data_hash[:parameters] = params
      data_hash[:method] = "grouped_exam"
      type = params[:type]
      data_hash[:type] = type
      batch = Batch.find(params[:batch])
      data_hash[:batch] = batch
      students = batch.students.by_first_name
      data_hash[:students] = students
      if type == 'grouped'
        grouped_exams = GroupedExam.find_all_by_batch_id(batch.id)
        exam_groups = []
        grouped_exams.each do |x|
          exam_groups.push ExamGroup.find(x.exam_group_id, :include => :exams)
        end
      else
        exam_groups = ExamGroup.find_all_by_batch_id(batch.id)
        exam_groups.reject!{|e| e.result_published==false}
      end
      data_hash[:exam_groups] = exam_groups
      if batch.gpa_enabled?
        data_hash[:grade_type] = "GPA"
      elsif batch.cwa_enabled?
        data_hash[:grade_type] = "CWA"
      else
        data_hash[:grade_type] = "normal"
      end
      find_report_type(data_hash)
    end

    private

    def find_report_type(h)
      case h[:parameters][:report_format_type]
      when "csv"
        send("#{h[:method]}_csv",h)
      when "pdf"
        return h
      end
    end

    def student_advanced_search_csv(data_hash)
      data ||= Array.new
      data << ["#{t('students')} #{t('listed_by')} "+"#{ }"+data_hash[:searched_for].downcase]
      temp = ["#{t('name')}","#{t('batch')}","#{t('adm_no')}"]
      temp.push("#{t('roll_no')}") if Configuration.enabled_roll_number?
      if (((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:doa_option].present?)) and ((!data_hash[:parameters].present?) or (!data_hash[:parameters][:advv_search].present?) or (!data_hash[:parameters][:advv_search][:dob_option].present?)))
        temp.push("#{t('admission_date')}")
      elsif (((!data_hash[:parameters].present?) or (!data_hash[:parameters][:advv_search].present?) or (!data_hash[:parameters][:advv_search][:doa_option].present?)) and ((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:dob_option].present?)))
        temp.push("#{t('date_of_birth')}")
      elsif (((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:doa_option].present?)) and ((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:dob_option].present?)))
        temp.push("#{t('admission_date')}")
        temp.push("#{t('date_of_birth')}")
      end
      temp.push("#{t('leaving_date')}") if data_hash[:parameters][:search][:is_active_equals]=="false"
      data << temp
      data_hash[:students].each do |row|      
        temp = [row.full_name.to_s,row.batch.full_name.to_s,row.admission_no.to_s]
        temp.push(row.roll_number) if Configuration.enabled_roll_number?
        if (((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:doa_option].present?)) and ((!data_hash[:parameters].present?) or (!data_hash[:parameters][:advv_search].present?) or (!data_hash[:parameters][:advv_search][:dob_option].present?)))
          temp.push(format_date(row.admission_date))
        elsif (((!data_hash[:parameters].present?) or (!data_hash[:parameters][:advv_search].present?) or (!data_hash[:parameters][:advv_search][:doa_option].present?)) and ((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:dob_option].present?)))
          temp.push(format_date(row.date_of_birth))
        elsif (((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:doa_option].present?)) and ((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:dob_option].present?)))
          temp.push(format_date(row.admission_date))
          temp.push(format_date(row.date_of_birth))
        end
        temp.push(format_date(row.date_of_leaving,:format=>:short)) if data_hash[:parameters][:search][:is_active_equals]=="false"
        data << temp
      end
      return data
    end

    def student_attendance_report_csv(data_hash)
      data ||= Array.new
      data << ["#{t('course_text')} : #{data_hash[:course]}"]
      data << ["#{t('batch')} : #{data_hash[:batch]}"]
      if data_hash[:parameters][:report_type] == 'Monthly'
        data << ["#{t('month_and_year')} : #{data_hash[:parameters][:start_date].to_date.strftime('%B %Y')}"]
      end
      if data_hash[:config].config_value == 'Daily'
        data << "#{t('total_no_of_wrkng_days')} = " + data_hash[:academic_days].to_s
      else
        data << "#{t('total_no_of_wrkng_hours')} = " + data_hash[:academic_days].to_s
        if data_hash[:subject].nil?
          data << "#{t('subject')} : " + "#{t('all_subjects')}"
        else
          data << "#{t('subject')} : " + data_hash[:subject].name
        end
      end

      temp =  [t('name'), t('adm_no'),t('total'),t('percentage')]
      temp.insert(2,t('roll_no')) if Configuration.enabled_roll_number?
      data << temp
      data_hash[:students].each do |row|
        unless data_hash[:range].empty? && data_hash[:value].empty?
          if data_hash[:leaves][row.id]['percent'].round(2) < data_hash[:value].to_f and data_hash[:range] == 'Below'
            temp = [row.full_name,row.admission_no,data_hash[:leaves][row.id]['total'].to_s,((data_hash[:leaves][row.id]['percent'].round(2).to_s) unless data_hash[:leaves][row.id]['percent'].nil?)]
            temp.insert(2,row.roll_number) if Configuration.enabled_roll_number?
            data << temp
          elsif data_hash[:leaves][row.id]['percent'].round(2) > data_hash[:value].to_f and data_hash[:range] == 'Above'
            temp = [row.full_name,row.admission_no,data_hash[:leaves][row.id]['total'].to_s,((data_hash[:leaves][row.id]['percent'].round(2).to_s) unless data_hash[:leaves][row.id]['percent'].nil?)]
            temp.insert(2,row.roll_number) if Configuration.enabled_roll_number?
            data << temp
          elsif data_hash[:leaves][row.id]['percent'].round(2) == data_hash[:value].to_f and data_hash[:range] == 'Equals'
            temp = [row.full_name,row.admission_no,data_hash[:leaves][row.id]['total'].to_s,((data_hash[:leaves][row.id]['percent'].round(2).to_s) unless data_hash[:leaves][row.id]['percent'].nil?)]
            temp.insert(2,row.roll_number) if Configuration.enabled_roll_number?
            data << temp
          end
        else
          temp = [row.full_name,row.admission_no,data_hash[:leaves][row.id]['total'].to_s,(((data_hash[:leaves][row.id]['percent']).round(2).to_s) unless data_hash[:leaves][row.id]['percent'].nil?)]
          temp.insert(2,row.roll_number) if Configuration.enabled_roll_number?
          data << temp
        end
      end
      return data
    end

    def day_wise_report_csv(data_hash)
      data ||= Array.new
      data << ["#{t('date_text')} : #{format_date(data_hash[:date])}"]
      data << [t('courses_text'),t('batches_text'),t('absentees')]
      data_hash[:report].each do |course,batches|
        batches.each do |batch|
          data << [course,batch.name,batch.attendance_count]
        end
      end
      return data
    end
    
    def student_ranking_per_subject_csv(data_hash)
      data ||= Array.new
      data << ["#{t('subjects_rankings')} - #{data_hash[:subject].name}"]
      data << ["#{data_hash[:batch_name]} - #{data_hash[:course]}"]
      header = ["#{t('name')}","#{t('adm_no')}"]
      header.insert(2,"#{t('roll_no')}") if Configuration.enabled_roll_number?
      data_hash[:exam_groups].each do |exam_group|
        header << exam_group.name
      end
      data << header
      data_hash[:students].each_with_index do |student,i|
        row = [student.full_name]
        student.admission_no.present? ? row << student.admission_no : row << "-"
        (student.roll_number.present? ? row << student.roll_number : row << "--") if Configuration.enabled_roll_number?
        data_hash[:exam_groups].each do |exam_group|
          mark_list = []
          data_hash[:ranks].each do|rank|
            if rank[0]==exam_group.id
              mark_list = rank[1]
            end
          end
          exam = Exam.find_by_subject_id(data_hash[:subject].id,:conditions=>{:exam_group_id=>exam_group.id}, :include => :exam_scores)
          exam_score = exam.exam_scores.select{|x| x.student_id == student.id and x.exam_id == exam.id} unless exam.nil?
          unless exam.nil?
            exam_score.empty? ? row << '-' : row << (exam_score[0].marks.nil? ? '-' : (mark_list.index(exam_score[0].marks) + 1))
          else
            row << "#{t('n_a')}"
          end
        end
        data << row
      end
      return data
    end

    def student_ranking_per_batch_csv(data_hash)
      data = Array.new
      data << ["#{t('overall_batch_rankings')} : #{data_hash[:batch]} - #{data_hash[:course]}"]
      temp = ["#{t('name')}","#{t('adm_no')}","#{t('marks')}","#{t('rank')}"]
      temp.insert(2,"#{t('roll_no')}") if Configuration.enabled_roll_number?
      data << temp
      data_hash[:ranked_students].each_with_index do |student,ind|
        row = ["#{student[3].full_name}"]
        student[3].admission_no.present? ? row << student[3].admission_no : row << "--"
        (student[3].roll_number.present? ? row << student[3].roll_number : row << "--") if Configuration.enabled_roll_number?
        row << student[1]
        row << student[0]
        data << row
      end
      return data
    end

    def student_ranking_per_course_csv(data_hash)
      data = Array.new
      data << "#{t('overall_rankings')}" + ":"  + (data_hash[:batch_group].present? ? "#{data_hash[:batch_group].name}" : "#{data_hash[:course].full_name}")
      temp = ["#{t('name')}","#{t('batch')}","#{t('adm_no')}","#{t('marks')}","#{t('rank')}"]
      temp.insert(3,t('roll_no')) if Configuration.enabled_roll_number?
      data << temp
      data_hash[:ranked_students].each_with_index do |student,i|
        row = []
        if data_hash[:sort_order]=="" or data_hash[:sort_order]=="rank-ascend" or data_hash[:sort_order]=="rank-descend"
          row << student[3].full_name
          row << student[3].batch.full_name
          student[3].admission_no.present? ? row << student[3].admission_no : row << "--"
          (student[3].roll_number.present? ? row << student[3].roll_number : row << "--") if Configuration.enabled_roll_number?
          row << student[1]
          row << student[0]
        else
          row << student[4].full_name
          row << student[4].batch.full_name
          student[4].admission_no.present? ? row << student[4].admission_no : row << "--"
          (student[4].roll_number.present? ? row << student[4].roll_number : row << "--") if Configuration.enabled_roll_number?
          row << student[2]
          row << student[1]
        end
        data << row
      end
      return data
    end

    def student_ranking_per_school_csv(data_hash)
      data = Array.new
      data << ["#{t('overall_school_rankings')} : #{Configuration.find_by_config_key("InstitutionName").config_value.present? ? Configuration.find_by_config_key("InstitutionName").config_value : "-"}"]
      temp = ["#{t('name')}","#{t('batch')}","#{t('adm_no')}","#{t('marks')}", "#{t('rank')}"]
      temp.insert(3,t('roll_no')) if Configuration.enabled_roll_number?
      data << temp
      index = 0; total = 0; i = 0
      data_hash[:ranked_students].each_with_index do |student,i|
        row = []
        if data_hash[:sort_order] =="" or data_hash[:sort_order] =="rank-ascend" or data_hash[:sort_order]=="rank-descend"
          row << student[3].full_name
          row << student[3].batch.full_name
          student[3].admission_no.present? ? row << student[3].admission_no : row << "--"
          (student[3].roll_number.present? ? row << student[3].roll_number : row << "--") if Configuration.enabled_roll_number?
          row << student[1]
          row << student[0]
        else
          row << student[4].full_name
          row << student[4].batch.full_name
          student[4].admission_no.present? ? row << student[4].admission_no : row << "--"
          (student[4].roll_number.present? ? row << student[4].roll_number : row << "--") if Configuration.enabled_roll_number?
          row << student[2]
          row << student[1]
        end
        data << row
      end
      return data
    end

    def student_ranking_per_attendance_csv(data_hash)
      data = Array.new
      data << ["#{t('overall_ranking_per_attendance')} : #{data_hash[:batch].name} - #{data_hash[:batch].course.full_name} | #{format_date(data_hash[:start_date])} - #{format_date(data_hash[:end_date])}"]
      temp = ["#{t('name')}","#{t('adm_no')}","#{t('working_days')}","#{t('attended')}","#{t('percentage')}","#{t('rank')}"]
      temp.insert(2,t('roll_no')) if Configuration.enabled_roll_number?
      data << temp
      unless data_hash[:students].empty?
        working_days = data_hash[:batch].find_working_days(data_hash[:start_date],data_hash[:end_date]).count
        unless working_days == 0
          data_hash[:ranked_students].each_with_index do |student,ind|
            row = ["#{student[5].full_name}"]
            student[5].admission_no.present? ? row << student[5].admission_no : row << "--"
            (student[5].roll_number.present? ? row << student[5].roll_number : row << "--") if Configuration.enabled_roll_number?
            row << student[3]
            row << student[4]
            row << "%.2f" %(student[1])
            row << student[0]
            data << row
          end
        end
      end
      return data
    end

    def employee_advance_search_csv(data_hash)
      data = Array.new
      data << ["#{t('employee_search_report')}"]
      data << ["#{t('employee_text')} "+ (data_hash[:searched_for].camelcase unless data_hash[:searched_for].nil?)]
      data << ["#{t('name')}","#{t('department')}", "#{t('employee_number')}", "#{t('joining_date')}", (("#{t('leaving_date')}") if data_hash[:parameters][:status]=='false')]
      data_hash[:employees].each_with_index do |employee1,i|
        row = [employee1.first_name,employee1.employee_department.name,employee1.employee_number,format_date(employee1.joining_date)]
        row << format_date(employee1.updated_at,:format=>:short_date) if data_hash[:parameters][:status]=='false'
        data << row
      end
      return data
    end

    def employee_attendance_data_csv(data_hash)
      data = Array.new
      data << ["#{t('department_attendance_report')}"]
      data << ["#{t('department')} - #{data_hash[:department_name]}"]
      data << ["#{t('total_members')} - #{data_hash[:employees].count}"]
      row = ["#{t('name')}","#{t('employee_number')}"]
      data_hash[:leave_types].each{ |lt| row << lt.code}
      row << t('total')
      data << row
      data_hash[:employees].each do |e|
        row = ["#{e.first_name}","#{e.employee_number}"]
        total = 0
        data_hash[:leave_types].each do |lt1|
          leave_count = EmployeeLeave.find_by_employee_leave_type_id_and_employee_id(lt1.id, e.id)
          unless leave_count.nil?
            if data_hash[:parameters][:filter_type]=='true'
              filtered_attendance = EmployeeAttendance.find(:all,:conditions=> ["attendance_date BETWEEN ? AND ?",data_hash[:parameters][:start_date],data_hash[:parameters][:end_date]])
              report = filtered_attendance.select {|x| x.employee_id == e.id && x.employee_leave_type_id == lt1.id }
            else
              attendance = EmployeeAttendance.all
              unless leave_count.reset_date.nil?
                report = attendance.select {|x| x.employee_id == e.id && x.employee_leave_type_id == lt1.id && x.created_at >= leave_count.reset_date}
              else
                report = attendance.select {|x| x.employee_id == e.id && x.employee_leave_type_id == lt1.id }
              end
            end
            count = 0
            unless report.nil?
              report.each do |d|
                if d.is_half_day==true
                  count += 0.5
                else
                  count +=1
                end
              end
              row << count
              total += count
            end
          else
            row << "-"
          end
        end
        row << total
        data << row
      end
      return data
    end

    def subject_wise_data_csv(data_hash)
      data ||= Array.new
      data << [data_hash[:subject].name]
      data << ["#{data_hash[:batch].name} -  #{data_hash[:batch].course.full_name}"]
      row = ["#{t('name')}","#{t('admission_no')}"]
      row << "#{t('roll_no')}" if Configuration.enabled_roll_number?
      i = 0
      data_hash[:exam_groups].each do |exam_group|
        row << exam_group.name
      end
      data << row
      data_hash[:students].each do |student|
        is_valid_subject = 1
        unless data_hash[:subject].elective_group_id.nil?
          is_student_elective = StudentsSubject.find_by_student_id_and_subject_id(student.id,data_hash[:subject].id)
          is_valid_subject = 0 if is_student_elective.nil?
        end
        unless is_valid_subject == 0
          row = [student.full_name,student.admission_no]
          row << (student.roll_number.present? ? student.roll_number : '--' ) if Configuration.enabled_roll_number?
          data_hash[:exam_groups].each do |exam_group|
            exam = Exam.find_by_subject_id(data_hash[:subject].id,:conditions=>{:exam_group_id=>exam_group.id})
            exam_score = ExamScore.find_by_student_id(student.id,:conditions=>{:exam_id=>exam.id}) unless exam.nil?
            unless exam.nil?
              if exam_group.exam_type == 'Marks'
                exam_score.nil? ? row << "--" : row << "#{exam_score.marks || "-"}/"+exam.maximum_marks.to_s
              elsif exam_group.exam_type == 'Grades'
                exam_score.nil? ? row << "--" : row << (exam_score.grading_level || '-')
              else
                exam_score.nil? ? row << "--" :  row << "#{(exam_score.marks || "-")}" +"/"+exam.maximum_marks.to_s+"[#{(exam_score.grading_level || "-")}]"
              end
            else
              row << "N.A"
            end
          end
          i+=1
          data << row
        end
      end
      row = ["#{t('class_average')}",""]
      data_hash[:exam_groups].each do |exam_group|
        if exam_group.exam_type == 'Marks' or exam_group.exam_type == 'MarksAndGrades'
          exam = Exam.find_by_subject_id(data_hash[:subject].id,:conditions=>{:exam_group_id=>exam_group.id})
          if exam.nil?
            row << "--"
          else
            row << ("%.2f"%exam_group.subject_wise_batch_average_marks(data_hash[:subject].id)).to_s unless exam.nil?
          end
        else
          row << "--"
        end
      end
      data << row
      return data
    end

    def consolidated_exam_data_csv(data_hash)
      data ||= Array.new
      data << [data_hash[:batch].course.full_name + data_hash[:batch].name + "|" + data_hash[:exam_group].name]
      row = ["#{t('name')}","#{t('admission_no')}"]
      row << "#{t('roll_no')}" if Configuration.enabled_roll_number? 
      grade_type = data_hash[:grade_type]
      if grade_type=="GPA" or grade_type=="CWA"
        data_hash[:exams].each do |exam|
          row << exam.subject.code + ("(" + exam.subject.credit_hours.to_s + ")"  unless exam.subject.credit_hours.nil?)
        end
        if grade_type=="CWA"
          row << t('weighted_average')
        else
          row << t('gpa')
        end
      else
        data_hash[:exams].each do |exam|
          #         row << exam.subject.code + (("(&#x200E;" + exam.maximum_marks.to_s + ")&#x200E;")  unless (exam.maximum_marks.nil? or exam_group.exam_type == "Grades" ))
          row << exam.subject.code #+ (("("+ exam.maximum_marks.to_s + ")")  unless (exam.maximum_marks.nil? or h[:exam_group].exam_type == "Grades" ))
        end
        unless data_hash[:exam_group].exam_type == "Grades"
          row << t('percentage') + "(%)"
        end
      end
      data << row
      data_hash[:exam_group].batch.students.each do |student|
        row = [student.full_name,student.admission_no]
        row << (student.roll_number.present? ? student.roll_number : '--')  if Configuration.enabled_roll_number?
        if grade_type=="GPA"
          total_credits = 0
          total_credit_points=0
          data_hash[:exams].each do |exam|
            exam_score = ExamScore.find_by_student_id_and_exam_id(student.id,exam.id)
            unless exam_score.nil?
              exam_score.grading_level.present? ? row << exam_score.grading_level : row << "--"
              total_credits = total_credits + exam.subject.credit_hours.to_f unless exam.subject.credit_hours.nil?
              total_credit_points = total_credit_points + (exam_score.grading_level.credit_points.to_f * exam.subject.credit_hours.to_f) unless exam_score.grading_level.nil?
            else
              row << "--"
            end
          end
          if (total_credit_points.to_f/total_credits.to_f).nan?
            row << "--"
          else
            row << "%.2f" %(total_credit_points.to_f/total_credits.to_f)
          end
        elsif grade_type=="CWA"
          total_credits = 0
          total_weighted_marks=0
          data_hash[:exams].each do |exam|
            exam_score = ExamScore.find_by_student_id_and_exam_id(student.id,exam.id)
            unless exam_score.nil?
              exam_score.marks.present? ? row << "%.2f" %((exam_score.marks.to_f/exam.maximum_marks.to_f)*100) : row << "--"
              total_credits = total_credits + exam.subject.credit_hours.to_f unless exam.subject.credit_hours.nil?
              total_weighted_marks = total_weighted_marks + ((exam_score.marks.to_f/exam.maximum_marks.to_f)*100)*(exam.subject.credit_hours.to_f) unless exam_score.marks.nil?
            else
              row << "--"
            end
          end
          row << "%.2f" %(total_weighted_marks.to_f/total_credits.to_f)
        else
          total_marks = 0
          total_max_marks = 0
          data_hash[:exams].each do |exam|
            exam_score = ExamScore.find_by_student_id_and_exam_id(student.id,exam.id)
            unless data_hash[:exam_group].exam_type == "Grades"
              if data_hash[:exam_group].exam_type == "MarksAndGrades"
                exam_score.nil? ? row << '--' :  row << "#{(exam_score.marks || "-")}" + "(#{(exam_score.grading_level || "-")})"
              else
                exam_score.nil? ? row << '--' : row << exam_score.marks || "-"
              end
              total_marks = total_marks+(exam_score.marks || 0) unless exam_score.nil?
              total_max_marks = total_max_marks+exam.maximum_marks unless exam_score.nil?
            else
              exam_score.nil? ? row << '--' : row << exam_score.grading_level || "-"
            end
          end
          unless data_hash[:exam_group].exam_type == "Grades"
            percentage = total_marks*100/total_max_marks.to_f unless total_max_marks == 0
            unless total_max_marks == 0
              row << "%.2f" %percentage
            else
              row << "-"
            end
          end
        end
        data << row
      end
      return data
    end

    def ranking_level_csv(data_hash)
      data = Array.new
      if data_hash[:parameters][:mode] == "batch"
        subject = Subject.find(data_hash[:parameters][:subject_id]) if data_hash[:parameters][:subject_id].present?
        batch = Batch.find(data_hash[:parameters][:batch_id]) if data_hash[:parameters][:batch_id].present?
        data << ["#{data_hash[:ranking_level].name} #{t('students')}"]
        data << ["#{batch.full_name}"] #+  (" | #{t('subject')} : "+ subject.name if subject.present?) ]
        temp = ["#{t('adm_no')}","#{t('name')}"]
        temp.insert(0,"#{t('roll_no')}") if Configuration.enabled_roll_number?
        data << temp
        data_hash[:ranked_students].each_with_index do |s,ind|
          row_data = []
          (s.roll_number.present? ? row_data << s.roll_number : row_data << "--") if Configuration.enabled_roll_number?
          s.admission_no.present? ? row_data << s.admission_no : row_data << "--"
          row_data << s.full_name
          data << row_data
        end
      else
        course = Course.find(data_hash[:parameters][:course_id])
        data << ["#{data_hash[:ranking_level].name}  #{t('students')}"]
        data << ["#{course.full_name}"]
        temp = ["#{t('adm_no')}","#{t('name')}","#{t('batch')}",("#{data_hash[:ranking_level].name} #{t('batch')}" unless data_hash[:ranking_level].full_course==true)]
        temp.insert(0,"#{t('roll_no')}") if Configuration.enabled_roll_number?
        data << temp
        data_hash[:ranked_students].each_with_index do |s,i|
          stu = Student.find(s[0])
          batch = Batch.find(s[1])
          row = [(stu.admission_no.present? ? stu.admission_no : "-"),stu.full_name,stu.batch.full_name ,(batch.full_name unless data_hash[:ranking_level].full_course==true)]
          row.insert(0,(stu.roll_number.present? ? stu.roll_number : "--")) if Configuration.enabled_roll_number?
          data << row
        end
      end
      return data
    end

    def finance_transaction_data_csv(data_hash)
      data = Array.new
      data << ["#{t('finance_transaction_report')}"]
      data << ["#{t('from')} ( #{format_date(data_hash[:start_date])}) #{t('to')} ( #{format_date(data_hash[:end_date])})"]
      data << ["#{t('particulars')}","#{t('expenses')}","#{t('income')}"]
      index = 0; income_total = 0; expenses_total = 0
      unless data_hash[:hr].nil?
        data << ["#{t('salary')}",precision_label(data_hash[:salary]),""]
      end
      data << ["#{t('donations')}","",precision_label(data_hash[:donations_total])]
      data << ["#{t('fees_account')}","",precision_label(data_hash[:transactions_fees])]
      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        row = ["#{t(category[:category_name]+'_account')}"]
        if data_hash[:category_transaction_totals]["#{category[:category_name]}"][:category_type] == "income"
          row << ""
          row << precision_label(data_hash[:category_transaction_totals]["#{category[:category_name]}"][:amount])
        else
          row << precision_label(data_hash[:category_transaction_totals]["#{category[:category_name]}"][:amount])
          row << ""
        end
        data << row
      end
      data_hash[:other_transaction_categories].each_with_index do |t,i|
        income = t.total_income(data_hash[:start_date],data_hash[:end_date])
        expense = t.total_expense(data_hash[:start_date],data_hash[:end_date])
        data << [t.name,precision_label(expense),precision_label(income)]
        income_total +=income
        expenses_total +=expense
      end
      if data_hash[:grand_total] >= 0
        data << ["#{t('grand_total')}","",precision_label(data_hash[:grand_total]).to_s]
      else
        data << ["#{t('grand_total')}",precision_label(data_hash[:grand_total] * -1).to_s,""]
      end
      return data
    end


    def finance_payslip_data_csv(data_hash)
      return payslip_data(data_hash)
    end

    def employee_payslip_data_csv(data_hash)
      return payslip_data(data_hash)
    end

    def payslip_data(data_hash)
      data ||= Array.new
      data << ["#{t('department')}" + ":" + "#{data_hash[:department_name]}"]
      data << ["#{t('salary_month')}" + ":" + "#{data_hash[:salary_month]}"]
      data << ["#{t('employee_name')}","#{t('employee_no')}","#{t('net_salary')}","#{t('payslip_status')}"]
      total_salary = 0; total_approved_salary = 0;total_employees = 0; i = 0
      unless data_hash[:grouped_monthly_payslips].blank?
        data_hash[:grouped_monthly_payslips].each do |(empid,payslip)|
          if payslip and payslip.first and payslip.first.active_or_archived_employee
            i += 1
            row = [payslip.first.active_or_archived_employee.full_name,payslip.first.active_or_archived_employee.employee_number]
            grouped_individual_payslip_category = nil
            unless data_hash[:grouped_individual_payslip_categories].blank?
              grouped_individual_payslip_category = data_hash[:grouped_individual_payslip_categories][empid] unless data_hash[:grouped_individual_payslip_categories][empid].nil?
            end
            emp_payslip = Employee.calculate_salary(payslip,grouped_individual_payslip_category)
            row << precision_label(emp_payslip[:net_amount]) unless emp_payslip.nil?
            row << payslip.first.status_as_text
          end
          total_salary +=  emp_payslip[:net_amount].to_f unless emp_payslip.nil?
          total_approved_salary +=  emp_payslip[:net_amount].to_f if  !emp_payslip.nil? and payslip.first.is_approved
          total_employees = i
          data << row
        end
      end
      data << [] << ["#{t('total_employees')}",total_employees]
      data << ["#{t('total_salary')}",precision_label(total_salary)]
      data << ["#{t('approved_salary')}",precision_label(total_approved_salary)]
      return data
    end

    def student_wise_report_csv(data_hash)
      data = Array.new
      scholastic = data_hash[:report].scholastic
      cgpa=0.0; count=0
      data << ["STUDENT REPORT"]
      data << ["Name : #{data_hash[:student].full_name}"]
      data << ["#{t('course')} : #{data_hash[:batch].course.full_name}"]
      data << ["Adm No. : #{(data_hash[:student].admission_no.present? ? data_hash[:student].admission_no : "--")}"]
      data << ["Roll No. : #{(data_hash[:student].roll_number.present? ? data_hash[:student].roll_number : "--")}"] if Configuration.enabled_roll_number?
      data << ["Batch : #{data_hash[:batch].name}"]
      data << ["Scholastic Areas"]

      if data_hash[:exam_groups].empty?
        data << ["No Exams"]
      else
        row = ["Sl no","Subjects"]
        data_hash[:exam_groups].each do |eg|
          row << eg.cce_exam_category.name
        end
        if data_hash[:exam_groups].count==2
          row << ["Overall"]
        end
        data << row

        data_hash[:exam_groups].each_with_index do |eg,i|
          row = ["","","FA#{2*i+1}","FA#{2*i+2}","SA#{i+1}","FA#{2*i+1}+ FA#{2*i+2}+ SA#{i+1}"]
        end
        if data_hash[:exam_groups].count==2
          row << "FA1"+ "FA2"+ "FA3"+ "FA4"
          row << "SA1"+ "SA2"
          row << "Overall"
          row << "Grade Point"
        end

        data << row

        data_hash[:subjects].each_with_index do |s,i|
          row = [i+1,s.name]
          sub=scholastic.find{|c| c.subject_id==s.id}
          data_hash[:exam_groups].each_with_index do |eg,j|
            se=sub.exams.find{|g| g.exam_group_id==eg.id} if sub
            if se
              row << se.fa[se.fa_names["FA#{2*j+1}"]] if se.fa_names["FA#{2*j+1}"]
              row << se.fa[se.fa_names["FA#{2*j+2}"]] if se.fa_names["FA#{2*j+2}"]
              row << se.sa
              row << se.overall
            else
              row << "-"
              row << "-"
              row << "-"
              row << "-"
            end
          end
          if data_hash[:exam_groups].count==2
            if sub
              sub.fa
              sub.sa
              sub.overall
              sub.grade_point
              if s.elective_group_id.blank?
                cgpa += sub.grade_point.to_f
                count += 1
              end
            else
              row << "-"
              row << "-"
              row << "-"
              row << "-"
            end
          end
          data << row
        end
      end
      data_hash[:co_hashi].keys.sort.each do |kind|
        data << [ObservationGroup::OBSERVATION_KINDS[kind]]
        i = 0; data_hash[:co_hashi][kind].each{|el| i+=1; el.sort_order ||= i}
        data_hash[:co_hashi][kind].sort_by(&:sort_order).each do |ob_grp|
          data << [data_hash[:obs_groups].find{|o| o.id == ob_grp.observation_group_id}.try(:name)]
          data << ["Observation","Descriptive Indicators","Grade"]
          ob_grp.observations.sort_by(&:sort_order).each do |o|
            data << [o.observation_name,data_hash[:student].get_descriptive_indicators(o.observation_id),o.grade]
          end
        end
      end
      return data
    end

    def grouped_exam_csv(data_hash)
      data = Array.new
      type = data_hash[:type]
      batch = data_hash[:batch]
      data << "Grouped Exam Report for Batch : "+ batch.full_name
      grade_type = data_hash[:grade_type]
      students = data_hash[:students]
      general_subjects = Subject.find_all_by_batch_id(batch.id, :conditions=>"elective_group_id IS NULL and is_deleted=false")
      exams = Exam.find_all_by_exam_group_id(data_hash[:exam_groups].collect(&:id))
      students.each_with_index do |student,i|
        student_electives = StudentsSubject.find_all_by_student_id(student.id,:conditions=>"batch_id = #{batch.id}")
        elective_subjects = []
        student_electives.each do |elect|
          elective_subjects.push Subject.find_by_id(elect.subject_id,:conditions => {:is_deleted => false})
        end
        subjects = general_subjects + elective_subjects
        subjects = subjects.compact.flatten
        subjects.reject!{|s| s.no_exams==true}
        subject_ids = exams.collect(&:subject_id)
        subjects.reject!{|sub| !(subject_ids.include?(sub.id))}
        row_data = ["#{student.full_name} - #{student.admission_no}"]
        data << row_data
        data << ["#{t('roll_no')} - #{student.roll_number.present? ? student.roll_number : '--'}"] if Configuration.enabled_roll_number?
        if type=="grouped"
          row_data = []
          row_data << t('subject')
          if grade_type=="GPA" or grade_type=="CWA"
            row_data << t('credit')
          end
          data_hash[:exam_groups].each do |exam_group|
            row_data << exam_group.name
          end
          row_data << t('combined')
          data << row_data
          subjects.each do |subject|
            row_data = ["#{subject.name}"]
            if grade_type=="GPA" or grade_type=="CWA"
              subject.credit_hours.present? ? row_data << subject.credit_hours : row_data << "-"
            end
            data_hash[:exam_groups].each do |exam_group|
              exam = Exam.find_by_subject_id_and_exam_group_id(subject.id,exam_group.id)
              exam_score = ExamScore.find_by_student_id(student.id, :conditions=>{:exam_id=>exam.id})unless exam.nil?
              if grade_type=="GPA"
                exam_score.present? ? row_data << "#{exam_score.grading_level || "-"}"+" ["+"#{exam_score.grading_level.present? ? (exam_score.grading_level.credit_points || "-") : "-"}"+"]" : row_data << "-"
              elsif grade_type=="CWA"
                exam_score.present? ? row_data << "#{exam_score.marks.present? ? ("%.2f" %((exam_score.marks.to_f/exam.maximum_marks.to_f)*100)) : "-"}"+" ["+"#{exam_score.grading_level.present? ? exam_score.grading_level : "-"}"+"]" : row_data << "-"
              else
                if exam_group.exam_type == "MarksAndGrades"
                  exam_score.nil? ? row_data << '-' :  row_data << "#{(exam_score.marks || "-")}" +"/"+exam.maximum_marks.to_s+"[#{(exam_score.grading_level || "-")}]"
                elsif exam_group.exam_type == "Marks"
                  exam_score.nil? ? row_data << '-' : row_data << "#{exam_score.marks || "-"}/"+exam.maximum_marks.to_s
                else
                  exam_score.nil? ? row_data << '-' : row_data << (exam_score.grading_level || '-')
                end
              end
            end
            subject_average = GroupedExamReport.find_by_student_id_and_subject_id_and_score_type(student.id,subject.id,"s")
            subject_average.present? ? row_data << "#{subject_average.marks}[#{GradingLevel.percentage_to_grade(subject_average.marks, batch.id).present? ? GradingLevel.percentage_to_grade(subject_average.marks, batch.id) : '-'}]" : "-[-]"
            data << row_data
          end
          row_data = []
          if grade_type=="GPA"
            row_data <<  t('gpa') << ""
          elsif grade_type=="CWA"
            row_data << t('weighted_average')
          else
            row_data << t('percentage')
          end
          data_hash[:exam_groups].each do |exam_group|
            exam_total = GroupedExamReport.find_by_student_id_and_exam_group_id_and_score_type(student.id,exam_group.id,"e")
            exam_total.present? ? row_data << exam_total.marks : row_data << "-"
          end
          total_avg = GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(student.id,student.batch.id,"c")
          total_avg.present? ? row_data << total_avg.marks : row_data << "-"
          data << row_data
        else
          row_data = []
          all_exams = data_hash[:exam_groups].reject{|ex| ex.exam_type == "Grades"}
          row_data << t('subject')
          data_hash[:exam_groups].each do |exam_group|
            row_data << exam_group.name
          end
          unless all_exams.empty?
            row_data << t('total')
          end
          data << row_data
          subjects.each do |subject|
            row_data = ["#{subject.name}"]
            mmg = 1;g = 1
            data_hash[:exam_groups].each do |exam_group|
              exam = Exam.find_by_subject_id_and_exam_group_id(subject.id,exam_group.id)
              exam_score = ExamScore.find_by_student_id(student.id, :conditions=>{:exam_id=>exam.id})unless exam.nil?
              unless exam.nil?
                if exam_group.exam_type == "MarksAndGrades"
                  exam_score.nil? ? row_data << '-' :  row_data << "#{(exam_score.marks || "-")}" +"/"+exam.maximum_marks.to_s+"[#{(exam_score.grading_level || "-")}]"
                elsif exam_group.exam_type == "Marks"
                  exam_score.nil? ? row_data << '-' : row_data << "#{exam_score.marks || "-"}/"+exam.maximum_marks.to_s
                else
                  exam_score.nil? ? row_data << '-' : row_data << (exam_score.grading_level || '-')
                  g = 0
                end
              else
                row_data << "#{t('n_a')}"
              end
            end
            total_score = ExamScore.new()
            unless all_exams.empty?
              if mmg == g
                row_data << total_score.grouped_exam_subject_total(subject,student,type)
              else
                row_data << "-"
              end
            end
            data << row_data
          end
          row_data = [t('total')]
          max_total = 0; marks_total = 0
          data_hash[:exam_groups].each do |exam_group|
            if exam_group.exam_type == "MarksAndGrades"
              row_data << exam_group.total_marks(student)[0]
            elsif exam_group.exam_type == "Marks"
              row_data << exam_group.total_marks(student)[0]
            else
              row_data << "-"
            end
            unless exam_group.exam_type == "Grades"
              max_total = max_total + exam_group.total_marks(student)[1]
              marks_total = marks_total + exam_group.total_marks(student)[0]
            end
          end
          unless all_exams.empty?
            row_data << ""
          end
          data << row_data
        end
        row_data = []
        data << row_data

        row_data = []
        data << row_data
        row_data << "Remarks"
        row_data = []
        data << row_data
        remarks=RemarkMod.generate_common_remark_form("grouped_exam_general", student.id,nil,1,{:batch_id=>student.batch_id,:student_id=>student.id})
        if remarks.present?
          remarks.each do |remark|
            remark_user=remark.user.present? ? remark.user.first_name : 'deleted user'
            row_data=[remark.remarked_by,remark.remark_body,"#{remark_user} on #{format_date(remark.updated_at,:format=>:long)}"]
            data<<row_data
          end
        else
          row_data << "No remarks added yet"
        end
        row_data=[]
        data << row_data
      end
      return data
    end

    def precision_label(val)
      precision_count = Configuration.get_config_value('PrecisionCount')
      precision = precision_count.to_i < 2 ? 2 : precision_count.to_i > 9 ? 8 : precision_count.to_i
      return sprintf("%0.#{precision}f",val)
    end
  end
end

 

class StudentAttendance < ActiveRecord::Base
  belongs_to :student
  validate :unique_attendance_per_day
  
  def unique_attendance_per_day
    if student_id.present?
      student_attendance_in = StudentAttendance.find(:all, :conditions => {:student_id => student_id, :in_time => in_time , :school_id => school_id }) rescue nil
      if !sms_sent? && !out_time.present? && student_attendance_in.present? 
        errors.add('student_id',"IN attendance already exists")
        false
      end
      student_attendance_out = StudentAttendance.find(:all, :conditions => {:student_id => student_id, :out_time => out_time , :school_id => school_id }) rescue nil
      if !sms_sent? && out_time.present? && student_attendance_out.present?
        errors.add('student_id',"OUT attendance already exists")
        false
      end
    end

    if employee_id.present?
      employee_attendance_in = StudentAttendance.find(:all, :conditions => {:employee_id => employee_id, :in_time => in_time , :school_id => school_id }) rescue nil
      if !out_time.present? && employee_attendance_in.present?
        errors.add('employee_id',"IN attedance already exists")
        false
      end
      employee_attendance_out = StudentAttendance.find(:all, :conditions => {:employee_id => employee_id, :out_time => out_time , :school_id => school_id }) rescue nil
      if out_time.present? && employee_attendance_out.present?
        errors.add('employee_id',"OUT attedance already exists")
        false
      end
    end
  end

  def self.get_attendance_hash(params)
    @school_in_time = SchoolDetail.first.try(:in_time)
    batch_id, date = params["batch_id"], "1-#{params["date"]}".to_date
    if batch_id.present? && date.present?
      result = Hash.new
      result["date"] = params["date"]
      batch = Batch.find batch_id
      result["batch_tutor"] = batch.employees.first.full_name rescue nil
      result["not_weekdays"] = [1, 2, 3, 4, 5, 6,7] - batch.batch_class_timing_sets.map(&:weekday_id) rescue []
      students =  batch.students.by_first_name
      ids =  students.map(&:id)
      start_date = date.beginning_of_month.beginning_of_day
      end_date = date.end_of_month.end_of_day
      @start_date, @end_date = start_date, end_date
      result["holiday_events"] = get_holiday_events(start_date, end_date, batch_id)
      result["institution_address"] = Configuration.find_by_config_key("InstitutionAddress").config_value
      attendances = StudentAttendance.find(:all, :conditions => {:student_id => ids, :created_at => start_date..end_date})
      header = []
      data_hash = {}
      (start_date.to_date..end_date.to_date).each do |date|
        header << [date.strftime("%a"), date.day]
        data_hash[date.day] = []
      end

      # attendance percentage stsart
      academic_days = get_academic_days(batch)
      leaves_forenoon=Attendance.count(:all,:joins=>:student,:conditions=>{:batch_id=>batch.id,:forenoon=>true,:afternoon=>false,:month_date => start_date..end_date},:group=>:student_id)
      leaves_afternoon=Attendance.count(:all,:joins=>:student,:conditions=>{:batch_id=>batch.id,:forenoon=>false,:afternoon=>true,:month_date => start_date..end_date},:group=>:student_id)
      leaves_full=Attendance.count(:all,:joins=>:student,:conditions=>{:batch_id=>batch.id,:forenoon=>true,:afternoon=>true,:month_date => start_date..end_date},:group=>:student_id)
      # attendance percentage end

      result["working_days"] = academic_days
      result["batch_name"] = batch.name
      data = Hash.new
      students.each_with_index do |student,i|
        # Defines In/Out/Absent/LateIn
        array = Array.new
        (start_date.to_date..end_date.to_date).each do |date|
          array << get_in_and_out_time_array(student, date)
        end
        data[student.full_name] = Hash.new
        data[student.full_name]["attendance"] = 
        array.each_with_index do |arr, i|
        val = 
          if arr.include? nil
            nil
          elsif arr.include? "A"
            1
          else
            0
          end rescue nil
          data_hash[i+1] << val
        end
        total=academic_days-leaves_full[student.id].to_f-(0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
        data[student.full_name]["percentage"] = ((total.to_f/academic_days)*100 unless academic_days == 0).round(2) rescue nil
      end
    end
    attendance_percentage = {}
    data_hash.each do |key, val|
      value = 
        if ((val.count 0) == 0) && ((val.count nil) == students.count)
          nil
        elsif ((val.count 1) == 0)
          100
        else
          (((students.count - (val.count 1)).to_f/students.count.to_f)*100).to_f.round(2)
        end
      attendance_percentage[key] = value
    end
    result["daily_attendance_percentage"] = attendance_percentage
    result["day_one"] = get_day_in_int(start_date.strftime("%a"))
    return [header,data.sort,result]
  end

  def self.get_day_in_int(day)
    case day
    when "Mon"
      1
    when "Tue"
      2
    when "Wed"
      3
    when "Thu"
      4
    when "Fri"
      5
    when "Sat"
      6
    when "Sun"
      7
    end  
  end

  def self.get_holiday_events(start_date, end_date, batch_id)
    dates = []
    events = Event.find(:all, :conditions => {:start_date  => start_date.beginning_of_day..end_date.end_of_day, :end_date => start_date.beginning_of_day..end_date.end_of_day, :is_holiday => true})
    events.each do |event|
      if  (event.is_common || (event.batch_events.map(&:batch_id).include? batch_id.to_i))
        if event.start_date.day == end_date.day
          dates << event.start_date.day
        else
          dates << (event.start_date.day..event.end_date.day).to_a
        end
      end
    end
    return dates.flatten.uniq
  end

  def self.get_academic_days(batch)
    working_days=batch.working_days(@start_date.to_date)
    if @end_date.strftime("%m-%Y") == Time.now.to_date.strftime("%m-%Y")
      @end_date = Time.now.to_date
    end
    academic_days = working_days.select{|v| v<=@end_date.to_date}.count
    return academic_days
  end

  def self.get_in_and_out_time_array(student, date)
    attendance = Attendance.find(:all, :conditions => {:student_id => student.id, :month_date  => date.beginning_of_day..date.end_of_day})
    in_time = attendance.present? ? "A" : StudentAttendance.find(:all, :conditions => {:student_id => student.id, :in_time  => date.beginning_of_day..date.end_of_day}).first.in_time.strftime("%H:%M")  rescue nil
    out_time = attendance.present? ? "A" : StudentAttendance.find(:all, :conditions => {:student_id => student.id, :out_time => date.beginning_of_day..date.end_of_day}).first.out_time.strftime("%H:%M") rescue nil
    late_status = ((Date.today.strftime("%d-%m-%Y ") + in_time).to_datetime > (Date.today.strftime("%d-%m-%Y ") + @school_in_time.strftime("%H:%M")).to_datetime) ? "Late" : "" rescue ""
    return [in_time, late_status, out_time]
  end

  def self.get_employee_attendance_hash(params)
    date = "1-#{params["advance_search"]["date"]}".to_date
    department = EmployeeDepartment.find_by_id params["advance_search"]["department_id"].to_i
    if department.present? && date.present?
      employee_result = Hash.new
      get_employees_report(department, date)
    end
  end

  private

  def get_employees_report(department)
    employees = department.employees
    start_date = date.beginning_of_month.beginning_of_day
    end_date = date.end_of_month.end_of_day
    employees.each do |employee|

    end
  end
end

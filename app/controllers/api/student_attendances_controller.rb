class Api::StudentAttendancesController < ApiController

  def time_status
    student = Student.find_by_admission_no params[:id]
    employee = Employee.find_by_employee_number params[:id]
    if (employee.present? || student.present?) && (params[:in_time].present? || params[:out_time].present?) && params[:school_id].present?
      student_id = student.id if student.present?
      employee_id = employee.id if employee.present?
      if params[:in_time].present?
        in_time = params[:in_time].to_time
        student_attendance = StudentAttendance.new(:in_time => params[:in_time].to_time, :student_id => student_id, :employee_id => employee_id , :school_id => params[:school_id] )
        if student_attendance.save
          send_in_sms(student_attendance) if student_id.present?
          respond_to do |format|
            msg = { :status => true, :message => "Success!", :data => { :id => student_attendance.id, :in_time => student_attendance.in_time } }
            format.json  { render :json => msg }
          end
        else
          respond_to do |format|
            msg = { :status => false, :message => student_attendance.errors.full_messages }
            format.json  { render :json => msg }
          end
        end
      else
        student_attendance = StudentAttendance.new(:out_time => params[:out_time].to_time, :student_id => student_id, :employee_id => employee_id, :school_id => params[:school_id] )
        if student_attendance.save
          send_out_sms(student_attendance) if student_id.present?
          respond_to do |format|
            msg = { :status => true, :message => "Success!", :data => { :id => student_attendance.id, :out_time => student_attendance.out_time } }
            format.json { render :json => msg }
          end
        else
          respond_to do |format|
            msg = { :status => false, :message => student_attendance.errors.full_messages }
            format.json { render :json => msg }
          end
        end
      end
    else
      respond_to do |format|
        message = !(student.present? || employee.present?) ? "Student/Employee not found" : "parameters missing" rescue nil
        msg = { :status => false, :message => message }
        format.json  { render :json => msg }
      end
    end
  end

  private

  def send_in_sms(student_attendance)
    student = student_attendance.student
    student_attendances = StudentAttendance.find(:all, :conditions => {:student_id => student.id, :in_time => (student_attendance.in_time.beginning_of_day..student_attendance.in_time.end_of_day) , :school_id => params[:school_id] }) rescue nil
    return if student_attendances.map(&:sms_sent).include? true rescue false
    phone_no = student.guardians.map(&:mobile_phone).first rescue nil
    return if phone_no == nil
    student_message = "Dear parent: Entrance for #{student.full_name} was recorded at #{params[:in_time]}"
    school = School.find(params[:school_id]) rescue nil
    attendance_messsage = AttendanceMesssage.find_by_school_id(school.try(:id)) rescue nil
    in_msg = attendance_messsage.try(:in_message).gsub("[[NAME]]", student.full_name).gsub("[[TIME]]", params[:in_time].to_s) rescue student_message
    in_out_attendance_sms_enabled = SmsSetting.find_by_settings_key("InOutAttendanceEnabled").is_enabled? rescue false
    if in_out_attendance_sms_enabled && phone_no.present?
      Delayed::Job.enqueue(SmsManager.new(in_msg,phone_no))
      student_attendance.update_attributes(:sms_sent => true)
    end
  end

  def send_out_sms(student_attendance)
    student = student_attendance.student
    student_attendances = StudentAttendance.find(:all, :conditions => {:student_id => student.id, :out_time => (student_attendance.out_time.beginning_of_day..student_attendance.out_time.end_of_day) , :school_id => params[:school_id] }) rescue nil
    return if student_attendances.map(&:sms_sent).include? true rescue false
    student_message = "Dear parent: Exit for #{student.full_name} was recorded at #{params[:out_time]}"
    school = School.find(params[:school_id]) rescue nil
    attendance_messsage = AttendanceMesssage.find_by_school_id(school.try(:id)) rescue nil
    out_msg = attendance_messsage.try(:out_message).gsub("[[NAME]]", student.full_name).gsub("[[TIME]]", params[:out_time].to_s) rescue student_message
    phone_no = student.guardians.map(&:mobile_phone).first rescue nil
    return if phone_no == nil
    in_out_attendance_sms_enabled = SmsSetting.find_by_settings_key("InOutAttendanceEnabled").is_enabled? rescue false
    if in_out_attendance_sms_enabled && phone_no.present?
      Delayed::Job.enqueue(SmsManager.new(out_msg,phone_no))
      student_attendance.update_attributes(:sms_sent => true)
    end
  end
end

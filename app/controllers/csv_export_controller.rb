class CsvExportController < ApplicationController
  require 'fastercsv'

  def generate_csv
    filename    = "#{params[:csv_report_type]}.csv"
    report_type = params[:csv_report_type]
    report_data = fetch_report_data(report_type,filename)
  end

  private

  def fetch_report_data(report_type,filename)
    
    case report_type

    when "student_advance_search"
      parameters = {:params => params, :locale => I18n.locale}
      csv_export('student','fetch_student_advance_search_result', parameters)
      return
    when "student_attendance_report"
      data = Attendance.fetch_student_attendance_data(params)
    when "day_wise_report"
      data = Attendance.fetch_day_wise_report_data(params)
    when "student_ranking_per_subject"
      data = Exam.fetch_student_ranking_per_subject_data(params)
    when "student_ranking_per_batch"
      data = Exam.fetch_student_ranking_per_batch_data(params)
    when "student_ranking_per_course"
      data = Exam.fetch_student_ranking_per_course_data(params)
    when "student_ranking_per_school"
      parameters = {:params => params, :locale => I18n.locale}
      csv_export('exam', 'fetch_student_ranking_per_school_data', parameters)
      return
    when "student_ranking_per_attendance"
      data = Exam.fetch_student_ranking_per_attendance_data(params)
    when "employee_attendance_report"
      parameters = {:params => params, :locale => I18n.locale}
      csv_export('employee_attendance','fetch_employee_attendance_data',parameters)
      return
    when "employee_advance_search"
      parameters = {:params => params, :locale => I18n.locale}
      csv_export('employee','fetch_employee_advance_search_data', parameters)
      return
    when "subject_wise_report" 
      data = Exam.fetch_subject_wise_data(params)
    when "consolidated_exam_report"
      data = Exam.fetch_consolidated_exam_data(params)
    when "ranking_level"
      data = RankingLevel.fetch_ranking_level_data(params)
    when "finance_transaction"
      data = FinanceTransaction.fetch_finance_transaction_data(params)
    when "finance_payslip"
      data = FinanceTransaction.fetch_finance_payslip_data(params)
    when "employee_payslip"
      data = MonthlyPayslip.fetch_employee_payslip_data(params)
    when "grouped_exam_report" 
      parameters = {:params => params, :locale => I18n.locale}
      csv_export('grouped_exam_report','fetch_grouped_exam_data',parameters)
      return
    when "student_wise_report"
      data = CceReport.fetch_student_wise_report(params)
    when "timetable_data"
      data = Timetable.fetch_timetable_data(params)
    else
      FedenaPlugin::AVAILABLE_MODULES.each do |mod|
        modu = mod[:name].camelize.constantize
        if modu.respond_to?("csv_export_list")
          data = modu.send("csv_export_data",report_type,params) if modu.send("csv_export_list").include?(report_type)
        end
      end
    end
    data = write_csv_report(data) if data.present?  
    send_data(data, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def write_csv_report(data)
  	csv_data = FasterCSV.generate do |csv|
  	  data.each do |data_row|
        csv << data_row
	    end
  	end
  end

  def csv_export(model,method,parameters)
    csv_report=AdditionalReportCsv.find_by_model_name_and_method_name(model,method)
    if csv_report.nil?
      csv_report=AdditionalReportCsv.new(:model_name=>model,:method_name=>method,:parameters=>parameters)
      if csv_report.save
        Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id))
      end
    else
      if csv_report.update_attributes(:parameters=>parameters,:csv_report=>nil)
        Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id))
      end
    end
    flash[:notice]="#{t('csv_report_is_in_queue')}"
    redirect_to :controller => :report, :action=>:csv_reports,:model=>model,:method=>method
  end
end

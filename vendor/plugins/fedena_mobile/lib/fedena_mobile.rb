module FedenaMobile
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_mobile do
      ApplicationController.instance_eval { include FedenaMobile::MobileApplication }
      UserController.instance_eval { include FedenaMobile::MobileUser }
      ReminderController.instance_eval { include FedenaMobile::MobileReminder }
      CalendarController.instance_eval { include FedenaMobile::MobileCalendar }
      TimetableController.instance_eval { include FedenaMobile::MobileTimetable }
      AttendanceReportsController.instance_eval { include FedenaMobile::MobileAttendanceReports }
      EmployeeAttendanceController.instance_eval { include FedenaMobile::MobileEmployeeAttendance }
      AttendancesController.instance_eval { include FedenaMobile::MobileAttendances }
      StudentController.instance_eval { include FedenaMobile::MobileStudent }
    end
  end
end
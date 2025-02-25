module RegistrationCoursesHelper
  def course_pin_system_registered_for_course(course_id)
    course_pin = CoursePin.find_by_course_id(course_id)
    if course_pin.nil?
      return true
    else
      return false if course_pin.is_pin_enabled?
    end
    return true
  end

  def selected_additional_field_ids
    #registration_course = RegistrationCourse.find_by_id(params[:registration_course_id])
    @registration_course.nil? ? Array.new : @registration_course.additional_field_ids.nil? ? Array.new : @registration_course.additional_field_ids
  end
end

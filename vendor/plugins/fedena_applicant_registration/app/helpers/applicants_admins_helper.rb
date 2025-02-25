module ApplicantsAdminsHelper
  def attr_pair(label,value)
    content_tag(:div,:class => :attr_pair) do
      content_tag(:div,label,:class => :attr_label) + content_tag(:div,value,:class => :attr_value)
    end
  end

  def course_pin_system_registered_for_course(course_id)
    course_pin = CoursePin.find_by_course_id(course_id)
    if course_pin.nil?
      return true
    else
      return false if course_pin.is_pin_enabled?
    end
    return true
  end
end
module ApplicantsHelper
  include ApplicantAdditionalFieldsHelper

  def attr_pair(label,value)
    content_tag(:div,:class => :attr_pair) do
      content_tag(:div,label,:class => :attr_label) + content_tag(:div,value,:class => :attr_value)
    end
  end
  
  def generate_input(form,field,options=[])
    if field.field_type=="text"
      text_field_tag "applicant[addl_fields[#{field.id}]]",form.object.addl_fields["#{field.id}"] 
    elsif field.field_type=="belongs_to"
      select_tag "applicant[addl_fields[#{field.id}]]", "<option value=\"\">Select</option>" + options_from_collection_for_select(options,"id","option",form.object.addl_fields["#{field.id}"].to_i)
    elsif field.field_type=="has_many"
      ss = ""
      options.each{|opt| ss += "#{check_box_tag "applicant[addl_fields[#{field.id}]][]",opt.id,form.object.addl_fields["#{field.id}"].to_a.include?("#{opt.id}")} <div class=\"coption\"> #{opt.option}</div>"}
      ss
    end
  end

  def link_to_add_addl_attachment(name, f, association,addl_options={})
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, h("add_addl_attachment(this, \"#{association}\", \"#{escape_javascript(fields)}\")"),{:class=>"add_button_img"}.merge(addl_options))
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

  def latest_subject_name(code)
    Subject.find_all_by_code(code).last.name
  end

end

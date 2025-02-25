module BlogPostsHelper
  def blog_profile
    Blog.find_by_user_id(current_user.id)
  end

  def identity_number(user)
    if user.student?
      user.student_record.admission_no
    elsif user.employee?
      user.employee_record.employee_number
    end
  end

  def can_favourite(blog_post)
    true if blog_post.is_published? and blog_post.is_active? and blog_post.is_deleted == false
  end

  def fetch_profile_pic(user)
    if user.student?
      if user.student_record.photo.file?
        image_tag(user.student_record.photo.url(:original, false))
      else
        image_tag("master_student/profile/default_student.png")
      end
    elsif user.employee?
      if user.employee_record.photo.file?
        image_tag(user.employee_record.photo.url(:original, false))
      else
        image_tag("HR/default_employee.png")
      end
    end
  end
end

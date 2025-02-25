module BlogsHelper
  def blog_profile
    Blog.find_by_user_id(current_user.id)
  end

end

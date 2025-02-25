class BlogComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :blog_post
  validates_presence_of :body,:user_id,:blog_post_id

  named_scope :showable,{ :conditions => { :is_deleted => false },:order => "created_at DESC"}
  


  def is_owner?
    self.user == Authorization.current_user
  end
 
  def is_owner_of_post?(user_in_question)
    blog_post.blog.user == user_in_question
  end
 
end

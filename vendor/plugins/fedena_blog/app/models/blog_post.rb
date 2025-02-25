class BlogPost < ActiveRecord::Base
  belongs_to :blog
  has_many :blog_comments,:dependent => :destroy
  before_destroy :delete_redactors
  after_save :update_redactor
  attr_accessor :redactor_to_update, :redactor_to_delete
  
  validates_presence_of :title,:body

  xss_terminate :except => [:body]

  acts_as_voteable

  named_scope :showable,{:joins=>[:blog], :conditions => { :is_deleted => false, :is_active => true,:is_published => true ,:blogs=>{:is_active=>true}},:order => "created_at DESC"}
  named_scope :showable_to_owner,{:conditions => { :is_deleted => false },:order => "created_at DESC"}
  named_scope :showable_to_blog_admin,{:conditions => { :is_deleted => false },:order => "created_at DESC"}

  def is_owner?
    self.blog.user == Authorization.current_user
  end

  def is_viewable?(user_in_question)
    if self.blog.is_active == true
      if is_published == false
        blog.user == user_in_question ? true : false
      else
        true
      end
    else
      blog.user == user_in_question ? true : false
    end
  end

  def total_likes
    votes_for
  end

  def fetch_first_image(height,width)
    body_content = body
    first_image_start_index = body_content.index('<img ')
    first_image_end_index = (0 .. body_content.length - 1).find_all { |i| body_content[i,1] == '>' }.reject{|i| i < first_image_start_index}.first
    first_image_tag = body_content[first_image_start_index..first_image_end_index]
    previous_height = first_image_tag[/\d+/]
    body_make = body_content.sub(previous_height,"")
    previous_width = body_make[/\d+/]
    first_image_tag = first_image_tag.sub(previous_height.to_s,height.to_s)
    first_image_tag = first_image_tag.sub(previous_width.to_s,width.to_s)
  end

  def update_redactor
    RedactorUpload.update_redactors(self.redactor_to_update,self.redactor_to_delete)
  end

  def delete_redactors
    RedactorUpload.delete_after_create(self.body)
  end
end

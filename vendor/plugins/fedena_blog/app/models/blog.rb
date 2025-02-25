class Blog < ActiveRecord::Base
  belongs_to :user
  has_many :blog_posts,:dependent => :destroy
  validates_presence_of :user_id,:name
  validates_uniqueness_of :user_id

  named_scope :active,{ :conditions => { :is_active => true,:is_published => true }}
  named_scope :banned,{ :conditions => { :is_active => false }}

end

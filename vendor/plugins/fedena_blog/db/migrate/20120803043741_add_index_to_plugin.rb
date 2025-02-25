class AddIndexToPlugin < ActiveRecord::Migration
  def self.up
    add_index :blogs,:school_id, :name => "by_school_id"
    add_index :blog_posts,:school_id, :name => "by_school_id"
    add_index :blog_posts,:blog_id, :name => "by_blog_id"
    add_index :blog_comments,:school_id, :name => "by_school_id"
    add_index :blog_comments,:blog_post_id, :name => "by_blog_post_id"
  end

  def self.down
    remove_index :blogs, :name => "by_school_id"
    remove_index :blog_posts, :name => "by_school_id"
    remove_index :blog_posts, :name => "by_blog_id"
    remove_index :blog_comments, :name => "by_school_id"
    remove_index :blog_comments, :name => "by_blog_post_id"
  end
end

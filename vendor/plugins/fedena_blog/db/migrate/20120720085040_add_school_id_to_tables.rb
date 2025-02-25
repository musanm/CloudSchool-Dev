class AddSchoolIdToTables < ActiveRecord::Migration
  def self.up
    add_column :blogs,:school_id, :integer
    add_column :blog_posts,:school_id, :integer
    add_column :blog_comments,:school_id, :integer
  end

  def self.down
    remove_column :blogs, :school_id
    remove_column :blog_posts, :school_id
    remove_column :blog_comments, :school_id
  end
end

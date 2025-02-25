class CreateBlogComments < ActiveRecord::Migration
  def self.up
    create_table :blog_comments do |t|
      t.text :body
      t.boolean :is_deleted
      t.references :user
      t.references :blog_post

      t.timestamps
    end
  end

  def self.down
    drop_table :blog_comments
  end
end

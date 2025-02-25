class AddOauthFieldsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :google_refresh_token, :string
    add_column :users, :google_access_token, :string
    add_column :users, :google_expired_at, :string
    add_index :users, :google_access_token
  end

  def self.down
    remove_index :users, :google_access_token
    remove_column :users, :google_expired_at
    remove_column :users, :google_access_token
    remove_column :users, :google_refresh_token
  end
end

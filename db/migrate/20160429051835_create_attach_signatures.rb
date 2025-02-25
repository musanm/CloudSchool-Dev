class CreateAttachSignatures < ActiveRecord::Migration
  def self.up
    create_table :attach_signatures do |t|
      t.string :name

      t.string     :photo_file_name
      t.string     :photo_content_type
      t.binary     :photo_data, :limit => 75.kilobytes
      t.timestamps
    end
  end

  def self.down
    drop_table :attach_signatures
  end
end

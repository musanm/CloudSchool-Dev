class GalleryTag < ActiveRecord::Base
  belongs_to :gallery_photo
  belongs_to :member, :polymorphic=> true

  validates_presence_of :gallery_photo_id

end

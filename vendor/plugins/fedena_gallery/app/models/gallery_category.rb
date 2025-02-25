class GalleryCategory < ActiveRecord::Base
  has_many :gallery_photos, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name

end

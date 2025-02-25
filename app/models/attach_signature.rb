class AttachSignature < ActiveRecord::Base
  has_attached_file :photo, 
    :styles => {:original=> "125x125#"},
    :url => "/system/:class/:attachment/:id/:style/:basename.:extension",
    :path => ":rails_root/public/system/:class/:attachment/:id/:style/:basename.:extension"

  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']
  validates_attachment_content_type :photo, :content_type =>VALID_IMAGE_TYPES,
    :message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.photo_file_name.blank? }
  # validates_attachment_presence :photo  
  validates_presence_of :name
  belongs_to :school

  # default_scope :conditions => { :school_id => School.find_by_name(Configuration.get_config_value('InstitutionName')).id }
end

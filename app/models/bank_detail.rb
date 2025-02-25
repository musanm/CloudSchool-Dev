class BankDetail < ActiveRecord::Base
	has_attached_file :avatar, 
    :styles => {:original=> "125x125#"},
    :url => "/system/:class/:attachment/:id/:style/:basename.:extension",
    :path => ":rails_root/public/system/:class/:attachment/:id/:style/:basename.:extension"

	VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']
	validates_attachment_content_type :avatar, :content_type =>VALID_IMAGE_TYPES,
	:message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.avatar_file_name.blank? }
	# validates_attachment_presence :photo  
	validates_presence_of :bank_name,:account_no
	belongs_to :school
end

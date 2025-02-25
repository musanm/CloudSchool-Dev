class Group < ActiveRecord::Base
  belongs_to :user
  has_many :group_members, :dependent => :destroy

  has_many :group_posts, :dependent => :destroy
  has_many :members,:class_name=>"User",:source=>"user",:foreign_key=>"user_id",:through=>:group_members
  has_many :admin_members,:class_name=>"User",:source=>"user",:foreign_key=>"user_id",:through=>:group_members,:conditions=>"`group_members`.is_admin = 1"
  has_many :non_admin_members,:class_name=>"User",:source=>"user",:foreign_key=>"user_id",:through=>:group_members,:conditions=>"`group_members`.is_admin = 0"

  after_create :create_admin
  after_create :notify_recipients

   
  
  validates_presence_of :group_name,:message=>:required
  validates_length_of :group_name, :maximum => 30
  validates_presence_of :members,:message=>:member_required

  has_attached_file :logo,
    :styles => {
    :thumb=> "100x100#",
    :small  => "150x150>"},
    :url => "/images/discussion/:class/:attachment/:id/:style/:basename.:extension",
    :path => ":rails_root/uploads/:class/:attachment/:id_partition/:style/:basename.:extension"

  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']

  validates_attachment_content_type :logo, :content_type =>VALID_IMAGE_TYPES,
    :message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.logo_file_name.blank? }
  validates_attachment_size :logo, :less_than => 512000,\
    :message=>'must be less than 500 KB.',:if=> Proc.new { |p| p.logo_file_name_changed? }


  def create_admin
    user = self.group_members.find_by_user_id(self.user_id)
    if user
      user.update_attributes(:is_admin=>true)
    else
      self.group_members.create(:user_id => self.user_id, :is_admin=>true)
    end
  end

  def self.latest_comments(user,limit)
    GroupPostComment.find(:all,:order=>"`group_post_comments`.id DESC", :conditions=>["group_post_id IN (?)",user.member_groups.collect(&:id)],:limit=>limit)
  end

  def notify_recipients
    unless self.members.blank?
      self.members.each do |member|
        Reminder.create(:sender => self.user_id, :recipient => member.id, :subject=>"#{t('new_group')} - #{self.group_name}",
          :body=>"#{t('congrats')}  <br /> #{t('you_have_been_added_to_this_group')}", :is_read=>false, :is_deleted_by_sender=>false,:is_deleted_by_recipient=>false)
      end
    end
  end

end

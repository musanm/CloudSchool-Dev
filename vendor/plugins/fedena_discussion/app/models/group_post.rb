class GroupPost < ActiveRecord::Base
  belongs_to :group
  belongs_to :user

  has_many :group_post_comments, :dependent => :destroy
  has_many :group_files, :dependent => :destroy

  accepts_nested_attributes_for :group_files
  
  validates_presence_of :post_title, :message =>:cant_be_blank
  validates_length_of :post_title, :maximum => 30
  validates_presence_of :post_body, :message =>:cant_be_blank

  after_create :notify_members

  def can_delete_his_own_post?(user_in_question)
    user_in_question==self.user
  end

  def notify_members
    self.group.members.each do |user|
      unless user.id==self.user_id
        Reminder.create( :sender => self.user_id, :recipient => user.id,
           :subject=>"#{t('group_posts.new_post')} - #{self.post_title} #{t('group_posts.under')} #{self.group.group_name} #{t('group_posts.group')}",
          :body=>self.post_body, :is_read=>false, :is_deleted_by_sender=>false,:is_deleted_by_recipient=>false)
      end
    end
  end
  
end
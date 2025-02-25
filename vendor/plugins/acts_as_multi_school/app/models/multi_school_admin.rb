class MultiSchoolAdmin < AdminUser
  has_one :school_group_user , :foreign_key=>:admin_user_id
  has_one :multi_school_group, :through=>:school_group_user
  validates_presence_of :contact_no
    
end

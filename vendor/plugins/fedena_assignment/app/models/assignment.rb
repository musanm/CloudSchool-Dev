class Assignment < ActiveRecord::Base
  belongs_to :employee
  belongs_to :subject
  has_many :assignment_answers , :dependent=>:destroy
  named_scope :active,:conditions => {:subjects=>{:is_deleted => false}},:joins=>[:subject]

  validates_presence_of :title, :content,:student_list, :duedate

  has_attached_file :attachment ,
    :path => "uploads/:class/:id_partition/:basename.:extension",
    :url=> "/assignments/download_attachment/:id",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]

  validates_attachment_size :attachment, :less_than => 5242880,\
    :message=>'must be less than 5 MB.',:if=> Proc.new { |p| p.attachment_file_name_changed? }

  named_scope :for_student, lambda { |s|{ :conditions => ["FIND_IN_SET(?,student_list)",s],:order=>"duedate asc"} }

  def download_allowed_for user
    return true if user.admin?
    return (user.employee_record.id==self.employee_id) if user.employee?
    return (self.student_list.split(",").include? user.student_record.id.to_s) if user.student?
    false
  end
  def assignment_student_ids
    student_list.split(",").collect{|s| s.to_i}
  end
  def validate
    if self.duedate.to_date < Date.today
      errors.add_to_base :date_cant_be_past_date
      return false
    else
      return true
    end
  end
end

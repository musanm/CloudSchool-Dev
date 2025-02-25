class PollMember < ActiveRecord::Base
  belongs_to :poll_question
  belongs_to :member ,:polymorphic => true
  def poll_member_emails
#     member_emails=[]
    s=(self.member_type.constantize.find self.member_id).instance_eval(stud= self.member_type=="Batch" ? "students.select{|s| (s.is_email_enabled)}" : "employees")
    s.collect(&:email).zip(s.collect(&:first_name))
#     member_emails.flatten.reject{|e| e.empty?}
  end
end

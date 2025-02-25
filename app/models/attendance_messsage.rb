class AttendanceMesssage < ActiveRecord::Base
  
  belongs_to :school

	validates_presence_of :in_message, :out_message, :absent_message, :school_id

	def validate
    errors.add("in_message",": [[NAME]] can't be removed") if !(self.in_message.include? "[[NAME]]")
    errors.add("out_message",": [[NAME]] can't be removed") if !(self.out_message.include? "[[NAME]]")
    errors.add("absent_message",": [[NAME]] can't be removed") if !(self.absent_message.include? "[[NAME]]")
    errors.add("in_message",": [[TIME]] can't be removed") if !(self.in_message.include? "[[TIME]]")
    errors.add("out_message",": [[TIME]] can't be removed") if !(self.out_message.include? "[[TIME]]")
    errors.add("absent_message",": [[TIME]] can't be removed") if !(self.absent_message.include? "[[TIME]]")
    
  end
end

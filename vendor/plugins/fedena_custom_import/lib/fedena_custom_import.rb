require 'dispatcher'

module FedenaCustomImport
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_custom_import do
      ::Guardian.instance_eval { include GuardianExtension }
      ::ExamScore.instance_eval { include ExamScoreExtension }
    end
  end

  module GuardianExtension
    def self.included(base)
          base.instance_eval do
        attr_accessor_with_default :set_immediate_contact,"NOSET"
        attr_accessor :ward_admission_number
        after_save :update_immediate_contact
      end

      def update_immediate_contact
        if set_immediate_contact.present?
          siblings = Student.find_all_by_admission_no_and_sibling_id(set_immediate_contact.split(','),ward_id)
          siblings.each{|sibling| sibling.update_attributes(:immediate_contact_id => id)}
        end
      end
    end
  end

  module ExamScoreExtension
    def self.included(base)
      base.instance_eval do
        before_validation :check_exam_score
      end
      def check_exam_score
        if exam.present? and exam.exam_group.present? and exam.exam_group.exam_type=='Grades'
          self.marks=''
        else
          self.grading_level_id=''
        end
      end
    end
  end
end
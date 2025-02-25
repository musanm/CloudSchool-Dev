class ApplicantGuardian < ActiveRecord::Base
  belongs_to :applicant
  belongs_to :country
  
  validates_presence_of :first_name,:relation

  HUMANIZED_COLUMNS = {:first_name => "#{t('guardian_first_name')}",:relation=>"#{t('guardian_relation')}"}

  def self.human_attribute_name(attribute)
    HUMANIZED_COLUMNS[attribute.to_sym] || super
  end

end

class SchoolDomain < ActiveRecord::Base
  belongs_to :linkable, :polymorphic=>true

  validates_format_of :domain, :with => /(^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[^ .]{2,}(:(6553[0-5]|655[0-2]\d|65[0-4]\d{2}|6[0-4]\d{3}|[1-5]\d{4}|[1-9]\d{0,3}))?$)|(^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(:(6553[0-5]|655[0-2]\d|65[0-4]\d{2}|6[0-4]\d{3}|[1-5]\d{4}|[1-9]\d{0,3}))?$)/ix
  validates_uniqueness_of :domain, :message=>"this domain is not available"

  RESTRICTED_SUB_DOMAINS = open("#{File.dirname(__FILE__)}/../../config/restricted_domains.txt",'r').map {|line| Regexp.new "^#{line.strip}\\.#{MultiSchool.default_domain.gsub(/\./,'\.')}$"}

  def validate
     self.errors.add(:domain,"this domain is reserved") unless RESTRICTED_SUB_DOMAINS.select{|d| d.match self.domain}.blank?
  end

end

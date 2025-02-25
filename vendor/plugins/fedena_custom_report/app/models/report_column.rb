class ReportColumn < ActiveRecord::Base
  belongs_to :report
  before_save :set_default_title
  default_scope  :order=>"position"
  LABEL_NAMES = YAML::load(File.open(File.dirname(__FILE__)+'/../../config/label_names.yml'))
  def set_default_title
    self.title = self.method.titleize if self.title.blank?
  end

  def association_method_object
    model = self.association_method.camelize.singularize
    Kernel.const_get(model)
  end

  def label_name
    label_name = (self.method.to_s.include?("_additional_fields_") ? self.method.to_s.split('_additional_fields_').first.to_sym : self.association_method.nil? ? self.method.to_sym : (self.association_method.to_s + "_" + self.method.to_s).to_sym)
    LABEL_NAMES[label_name]||label_name
  end
end

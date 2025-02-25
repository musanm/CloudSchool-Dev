class FormFieldCheckbox < FormField
  belongs_to :form_template
  has_many :form_field_options, :class_name => 'FormFieldOption', :foreign_key => 'form_field_id'

  accepts_nested_attributes_for :form_field_options
  validates_presence_of :label,:message => t('form_templates.field_title_blank')

  validate :require_two_options

  def require_two_options
    errors.add(:base, t('form_templates.checkbox_minimum_two_options')) if self.form_field_options.size < 2
  end

  def validate
    unless self.new_record?
      if self.form_template.forms.present?
        if errors.empty? and !self.changed.empty?
          errors.add(:base,t('template_modified'))
        end
      end
    end
  end

  def set_initial_field_data
    self.field_type = "checkbox"
    settings = FieldConfig.fields["checkbox"]
    self.label = settings['label']
    self.show_label = settings['show_label']
  end
end

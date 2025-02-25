require 'logger'
class DelayedFormReminderJob
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  attr_accessor :form
  def initialize(form,host,new_recipients = [])
    recipients = []
    log = Logger.new('log/reminder_new.log')    
    log.info(new_recipients)
    @recipients_array = []    
    unless form.is_public
      if new_recipients.present?
        students = User.find_all_by_id(new_recipients,:conditions => {:student => true}).map(&:id)
        employees = new_recipients - students
      end
        
      students = form.students.split(',') unless new_recipients.present?
      employees = form.members.split(',') - students unless new_recipients.present?
      case form.is_parent
      when 0
        Student.find_all_by_user_id(students,:select => "students.*",:joins=>"INNER JOIN `guardians` ON guardians.id = students.immediate_contact_id").collect {
          |x|
          recipients << x.immediate_contact.user_id
        }
      when 1
        recipients << students
      when 2
        Student.find_all_by_user_id(students,:select => "students.*",:joins=>"INNER JOIN `guardians` ON guardians.id = students.immediate_contact_id").collect {
          |x|
          recipients << x.immediate_contact.user_id
        }
        recipients << students
      end
      recipients.delete nil
      @recipients_array << employees
      @recipients_array << recipients
      @recipients_array = @recipients_array.flatten.uniq
    end    
    
    
    form_path = "#{Fedena.hostname}/forms/#{form.id}"
    @form_link = "#{link_to form_path,form_path,:class=>'themed_text'}".html_safe
    @sender = form.user_id
    @form_name = form.name
    @form_is_public = form.is_public
  end

  def perform
    subject = "#{I18n.t('new_form_published', :form_name=>@form_name )}"
    body = "#{subject}<br/>#{@form_link}"
    if(@form_is_public)
      News.create(:title => subject,:content => body, :author_id => @sender)
    else      
      @recipients_array.flatten.compact.each do |r_id|
        Reminder.create(:sender => @sender,:recipient => r_id,:subject => subject,:body => body)
      end
    end    
  end



end
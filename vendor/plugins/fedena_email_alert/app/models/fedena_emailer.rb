class FedenaEmailer < ActionMailer::Base

def emails(sender,recipients, subject, message,hostname,footer,rtl,other_details)
    recipient_emails = (recipients.class == String) ? recipients.gsub(' ','').split(',').compact : recipients.compact
    setup_emails(sender, recipient_emails, subject, message,hostname,footer,rtl,other_details)
end

  protected
  def setup_emails(sender, emails, subject, message,hostname,footer,rtl,other_details)
    @from = sender
    @bcc = emails
    @subject = subject
    @sent_on = Time.now
    @body['message'] = message
    @body['hostname'] = hostname
    @body['footer']=footer || ""
    @body['rtl']=rtl
    @body['email']=emails
    @body['other_details']=other_details
    @content_type="text/html; charset=utf-8"
  end

end
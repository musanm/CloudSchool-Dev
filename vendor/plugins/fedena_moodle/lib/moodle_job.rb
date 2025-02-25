#require File.join(File.dirname(__FILE__),"fedena_moodle.rb")
class MoodleJob

  def initialize(*args)
    opts = args.extract_options!

    @action = opts[:action].to_s
    @usertype = opts[:usertype].to_s if opts[:usertype].present?
    @usertype ||= "student"
    @userid = opts[:id].to_i
    @username = opts[:username].to_s
    @password = opts[:password].to_s
  end

  def perform
    fm = FedenaMoodle::Moodle.new(@action, @userid, @username, @usertype)
    case @action
    when "UpdateAccountPassword"
      fm.password = @password
      fm.change_moodle_account_password
    else     
      fm.send_to_moodle
    end
  end

end

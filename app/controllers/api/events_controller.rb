class Api::EventsController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @user = User.first(:conditions => ["username LIKE BINARY(?)",params[:username]])
    @events = @user.student? ? BatchEvent.find_all_by_batch_id(@user.try(:student_record).try(:batch_id),:select => "events.*",:joins => :event,:conditions => ["DATE(events.start_date) <= ? AND ? <= DATE(events.end_date)",params[:start_date],params[:start_date]]) : EmployeeDepartmentEvent.find_all_by_employee_department_id(@user.try(:employee_record).try(:employee_department_id),:select => "events.*",:joins => :event,:conditions => ["DATE(events.start_date) <= ? AND ? <= DATE(events.end_date)",params[:start_date],params[:start_date]])
    common_events = Event.all(:conditions => ["DATE(start_date) <= ? AND ? <= DATE(end_date) AND is_common = true",params[:start_date],params[:start_date]])
    @events = @events + common_events
    respond_to do |format|
      unless (params[:username].present? and params[:start_date].present?)
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :events }
      end
    end
  end
end

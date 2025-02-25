class ApplicantsAdminsController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def show
    @enabled_courses = RegistrationCourse.find(:all,:order => "courses.course_name",:joins => :course).paginate(:page => params[:page],:per_page => 30)
  end

  def applicants
    search_by =""
    if params[:search].present?
      search_by=params[:search]
    end
    @sort_order=""
    if params[:sort_order].present?
      @sort_order=params[:sort_order]
    end
    @results=Applicant.search_by_order(params[:id], @sort_order, search_by)
    if @sort_order==""
      @results = @results.sort_by { |u1| [u1.status,u1.created_at.to_date] }.reverse if @results.present?
    end
    @applicants = @results.paginate :per_page=>10,:page => params[:page]
    @registration_course = RegistrationCourse.find(params[:id])
  end

  def applicants_pdf
    search_by =""
    if params[:search].present?
      search_by=params[:search]
    end
    @sort_order=""
    if params[:sort_order].present?
      @sort_order=params[:sort_order]
    end
    @results=Applicant.search_by_order(params[:id], @sort_order, search_by)
    if @sort_order==""
      @results = @results.sort_by { |u1| [u1.status,u1.created_at.to_date] }.reverse if @results.present?
    end
    @applicants = @results
    @course = RegistrationCourse.find(params[:id]).course
    render :pdf => 'applicants_pdf'
  end

  def search_by_registration
    @registration_no = params[:search][:registration_no]
    @results = Applicant.search(:reg_no_begins_with => @registration_no)
    @applicants = @results.all.paginate :per_page => 10,:page => params[:page]
    render "applicants/search_results"
  end

  def search_by_registration_pdf
    @registration_no = params[:reg_no]
    @results = Applicant.search(:reg_no_begins_with => @registration_no)
    @applicants = @results.all
    render :pdf => "search_by_registration_pdf"
  end

  def view_applicant
    @elective_name=[]
    @applicant = Applicant.find params[:id]
    @electives=@applicant.subject_ids
    @electives.each do |elec|
      @elective_name<<Subject.find_by_code(elec)
    end
    @addl_values = @applicant.applicant_addl_values
    @additional_details = @applicant.applicant_additional_details
    @financetransaction=FinanceTransaction.find_by_title("Applicant Registration - #{@applicant.reg_no} - #{@applicant.full_name}")
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      if (PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.config_value("enabled_fees").include? "Application Registration")
        online_payment = Payment.find_by_payee_id_and_payee_type(@applicant.id,'Applicant')
        if online_payment.nil?
          @online_transaction_id = @applicant.has_paid == true ? nil : t('fee_not_paid')
        else
          if online_payment.gateway_response.keys.include? :transaction_id
            @online_transaction_id = online_payment.gateway_response[:transaction_id]
          elsif online_payment.gateway_response.include? :x_trans_id
            @online_transaction_id = online_payment.gateway_response[:x_trans_id]
          end
        end
      end
    end
  end

  def admit_applicant
    @applicant = Applicant.find(params[:id])
    @batches = @applicant.registration_course.course.batches.active
    render :update do |page|
      #atmts = Applicant.commit(params[:applicant_id],params[:batch_id],"allot")
      #flash[:notice] = "#{atmts}"
      page.replace_html 'modal-box', :partial => 'allotment_form'
      page << "Modalbox.show($('modal-box'), {title: ''});"
    end
  end

  def allot_applicant
    
    unless params[:allotment][:batch_id].blank?
      applicant = Applicant.find(params[:allotment][:id])
      atmts =  applicant.admit(params[:allotment][:batch_id])
      if atmts.second == 1
        flash[:notice] = "#{atmts.first.join(', ')}"
      else
        flash[:warn_notice] = "#{atmts.first.join(', ')}"
      end
      render :update do |page|
        page.redirect_to :controller => "applicants_admins",:action => "view_applicant",:id => params[:allotment][:id]
      end
    else
      flash[:notice] = t('select_batch_to_allot')
      render :update do |page|
        page.redirect_to :controller => "applicants_admins",:action => "view_applicant",:id => params[:allotment][:id]
      end
    end
  end

  def allot
    allot_to = (params[:allotment].present? and params[:allotment][:batch].present?) ? params[:allotment][:batch]  : ""
    if params[:regid].present? and  params[:commit].present?
      if params[:commit]==t('allot')
        atmts =  Applicant.commit(params[:regid],allot_to,'Allot')
      else
        atmts =  Applicant.commit(params[:regid],allot_to,'Discard')
      end
      flash[:notice] = "#{atmts.first.join(', ')}"
      redirect_to :action=>"applicants",:id=>params[:id],:view=>params[:allotment][:view]
    else
      flash[:notice] = t('no_applicant_selected')
      redirect_to :action=>"applicants",:id=>params[:id]
    end
  end

  def mark_paid
    @applicant = Applicant.find params[:id]
    @applicant.mark_paid
    render(:update) do |p|
      p.reload
    end
  end

  def mark_academically_cleared
    @applicant = Applicant.find params[:id]
    @applicant.mark_academically_cleared
    render(:update) do |p|
      flash[:notice] = t('applicants_admins.applicant_academically_cleared')
      p.reload
    end
  end

end

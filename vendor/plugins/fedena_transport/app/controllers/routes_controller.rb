class RoutesController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  before_filter  :set_precision
  
  def index
    @route = Route.all
  end

  def new
    @route = Route.new
    @main_routes = Route.all( :conditions=>["main_route_id is NULL"])
    @additional_fields = RouteAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC",:include=>"route_additional_field_options")
    @route_additional_fields = @additional_fields.map{|a| @route.route_vehicle_additional_details.build(:route_vehicle_additional_field_id=>a.id)}
  end

  def create
    @route = Route.new(params[:route])
    
      
    @main_routes = Route.all( :conditions=>["main_route_id is NULL"])
    
    respond_to do |format|
      if @route.save
        flash[:notice] = "#{t('flash1')}"
        format.html { redirect_to(@route) }
        format.xml { render :xml => @route, :status => :created, :location => @route }
      else
        @additional_fields = RouteAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC",:include=>"route_additional_field_options")
        @additional_fields.each{|a| @route.route_vehicle_additional_details.build(:route_vehicle_additional_field_id=>a.id) unless @route.route_vehicle_additional_details.collect(&:route_vehicle_additional_field_id).include? a.id}
        @route_additional_details=@route.route_vehicle_additional_details
        @route_additional_details=@route_additional_details.sort_by { |x| x.route_vehicle_additional_field.priority  }
        format.html { render :action => "new" }
        format.xml { render :xml => @route.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @route = Route.find(params[:id])
    @main_routes = Route.all( :conditions=>["main_route_id is NULL"])
    @additional_fields = RouteAdditionalField.find(:all, :conditions=> "is_active = true and type= 'RouteAdditionalField'", :order=>"priority ASC",:include=>"route_additional_field_options")
    @route_additional_details = @route.route_vehicle_additional_details.all(:conditions=>"route_vehicle_additional_fields.is_active = true and route_vehicle_additional_fields.type='RouteAdditionalField'",:include=>"route_vehicle_additional_field")
    @additional_fields.select{|a| @route_additional_details.push(@route.route_vehicle_additional_details.build(:route_vehicle_additional_field_id=>a.id)) unless @route_additional_details.collect(&:route_vehicle_additional_field_id).include?(a.id)}
    @route_additional_details=@route_additional_details.sort_by { |x| x.route_vehicle_additional_field.priority  }
  end

  def update
    @route = Route.find(params[:id])
    @main_routes = Route.all( :conditions=>["main_route_id is NULL"])
    respond_to do |format|
      if @route.update_attributes(params[:route])
        flash[:notice] = "#{t('flash2')}"
        format.html { redirect_to(@route) }
        format.xml { head :ok }
      else
        @additional_fields = RouteAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC")
        @additional_fields.each{|a| @route.route_vehicle_additional_details.build(:route_vehicle_additional_field_id=>a.id) unless @route.route_vehicle_additional_details.collect(&:route_vehicle_additional_field_id).include? a.id}
        @route_additional_details=@route.route_vehicle_additional_details.select{|a| a.route_vehicle_additional_field.is_active==true}
        @route_additional_details=@route_additional_details.sort_by { |x| x.route_vehicle_additional_field.priority  }
        format.html { render :action => "edit" }
        format.xml { render :xml =>@route.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @route = Route.find(params[:id])

    if @route.transports.empty? and @route.vehicles.empty?
      @route.destroy
      flash[:notice] = "#{t('flash3')}"
    else
      flash[:warn_notice] = "<p>#{t('flash4')}</p>" unless @route.transports.empty?
      flash[:warn_notice] = "<p>#{t('flash5')}</p>" unless @route.vehicles.empty?
      
    end
    redirect_to routes_url
  end


  def show
    @route = Route.find(params[:id])
    @additional_details=@route.route_vehicle_additional_details.all(:conditions=>"route_vehicle_additional_fields.is_active = true and route_vehicle_additional_fields.type='RouteAdditionalField'",:include=>"route_vehicle_additional_field")
    @vehicles=Vehicle.paginate(:conditions=>["main_route_id=?",@route.id],:per_page=>20,:page=>params[:page])
    @additional_details=@additional_details.sort_by { |x| x.route_vehicle_additional_field.priority  }
  end


  def sort_by
    sort = params[:sort][:on]
    @routes = Route.search(:status_like=>"#{sort}").paginate(:all,:page=>params[:page],:include=>:tags)
    @count = @routes.total_entries
    render(:update) do |page|
      page.replace_html 'routes', :partial=>'routes'
    end
  end

  def add_additional_details
    @all_details = RouteAdditionalField.find(:all,:order=>"priority ASC")
    @additional_details = RouteAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = RouteAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    @additional_field = RouteAdditionalField.new
    @route_additional_field_option = @additional_field.route_additional_field_options.build
    if request.post?
      priority = 1
      unless @all_details.empty?
        last_priority = @all_details.map{|r| r.priority}.compact.sort.last
        priority = last_priority + 1
      end
      @additional_field = RouteAdditionalField.new(params[:route_additional_field])
      @additional_field.priority = priority
      if @additional_field.save
        flash[:notice] = "Additional field added successfully"
        redirect_to :controller => "routes", :action => "add_additional_details"
      end
    end
  end

  def change_field_priority
    @additional_field = RouteAdditionalField.find(params[:id])
    priority = @additional_field.priority
    @additional_fields = RouteAdditionalField.find(:all, :conditions=>{:is_active=>true}, :order=> "priority ASC").map{|b| b.priority.to_i}
    position = @additional_fields.index(priority)
    if params[:order]=="up"
      prev_field = RouteAdditionalField.find_by_priority(@additional_fields[position - 1])
    else
      prev_field = RouteAdditionalField.find_by_priority(@additional_fields[position + 1])
    end
    @additional_field.update_attributes(:priority=>prev_field.priority)
    prev_field.update_attributes(:priority=>priority.to_i)
    @additional_field = RouteAdditionalField.new
    @additional_details = RouteAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = RouteAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    render(:update) do|page|
      page.replace_html "category-list", :partial=>"additional_fields"
    end
  end

  def edit_additional_details
    @additional_details = RouteAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = RouteAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    @additional_field = RouteAdditionalField.find(params[:id])
    @hostel_additional_field_option = @additional_field.route_additional_field_options
    if request.get?
      render :action=>'add_additional_details'
    else
      if @additional_field.update_attributes(params[:route_additional_field])
        flash[:notice] = "Additional field updated successfully"
        redirect_to :action => "add_additional_details"
      else
        render :action=>"add_additional_details"
      end
    end
  end

  def delete_additional_details
    routes = RouteVehicleAdditionalDetail.find(:all ,:conditions=>"route_vehicle_additional_field_id = #{params[:id]}")
    if routes.blank?
      RouteVehicleAdditionalField.find(params[:id]).destroy
      @additional_details = RouteVehicleAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
      @inactive_additional_details = RouteVehicleAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
      flash[:notice]="Additional field deleted successfully"
      redirect_to :action => "add_additional_details"
    else
      flash[:notice]="Additional field is in use and cannot be deleted"
      redirect_to :action => "add_additional_details"
    end
  end
end

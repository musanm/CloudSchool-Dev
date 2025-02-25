class VehiclesController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
    @vehicle = Vehicle.all
  end

  def new
    @vehicle = Vehicle.new
    @routes = Route.all( :conditions=>["main_route_id is NULL"])
    @additional_fields = VehicleAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC",:include=>"vehicle_additional_field_options")
    @hostel_additional_fields = @additional_fields.map{|a| @vehicle.route_vehicle_additional_details.build(:route_vehicle_additional_field_id=>a.id)}
  end

  def create
    @vehicle = Vehicle.new(params[:vehicle])
    @routes = Route.all( :conditions=>["main_route_id is NULL"])
    respond_to do |format|
      if @vehicle.save
        flash[:notice] = "#{t('flash1')}"
        format.html { redirect_to(@vehicle) }
        format.xml { render :xml => @vehicle, :status => :created, :location => @vehicle }
      else
        @additional_fields = VehicleAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC",:include=>"vehicle_additional_field_options")
        @additional_fields.each{|a| @vehicle.route_vehicle_additional_details.build(:route_vehicle_additional_field_id=>a.id) unless @vehicle.route_vehicle_additional_details.collect(&:route_vehicle_additional_field_id).include? a.id}
        @vehicle_additional_details=@vehicle.route_vehicle_additional_details
        @vehicle_additional_details=@vehicle_additional_details.sort_by{|x| x.route_vehicle_additional_field.priority}
        format.html { render :action => "new" }
        format.xml { render :xml => @vehicle.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @vehicle = Vehicle.find(params[:id])
    @routes = Route.all( :conditions=>["main_route_id is NULL"])
    @additional_fields = VehicleAdditionalField.find(:all, :conditions=> "is_active = true and type= 'VehicleAdditionalField'", :order=>"priority ASC",:include=>"vehicle_additional_field_options")
    @vehicle_additional_details = @vehicle.route_vehicle_additional_details.all(:conditions=>"route_vehicle_additional_fields.is_active = true and route_vehicle_additional_fields.type='VehicleAdditionalField'",:include=>"route_vehicle_additional_field")
    @additional_fields.select{|a| @vehicle_additional_details.push(@vehicle.route_vehicle_additional_details.build(:route_vehicle_additional_field_id=>a.id)) unless @vehicle_additional_details.collect(&:route_vehicle_additional_field_id).include?(a.id)}
    @vehicle_additional_details=@vehicle_additional_details.sort_by{|x| x.route_vehicle_additional_field.priority}
  end
    
  def update
    @vehicle = Vehicle.find(params[:id])
    @routes = Route.all( :conditions=>["main_route_id is NULL"])
    respond_to do |format|
      if @vehicle.update_attributes(params[:vehicle])
        flash[:notice] = "#{t('flash2')}"
        format.html { redirect_to(@vehicle) }
      else
        @additional_fields = VehicleAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC")
        @vehicle_additional_details = @vehicle.route_vehicle_additional_details.all(:conditions=>"route_vehicle_additional_fields.is_active = true and route_vehicle_additional_fields.type='VehicleAdditionalField'",:include=>"route_vehicle_additional_field")
        @additional_fields.each{|a| @vehicle.route_vehicle_additional_details.build(:route_vehicle_additional_field_id=>a.id) unless @vehicle.route_vehicle_additional_details.collect(&:route_vehicle_additional_field_id).include? a.id}
        @vehicle_additional_details=@vehicle.route_vehicle_additional_details.select{|a| a.route_vehicle_additional_field.is_active==true}
        @vehicle_additional_details=@vehicle_additional_details.sort_by{|x| x.route_vehicle_additional_field.priority}
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @vehicle = Vehicle.find(params[:id])
    if @vehicle.destroy
      flash[:notice]= "#{t('flash3')}"
    else
      flash[:warn_notice]="<p>#{@vehicle.errors.full_messages}</p>"
    end
    respond_to do |format|
      format.html { redirect_to(vehicles_url) }
      format.xml { head :ok }
    end
  end

  def show
    @vehicle = Vehicle.find(params[:id])
    @additional_details=@vehicle.route_vehicle_additional_details.all(:conditions=>"route_vehicle_additional_fields.is_active = true and route_vehicle_additional_fields.type='VehicleAdditionalField'",:include=>"route_vehicle_additional_field")
    @users=Transport.paginate(:conditions=>["vehicle_id=?",@vehicle.id],:per_page=>20,:page=>params[:page])
    @additional_details=@additional_details.sort_by{|x| x.route_vehicle_additional_field.priority}
    
  end
  def sort_by
    sort = params[:sort][:on]
    @room_details = Vehicle.search(:status_like=>"#{sort}").paginate(:all,:page=>params[:page],:include=>:tags)
    @count = @room_details.total_entries
    render(:update) do |page|
      page.replace_html 'vehicles', :partial=>'vehicles'
    end
  end

  def add_additional_details
    @all_details = VehicleAdditionalField.find(:all,:order=>"priority ASC")
    @additional_details = VehicleAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = VehicleAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    @additional_field = VehicleAdditionalField.new
    @vehicle_additional_field_option = @additional_field.vehicle_additional_field_options.build
    if request.post?
      priority = 1
      unless @all_details.empty?
        last_priority = @all_details.map{|r| r.priority}.compact.sort.last
        priority = last_priority + 1
      end
      @additional_field = VehicleAdditionalField.new(params[:vehicle_additional_field])
      @additional_field.priority = priority
      if @additional_field.save
        flash[:notice] = "Additional field added successfully"
        redirect_to :controller => "vehicles", :action => "add_additional_details"
      end
    end
  end

  def change_field_priority
    @additional_field = VehicleAdditionalField.find(params[:id])
    priority = @additional_field.priority
    @additional_fields = VehicleAdditionalField.find(:all, :conditions=>{:is_active=>true}, :order=> "priority ASC").map{|b| b.priority.to_i}
    position = @additional_fields.index(priority)
    if params[:order]=="up"
      prev_field = VehicleAdditionalField.find_by_priority(@additional_fields[position - 1])
    else
      prev_field = VehicleAdditionalField.find_by_priority(@additional_fields[position + 1])
    end
    @additional_field.update_attributes(:priority=>prev_field.priority)
    prev_field.update_attributes(:priority=>priority.to_i)
    @additional_field = VehicleAdditionalField.new
    @additional_details = VehicleAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = VehicleAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    render(:update) do|page|
      page.replace_html "category-list", :partial=>"additional_fields"
    end
  end

  def edit_additional_details
    @additional_details = VehicleAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = VehicleAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    @additional_field = VehicleAdditionalField.find(params[:id])
    @room_additional_field_option = @additional_field.vehicle_additional_field_options
    if request.get?
      render :action=>'add_additional_details'
    else
      if @additional_field.update_attributes(params[:vehicle_additional_field])
        flash[:notice] = "Additional field updated successfully"
        redirect_to :action => "add_additional_details"
      else
        render :action=>"add_additional_details"
      end
    end
  end

  def delete_additional_details
    vehicles = RouteVehicleAdditionalDetail.find(:all ,:conditions=>"route_vehicle_additional_field_id = #{params[:id]}")
    if vehicles.blank?
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
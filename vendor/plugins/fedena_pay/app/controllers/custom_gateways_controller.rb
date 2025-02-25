class CustomGatewaysController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
    @gateways = CustomGateway.own_gateways
    #@own_gateways = CustomGateway.own_gateways
    @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
  end

  def new
    @gateway = CustomGateway.new
  end

  def create
    @gateway = CustomGateway.new(params[:custom_gateway])
    if @gateway.save
      flash[:notice] = "#{t('gateway_creation_msg')}"
      redirect_to custom_gateways_path
    else
      render :new
    end
  end

  def edit
    @gateway = CustomGateway.find(params[:id]).remodel_params_hash
  end

  def update
    @gateway = CustomGateway.find(params[:id])
    if @gateway.update_attributes(params[:custom_gateway])
      flash[:notice] = "#{t('gateway_updation_msg')}"
      redirect_to custom_gateways_path
    else
      render :edit
    end
  end

  def destroy
    @gateway = CustomGateway.find(params[:id])
    @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
    unless @active_gateway == @gateway.id
      @gateway.update_attributes(:is_deleted=>true)
      flash[:notice]="#{t('gateway_deletion_msg')}"
    else
      flash[:notice]="#{t('cannot_delete_gateway')}"
    end
    redirect_to custom_gateways_path
  end

end

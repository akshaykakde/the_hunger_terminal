class AdminDashboardController < ApplicationController

  before_action :load_details, only: [:place_orders, :forward_orders, :confirm_orders]
  before_action :authenticate_user!
  before_action :load_terminal, only: [:place_orders, :forward_orders]

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Vendor wise Orders", :admin_dashboard_index_path, only: [:index]
  # add_breadcrumb "Employee wise Orders", :reports_employees_daily_order_detail_path, only: [ :input_terminal_extra_charges]
  add_breadcrumb "Add Terminal Extra Chrges", :admin_dashboard_input_terminal_extra_charges_path, only: [:input_terminal_extra_charges]

  def index
    authorize! :index, :order_management
    @res = Terminal.daily_terminals(current_user.company_id)
    # the overall status of all orders of each terminal
    generate_no_record_found_error(@res)
    @placed = []
    @confirmed = []
    @res.each do |terminal|
      status = Order.get_all_orders_status(terminal.id)
      @placed << status.all? { |status| status == "placed" }
      @confirmed << status.all? { |status| status == "confirmed" }
    end
  end

  def order_detail
    authorize! :order_detail, :order_management
  	@order_details = Order.daily_orders(params[:terminal_id], current_user.company_id)  
  end

  def forward_orders
    authorize! :forward_orders, :order_management
    
    respond_to do |format|
      format.html { redirect_to admin_dashboard_index_path}
      format.js {}
    end
  end  

  def payment
    @company = Company.find(current_user.company_id)
    @terminals = @company.terminals.all.order(:name)
    add_breadcrumb "Running balance report"
  end

  def pay
    @terminal = Terminal.find params[:terminal_id]
  end

  def place_orders
    authorize! :place_orders, :order_management
    unless @terminal.email.blank?
      SendOrderMailJob.perform_now(params[:terminal_id], @orders, params[:message], current_user.company_id)
      flash[:notice] = "email sent successfully"
    end
    # @orders = Order.menu_details(params[:terminal_id], current_user.company_id)
    if @orders.any?
      Order.update_status(@order_details)
    end
  end

  def confirm_orders
    authorize! :confirm_orders, :order_management
    Terminal.update_current_amount_of_terminal(params[:terminal_id], current_user.company_id, params[:todays_order_total])
    Order.confirm_all_placed_orders(params[:terminal_id], current_user.company_id, @order_details)
    flash[:notice] = "all orders confirmed"
    redirect_to admin_dashboard_index_path
  end 

  def input_terminal_extra_charges
    @todays_terminals = Terminal.all_terminals_todays_orders_report(current_user.company_id)
    # byebug
  end

  def save_terminal_extra_charges
    company_id = current_user.company_id
    params["terminal_extra_charges_form"].each do  |terminal_info|
      terminal_id = terminal_info["terminal_id"].to_i
      daily_extra_charge = terminal_info["daily_extra_charge"].to_i
      if TerminalExtraCharge.exists?(terminal_id: terminal_id, company_id: company_id, date: Time.zone.today)
        flash[:notice] = "Already updated !!"
        redirect_back(fallback_location: root_path)
        return
      elsif TerminalExtraCharge.create!(terminal_id: terminal_id, daily_extra_charge: daily_extra_charge, company_id: company_id, date: Time.zone.today)
        flash[:success] = "Successfully updated!!"
      else
        flash[:error] = "Error occurred!! Please try again!!"
        redirect_to "input_terminal_extra_charges"
        return
      end
    end
  end

  def destroy
    order_detail = OrderDetail.find(params[:id])
    order = Order.find(order_detail.order_id)
    order_detail.destroy
    if order.order_details.any? == false
      order.destroy
    end
    redirect_to admin_dashboard_index_path
  end

  private

  def load_details
    @order_details = Order.daily_orders(params[:terminal_id], current_user.company_id)
    @orders = Order.menu_details(params[:terminal_id], current_user.company_id).as_json
  end


  def load_terminal
    @terminal = Terminal.find(params[:terminal_id])
  end

  def generate_no_record_found_error(records)
    if records.empty?
      flash[:error] = "No record found"
    end
  end
end


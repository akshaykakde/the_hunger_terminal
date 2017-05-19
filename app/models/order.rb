class Order < ApplicationRecord

  validate :can_be_created?, :is_empty?, on: :create
  validates :date, :total_cost, :user, :company,:status, :terminal, presence: true
  validates :total_cost, numericality: { greater_than: 0 }
  validates :status, inclusion: {in: ORDER_STATUS}
  validates :user_id, uniqueness: { scope: :date }
  # :can_be_created?, 
  # validate :can_be_updated?, on: :update  
  # validates :user_id, uniqueness: { scope: :date }
  # validate :valid_date?, on: :create

  belongs_to :user
  belongs_to :company
  belongs_to :terminal
  has_many :order_details, dependent: :destroy, inverse_of: :order,autosave: true

  # after_initialize :set_date
  before_validation :set_discount

  accepts_nested_attributes_for :order_details, allow_destroy: true, reject_if: proc { |attributes| attributes['quantity'].to_i == 0 }

  def self.daily_orders(terminal_id, company_id)
    self.
      joins(:user,:order_details).
      where('orders.date' => Time.zone.today,'orders.terminal_id' => terminal_id,
        'orders.company_id' => company_id).
      select('orders.id','users.name AS emp_name',
        'order_details.menu_item_name AS menu, quantity', 'order_details.id as detail_id', 'orders.status').
      order("users.name ASC")
      # 'orders.status' => ['pending','review','placed']
  end

  #complete the below functionality: for getting all the terminal specific today's orders
  def self.get_terminal_specific_orders(terminal_id,company_id)
    self.
      joins(:user).
      where('orders.date' => Time.zone.today, 'orders.terminal_id' => terminal_id,
        'orders.company_id' => company_id).
      select('orders.id', 'orders.total_cost','users.id')
  end

  def self.employees_daily_order_detail_report(company_id)
    self.
      joins(:user,:order_details,:terminal).
      where('orders.date' => Time.zone.today, 'orders.company_id' => company_id).
      group('orders.id,orders.terminal_id,users.name,order_details.menu_item_name,order_details.quantity,terminals.name').
      select('orders.id','users.name AS emp_name',
        'order_details.menu_item_name AS menu, quantity,terminals.name AS vendor').
      order("terminals.name ASC")
  end

  def self.all_terminals_daily_report(c_id)
    self.
      joins(:terminal, :order_details).
      where('orders.date' => Time.zone.today, 'orders.company_id' => c_id, 'orders.status' => 'confirmed').
      group('orders.terminal_id','terminals.id','order_details.menu_item_name').
      select('terminals.name, sum(orders.total_cost) AS total, order_details.menu_item_name,
       sum(order_details.quantity) AS quantity')
  end

  def self.menu_details(terminal_id, company_id)
    self.
      joins(:order_details).
      where('orders.date'=> Time.zone.today,'orders.terminal_id' => terminal_id,
        'orders.company_id'=> company_id, 'orders.status' => ['pending', 'review']).
      group('order_details.menu_item_name').
      select('order_details.menu_item_name AS menu, sum(quantity) AS quantity')
  end

  def self.update_status(order_details)
    # @orders = Order.where('orders.date' => Time.zone.today, 
    #   'orders.terminal_id' => t_id, 'orders.company_id' => c_id)
    order_ids = order_details.pluck(:id).uniq
    orders = Order.where(:id => order_ids)
    orders.update_all(:status => "placed")
  end

  def self.confirm_all_placed_orders(terminal_id, company_id, order_details)
    order_ids = order_details.pluck(:id).uniq
    orders = Order.where(:id => order_ids)
    orders.update_all(:status => "confirmed")
    @employees =  orders.
                    joins(:user).
                    pluck('users.email AS email, users.name AS name')
    @employees.each do |employee|
      OrderMailer.send_mail_to_employees(employee).deliver_later
    end
  end

  def self.get_all_orders_status(terminal_id)
    where(date: Time.zone.today, terminal_id: terminal_id).pluck(:status)
  end
  
  private

    # needs to be evaluated
    def valid_date?
      errors.add(:date, "can't be in the past") if !date.blank? and date < Time.zone.today
    end

    def can_be_created?
      current_time = Time.zone.now.strftime('%H:%M:%S')
      start_time = self.company.start_ordering_at.strftime('%H:%M:%S')
      # self.company.start_ordering_at
      end_time = self.company.end_ordering_at.strftime('%H:%M:%S')
      # self.company.end_ordering_at
      day = Time.zone.today.wday
      # if day%7 != 0 and day%7 != 6
      if !(current_time >= start_time and current_time <= end_time)
        errors.add(:base,"order cannot be created or updated after #{end_time}")
      end
      # else
      #   errors.add(:base,"order cannot be created on saturday and sunday")
      # end
    end

    # def set_date
    #   self.date = Time.zone.today
    # end

    def is_empty?
      if self.order_details.any? == false
        errors.add(:base,"order shold have minimum one menu item")
      end
    end

    def set_discount
      a = self.company.subsidy
      b = self.total_cost
      self.discount = [a, (a*b)/100].min
      self.status = 'pending'
    end 
end
 

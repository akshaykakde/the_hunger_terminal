class OrderMailer < ApplicationMailer

  def send_mail_to_terminal(terminal_id, terminal_orders, message, company_id)
    @terminal = Terminal.find(terminal_id)
    @company = Company.find(company_id)
    @orders = terminal_orders
    @message = message
    mail(to: @terminal.email, subject: 'orders for today')
  end

  def send_mail_to_employees(employee)
    email = employee[0]
    @name = employee[1]
    mail(to: email, subject: 'status of order')
  end

  def send_place_order_reminder(employee, end_time)
    @end_time = end_time
    email = employee[0]
    @name = employee[1]
    mail(to:email, subject: 'place order soon')
  end

end

class Vietnq1::OrderService
  def initialize(order_repo, inventory_repo, payment_service, notification_service)
    @order_repo = order_repo
    @inventory_repo = inventory_repo
    @payment_service = payment_service
    @notification_service = notification_service
  end

  def process_order(order_id, user_id)
    raise ArgumentError, 'Invalid order_id or user_id' if order_id <= 0 || user_id <= 0

    order = @order_repo.get_order_by_id(order_id)
    return { message: 'Order not found' } unless order

    raise StandardError, 'Unauthorized access to order' if order[:user_id] != user_id

    case order[:status]
    when 'paid'
      { message: 'Order already paid' }
    when 'canceled'
      { message: 'Order has been canceled' }
    when 'processing'
      unless @inventory_repo.check_stock(order[:product_id], order[:quantity])
        @order_repo.update_order_status(order_id, 'canceled')
        @notification_service.send(user_id, 'Order canceled due to insufficient stock.')
        return { message: 'Order canceled due to insufficient stock' }
      end
    when 'pending'
      payment_result = @payment_service.charge(order[:total])
      if payment_result[:status] == 'success'
        @order_repo.update_order_status(order_id, 'paid')
        @notification_service.send(user_id, 'Payment successful. Your order is being processed.')
        { message: 'Payment successful', order_id: order_id }
      else
        { message: 'Payment failed', error: payment_result[:error] }
      end
    else
      { message: 'Unhandled order status' }
    end
  end
end

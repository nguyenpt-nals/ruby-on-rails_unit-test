class APIException < StandardError; end

class DatabaseException < StandardError; end

class OrderProcessingService
  def initialize(api_client)
    @api_client = api_client
  end

  def process_orders(user_id)
    orders = Order.where(user_id: user_id)
    return false if orders.empty?

    orders.each do |order|
      process_order(order, user_id)
      update_priority(order)
      save_order(order)
    end
    true
  rescue StandardError
    false
  end

  private

  def process_order(order, user_id)
    case order.type
    when "A"
      process_type_a(order, user_id)
    when "B"
      process_type_b(order)
    when "C"
      process_type_c(order)
    else
      order.update(status: :unknown_type)
    end
  end

  def process_type_a(order, user_id)
    begin
      csv_generate(order, user_id)
      order.update(status: :exported)
    rescue StandardError
      order.update(status: :export_failed)
    end
  end

  def process_type_b(order)
    begin
      response = @api_client.call_api(order.id)
      if response.status == "success"
        if response.data >= 50 && order.amount < 100
          order.update(status: :processed)
        elsif response.data < 50 || order.flag
          order.update(status: :pending)
        else
          order.update(status: :error)
        end
      else
        order.update(status: :api_error)
      end
    rescue APIException
      order.update(status: :api_failure)
    end
  end

  def process_type_c(order)
    order.update(status: order.flag ? :completed : :in_progress)
  end

  def csv_generate(order, user_id)
    csv_file_path = "orders_type_A_#{user_id}_#{Time.now.to_i}.csv"

    CSV.open(csv_file_path, "w") do |csv|
      csv << ["ID", "Type", "Amount", "Flag", "Status", "Priority"]
      csv << [order.id, order.type, order.amount, order.flag, order.status, order.priority]
      csv << ["", "", "", "", "Note", "High value order"] if order.amount > 150
    end
  end

  def update_priority(order)
    order.update(priority: order.amount > 200 ? :high : :low)
  end

  def save_order(order)
    order.save!
  rescue DatabaseException
    order.update(status: :db_error)
  end
end

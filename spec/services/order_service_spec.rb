require "rails_helper"

RSpec.describe OrderService do
  let(:order_repo) { double("OrderRepository") }
  let(:inventory_repo) { double("InventoryRepository") }
  let(:payment_service) { double("PaymentService") }
  let(:notification_service) { double("NotificationService") }
  let(:service) { described_class.new(order_repo, inventory_repo, payment_service, notification_service) }

  describe "#process_order" do
    let(:order_id) { 1 }
    let(:user_id) { 1 }

    it "should raise ArgumentError when order_id is invalid" do
      invalid_order_id = -1

      expect { service.process_order(invalid_order_id, user_id) }
        .to raise_error(ArgumentError, "Invalid order_id or user_id")
    end

    it "should raise ArgumentError when user_id is invalid" do
      invalid_user_id = 0

      expect { service.process_order(order_id, invalid_user_id) }
        .to raise_error(ArgumentError, "Invalid order_id or user_id")
    end

    it "should return order not found message when order does not exist" do
      allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(nil)

      result = service.process_order(order_id, user_id)

      expect(result).to eq({ message: "Order not found" })
    end

    it "should raise StandardError when user_id does not match order owner" do
      order = { user_id: 2, status: "pending", total: 100 }
      allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)

      expect { service.process_order(order_id, user_id) }
        .to raise_error(StandardError, "Unauthorized access to order")
    end

    it "should return already paid message when order status is paid" do
      order = { user_id: 1, status: "paid" }
      allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)

      result = service.process_order(order_id, user_id)

      expect(result).to eq({ message: "Order already paid" })
    end

    it "should return canceled message when order status is canceled" do
      order = { user_id: 1, status: "canceled" }
      allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)

      result = service.process_order(order_id, user_id)

      expect(result).to eq({ message: "Order has been canceled" })
    end

    it "should cancel order when processing and stock is insufficient" do
      order = { user_id: 1, status: "processing", product_id: 10, quantity: 5 }
      allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)
      allow(inventory_repo).to receive(:check_stock).with(10, 5).and_return(false)
      allow(order_repo).to receive(:update_order_status).with(order_id, "canceled")
      allow(notification_service).to receive(:send).with(user_id, "Order canceled due to insufficient stock.")

      result = service.process_order(order_id, user_id)

      expect(result).to eq({ message: "Order canceled due to insufficient stock" })
    end

    it "should process order successfully when processing and stock is sufficient" do
      order = { user_id: 1, status: "processing", product_id: 10, quantity: 5 }
      allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)
      allow(inventory_repo).to receive(:check_stock).with(10, 5).and_return(true)

      result = service.process_order(order_id, user_id)

      expect(result).to be_nil
    end

    it "should return payment successful when pending order payment succeeds" do
      order = { user_id: 1, status: "pending", total: 100 }
      allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)
      allow(payment_service).to receive(:charge).with(100).and_return({ status: "success" })
      allow(order_repo).to receive(:update_order_status).with(order_id, "paid")
      allow(notification_service).to receive(:send).with(user_id, "Payment successful. Your order is being processed.")

      result = service.process_order(order_id, user_id)

      expect(result).to eq({ message: "Payment successful", order_id: order_id })
    end

    it "should return payment failed when pending order payment fails" do
      order = { user_id: 1, status: "pending", total: 100 }
      allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)
      allow(payment_service).to receive(:charge).with(100).and_return({ status: "failed", error: "Insufficient funds" })

      result = service.process_order(order_id, user_id)

      expect(result).to eq({ message: "Payment failed", error: "Insufficient funds" })
    end

    it "should return unhandled status message when order status is unknown" do
      order = { user_id: 1, status: "unknown" }
      allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)

      result = service.process_order(order_id, user_id)

      expect(result).to eq({ message: "Unhandled order status" })
    end
  end
end

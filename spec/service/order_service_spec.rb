require 'rails_helper'

RSpec.describe OrderService do
  let(:order_repo) { double('OrderRepo') }
  let(:inventory_repo) { double('InventoryRepo') }
  let(:payment_service) { double('PaymentService') }
  let(:notification_service) { double('NotificationService') }

  let(:order_service) do
    OrderService.new(order_repo, inventory_repo, payment_service, notification_service)
  end

  describe '#process_order' do
    it 'should raises an ArgumentError error for invalid order_id' do
      expect { order_service.process_order(0, 1) }.to raise_error(ArgumentError, 'Invalid order_id or user_id')
    end

    it 'should raises an ArgumentError error for invalid user_id' do
      expect { order_service.process_order(1, 0) }.to raise_error(ArgumentError, 'Invalid order_id or user_id')
    end

    it 'should returns a message that order is not found when order is not found' do
      allow(order_repo).to receive(:get_order_by_id).and_return(nil)
      result = order_service.process_order(1, 1)
      expect(result).to eq({ message: 'Order not found' })
    end

    it 'should raises an error for unauthorized access when user does not have access to the order' do
      order = { user_id: 2, status: 'pending' }
      allow(order_repo).to receive(:get_order_by_id).and_return(order)
      expect { order_service.process_order(1, 1) }.to raise_error(StandardError, 'Unauthorized access to order')
    end

    it 'should returns a message that the order is already paid when order status is already paid' do
      order = { user_id: 1, status: 'paid', product_id: 1, quantity: 1, total: 100 }
      allow(order_repo).to receive(:get_order_by_id).and_return(order)
      result = order_service.process_order(1, 1)
      expect(result).to eq({ message: 'Order already paid' })
    end

    it 'should returns a message that the order has been canceled when order status is canceled' do
      order = { user_id: 1, status: 'canceled', product_id: 1, quantity: 1, total: 100 }
      allow(order_repo).to receive(:get_order_by_id).and_return(order)
      result = order_service.process_order(1, 1)
      expect(result).to eq({ message: 'Order has been canceled' })
    end

    it 'should cancels the order if there is insufficient stock when order status is processing' do
      order = { user_id: 1, status: 'processing', product_id: 1, quantity: 1, total: 100 }
      allow(order_repo).to receive(:get_order_by_id).and_return(order)
      allow(inventory_repo).to receive(:check_stock).and_return(false)
      allow(order_repo).to receive(:update_order_status)
      allow(notification_service).to receive(:send)
      
      result = order_service.process_order(1, 1)
      expect(result).to eq({ message: 'Order canceled due to insufficient stock' })
      expect(order_repo).to have_received(:update_order_status).with(1, 'canceled')
      expect(notification_service).to have_received(:send).with(1, 'Order canceled due to insufficient stock.')
    end

    it 'should processes payment successfully when order status is pending' do
      order = { user_id: 1, status: 'pending', product_id: 1, quantity: 1, total: 100 }
      allow(order_repo).to receive(:get_order_by_id).and_return(order)
      allow(payment_service).to receive(:charge).and_return({ status: 'success' })
      allow(order_repo).to receive(:update_order_status)
      allow(notification_service).to receive(:send)
      
      result = order_service.process_order(1, 1)
      expect(result).to eq({ message: 'Payment successful', order_id: 1 })
      expect(order_repo).to have_received(:update_order_status).with(1, 'paid')
      expect(notification_service).to have_received(:send).with(1, 'Payment successful. Your order is being processed.')
    end

    it 'should handles payment failure when order status is pending' do
      order = { user_id: 1, status: 'pending', product_id: 1, quantity: 1, total: 100 }
      allow(order_repo).to receive(:get_order_by_id).and_return(order)
      allow(payment_service).to receive(:charge).and_return({ status: 'failure', error: 'Insufficient funds' })
      
      result = order_service.process_order(1, 1)
      expect(result).to eq({ message: 'Payment failed', error: 'Insufficient funds' })
    end

    it 'should returns a message for unhandled order status when order status is unhandled' do
      order = { user_id: 1, status: 'unknown', product_id: 1, quantity: 1, total: 100 }
      allow(order_repo).to receive(:get_order_by_id).and_return(order)
      
      result = order_service.process_order(1, 1)
      expect(result).to eq({ message: 'Unhandled order status' })
    end
  end
end

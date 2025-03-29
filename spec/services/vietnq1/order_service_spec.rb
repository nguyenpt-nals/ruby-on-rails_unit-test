require 'rails_helper'

RSpec.describe Vietnq1::OrderService do
  let(:order_repo) { double('OrderRepository') }
  let(:inventory_repo) { double('InventoryRepository') }
  let(:payment_service) { double('PaymentService') }
  let(:notification_service) { double('NotificationService') }
  let(:service) do
    Vietnq1::OrderService.new(order_repo, inventory_repo, payment_service, notification_service)
  end
  let(:order_id) { 1 }
  let(:user_id) { 1 }
  let(:order) { { id: order_id, user_id: user_id, product_id: 10, quantity: 2, total: 100, status: 'pending' } }

  describe '#process_order' do
    context 'with invalid arguments' do
      it 'raises ArgumentError for invalid order_id' do
        expect { service.process_order(-1, user_id) }.to raise_error(ArgumentError, 'Invalid order_id or user_id')
      end

      it 'raises ArgumentError for invalid user_id' do
        expect { service.process_order(order_id, 0) }.to raise_error(ArgumentError, 'Invalid order_id or user_id')
      end
    end

    context 'when order is not found' do
      before do
        allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(nil)
      end

      it 'returns order not found message' do
        result = service.process_order(order_id, user_id)
        expect(result).to eq({ message: 'Order not found' })
      end
    end

    context 'when user is unauthorized' do
      let(:order) { { id: order_id, user_id: 2, status: 'pending' } }

      before do
        allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)
      end

      it 'raises StandardError for unauthorized access' do
        expect { service.process_order(order_id, user_id) }.to raise_error(StandardError, 'Unauthorized access to order')
      end
    end

    context 'when order status is paid' do
      let(:order) { { id: order_id, user_id: user_id, status: 'paid' } }

      before do
        allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)
      end

      it 'returns already paid message' do
        result = service.process_order(order_id, user_id)
        expect(result).to eq({ message: 'Order already paid' })
      end
    end

    context 'when order status is canceled' do
      let(:order) { { id: order_id, user_id: user_id, status: 'canceled' } }

      before do
        allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)
      end

      it 'returns canceled message' do
        result = service.process_order(order_id, user_id)
        expect(result).to eq({ message: 'Order has been canceled' })
      end
    end

    context 'when order status is processing' do
      let(:order) { { id: order_id, user_id: user_id, product_id: 10, quantity: 2, status: 'processing' } }

      before do
        allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)
      end

      context 'with sufficient stock' do
        before do
          allow(inventory_repo).to receive(:check_stock).with(10, 2).and_return(true)
        end

        it 'does not cancel order' do
          service.process_order(order_id, user_id)
          expect(order_repo).not_to receive(:update_order_status)
        end
      end

      context 'with insufficient stock' do
        before do
          allow(inventory_repo).to receive(:check_stock).with(10, 2).and_return(false)
          allow(order_repo).to receive(:update_order_status)
          allow(notification_service).to receive(:send)
        end

        it 'cancels order and sends notification' do
          result = service.process_order(order_id, user_id)
          expect(order_repo).to have_received(:update_order_status).with(order_id, 'canceled')
          expect(notification_service).to have_received(:send).with(user_id, 'Order canceled due to insufficient stock.')
          expect(result).to eq({ message: 'Order canceled due to insufficient stock' })
        end
      end
    end

    context 'when order status is pending' do
      let(:order) { { id: order_id, user_id: user_id, total: 100, status: 'pending' } }

      before do
        allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)
        allow(order_repo).to receive(:update_order_status)
        allow(notification_service).to receive(:send)
      end

      context 'with successful payment' do
        before do
          allow(payment_service).to receive(:charge).with(100).and_return({ status: 'success' })
        end

        it 'updates order status to paid and sends notification' do
          result = service.process_order(order_id, user_id)
          expect(order_repo).to have_received(:update_order_status).with(order_id, 'paid')
          expect(notification_service).to have_received(:send).with(user_id, 'Payment successful. Your order is being processed.')
          expect(result).to eq({ message: 'Payment successful', order_id: order_id })
        end
      end

      context 'with failed payment' do
        before do
          allow(payment_service).to receive(:charge).with(100).and_return({ status: 'failed', error: 'Insufficient funds' })
        end

        it 'returns payment failed message' do
          result = service.process_order(order_id, user_id)
          expect(result).to eq({ message: 'Payment failed', error: 'Insufficient funds' })
          expect(order_repo).not_to have_received(:update_order_status)
        end
      end
    end

    context 'with unhandled order status' do
      let(:order) { { id: order_id, user_id: user_id, status: 'unknown' } }

      before do
        allow(order_repo).to receive(:get_order_by_id).with(order_id).and_return(order)
      end

      it 'returns unhandled status message' do
        result = service.process_order(order_id, user_id)
        expect(result).to eq({ message: 'Unhandled order status' })
      end
    end
  end
end
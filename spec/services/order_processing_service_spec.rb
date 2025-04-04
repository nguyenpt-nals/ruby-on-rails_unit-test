require "rails_helper"
require "csv"

RSpec.describe OrderProcessingService, type: :service do
  let(:api_client) { instance_double("ApiClient") }
  let(:service) { described_class.new(api_client) }
  let(:user) { create(:user) }
  let(:user_id) { user.id }
  let(:order) { create(:order, type: "A", user_id: user.id) }
  let(:order_b) { create(:order, type: "B", user_id: user.id) }
  let(:order_c) { create(:order, type: "C", user_id: user.id) }
  let(:orders) { [order, order_b, order_c] }

  describe "#process_orders" do
    context "when there are orders" do
      it "should return true when all orders are processed successfully" do
        # Given
        allow(Order).to receive(:where).with(user_id: user_id).and_return(orders)
        allow(service).to receive(:process_order)

        # When
        result = service.process_orders(user_id)

        # Then
        expect(result).to be true
      end
    end

    context "when there are no orders" do
      it "should return false when no orders are found" do
        # Given
        allow(Order).to receive(:where).with(user_id: user_id).and_return([])

        # When
        result = service.process_orders(user_id)

        # Then
        expect(result).to be false
      end
    end

    context "when an error occurs during processing" do
      it "should return false when an exception is raised" do
        # Given
        allow(Order).to receive(:where).with(user_id: user_id).and_return(orders)
        allow(service).to receive(:process_order).and_raise(StandardError)

        # When
        result = service.process_orders(user_id)

        # Then
        expect(result).to be false
      end
    end
  end

  describe "#process_order" do
    context "when order type is A" do
      context "when CSV generation succeeds" do
        it "should mark the order as exported" do
          # Given
          allow(service).to receive(:csv_generate).with(order, user_id).and_return(true)
          order.update(amount: 100)

          # When
          service.send(:process_order, order, user_id)

          # Then
          expect(order.status).to eq("exported")
        end
      end

      context "when CSV generation fails" do
        it "should mark the order as export_failed" do
          # Given
          allow(service).to receive(:csv_generate).and_raise(StandardError)

          # When
          service.send(:process_order, order, user_id)

          # Then
          expect(order.status).to eq("export_failed")
        end
      end
    end

    context "when order type is B" do
      it "should process type B order successfully when API returns success and data >= 50 and order.amount < 100" do
        # Given
        response = double("response", status: "success", data: 60)
        allow(api_client).to receive(:call_api).with(order_b.id).and_return(response)
        order_b.update(amount: 90)

        # When
        service.send(:process_order, order_b, user_id)

        # Then
        expect(order_b.status).to eq("processed")
      end

      it "should process type B order as pending when API returns success and data < 50" do
        # Given
        response = double("response", status: "success", data: 40)
        allow(api_client).to receive(:call_api).with(order_b.id).and_return(response)

        # When
        service.send(:process_order, order_b, user_id)

        # Then
        expect(order_b.status).to eq("pending")
      end

      it "should process type B order as pending when API returns success and order.flag is true" do
        # Given
        response = double("response", status: "success", data: 60)
        order_b.flag = true
        allow(api_client).to receive(:call_api).with(order_b.id).and_return(response)

        # When
        service.send(:process_order, order_b, user_id)

        # Then
        expect(order_b.status).to eq("pending")
      end

      it "should process type B order as error when API returns success and response.data >= 50 and order.amount >= 100" do
        # Given
        response = double("response", status: "success", data: 60)
        order_b.update(amount: 150)
        allow(api_client).to receive(:call_api).with(order_b.id).and_return(response)

        # When
        service.send(:process_order, order_b, user_id)

        # Then
        expect(order_b.status).to eq("error")
      end

      it "should set status to api_error if API call returns failure" do
        # Given
        response = double("response", status: "failure", data: 0)
        allow(api_client).to receive(:call_api).with(order_b.id).and_return(response)

        # When
        service.send(:process_order, order_b, user_id)

        # Then
        expect(order_b.status).to eq("api_error")
      end

      it "should set status to api_failure if API call raises an exception" do
        # Given
        allow(api_client).to receive(:call_api).with(order_b.id).and_raise(APIException)

        # When
        service.send(:process_order, order_b, user_id)

        # Then
        expect(order_b.status).to eq("api_failure")
      end
    end

    context "when order type is C" do
      it "should set status to completed if flag is true" do
        # Given
        order_c.flag = true

        # When
        service.send(:process_order, order_c, user_id)

        # Then
        expect(order_c.status).to eq("completed")
      end

      it "should set status to in_progress if flag is false" do
        # Given
        order_c.flag = false

        # When
        service.send(:process_order, order_c, user_id)

        # Then
        expect(order_c.status).to eq("in_progress")
      end
    end

    context "when order type is unknown" do
      it "should set status to unknown_type" do
        # Given
        unknown_order = create(:order, type: "D", user_id: user.id)

        # When
        service.send(:process_order, unknown_order, user_id)

        # Then
        expect(unknown_order.status).to eq("unknown_type")
      end
    end
  end

  describe "#update_priority" do
    it "should set priority to high if amount is greater than 200" do
      # Given
      order.update(amount: 250)

      # When
      service.send(:update_priority, order)

      # Then
      expect(order.priority).to eq("high")
    end

    it "should set priority to low if amount is less than or equal to 200" do
      # Given
      order.update(amount: 150)

      # When
      service.send(:update_priority, order)

      # Then
      expect(order.priority).to eq("low")
    end
  end

  describe "#save_order" do
    context "when order is saved successfully" do
      it "should save the order without any errors" do
        # Given
        allow(order).to receive(:save!).and_return(true)

        # When
        service.send(:save_order, order)

        # Then
        expect(order.status).not_to eq("db_error")
      end
    end

    context "when database error occurs" do
      it "should set status to db_error if DatabaseException is raised" do
        # Given
        allow(order).to receive(:save!).and_raise(DatabaseException)

        # When
        service.send(:save_order, order)

        # Then
        expect(order.status).to eq("db_error")
      end
    end
  end

  describe "#csv_generate" do
    let(:order) { create(:order, user_id: user_id, type: "A", amount: 100, flag: true, status: :pending, priority: :low) }
    let(:high_value_order) { create(:order, user_id: user_id, type: "A", amount: 200, flag: false, status: :processed, priority: :high) }
    let(:csv_filename) { "orders_type_A_#{user_id}_#{Time.now.to_i}.csv" }
    let(:mock_csv) { [] }

    before do
      allow(Time).to receive(:now).and_return(Time.at(1_701_234_567))
      allow(CSV).to receive(:open).and_yield(mock_csv)
    end

    it "should generate a CSV file with correct data when given a valid order" do
      # When
      service.send(:csv_generate, order, user_id)

      # Then
      expect(mock_csv).to eq([
        ["ID", "Type", "Amount", "Flag", "Status", "Priority"],
        [order.id, order.type, order.amount, order.flag, order.status, order.priority]
      ])
    end

    it "should include a high value order note when amount is greater than 150" do
      # When
      service.send(:csv_generate, high_value_order, user_id)

      # Then
      expect(mock_csv).to include(["", "", "", "", "Note", "High value order"])
    end
  end
end

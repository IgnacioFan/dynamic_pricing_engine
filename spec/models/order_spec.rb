require 'rails_helper'

RSpec.describe Order, type: :model do
  describe '.place_order!' do
    let(:product) { create(:product, total_inventory: 10, total_reserved: 0, current_demand_count: 2) }
    let(:cart) { create(:cart, cart_items: [ cart_item ]) }
    let(:cart_item) { build(:cart_item, product:, quantity: 2) }

    context 'when the cart exists' do
      it 'places the order successfully' do
        order, error = described_class.place_order!(cart.id)
        expect(error).to be_nil
        expect(order.total_price).to eq(product.dynamic_price * cart_item.quantity)
        expect(order.total_quantity).to eq(cart_item.quantity)
        expect(order.order_items.size).to eq(1)
        product.reload
        expect(product.total_inventory).to eq(10)
        expect(product.total_reserved).to eq(2)
        expect(product.current_demand_count).to eq(3)
      end
    end

    context "when product inventory is insufficient" do
      let(:cart_item) { build(:cart_item, product:, quantity: 11) }

      it 'returns an error' do
        order, error = described_class.place_order!(cart.id)
        expect(order).to be_nil
        expect(error).to eq("Product #{product.name} (ID: #{product.id}) is insufficient")
      end
    end

    context 'when the order has been created' do
      before { create(:order, cart: cart) }

      it 'returns an error' do
        order, error = described_class.place_order!(cart.id)
        expect(order).to be_nil
        expect(error).to eq("Order has been created")
      end
    end

    context 'when the cart does not exist' do
      it 'returns an error' do
        order, error = described_class.place_order!('nonexistent_id')
        expect(order).to be_nil
        expect(error).to eq('Cart not found')
      end
    end

    context 'when the cart has no items' do
      let(:cart) { create(:cart) }

      it 'returns an error' do
        order, error = described_class.place_order!(cart.id)
        expect(order).to be_nil
        expect(error).to eq('Cart is empty')
      end
    end

    context "when multiple threads place orders simultaneously" do
      it "handles race conditions when many orders update the same product" do
        threads = []
        errors = []

        5.times do
          threads << Thread.new do
            begin
              Order.place_order!(cart.id)
            rescue => e
              errors << e.message
            end
          end
        end

        # Wait for 5 threads to complete
        threads.each(&:join)

        product.reload

        expect(product.total_reserved).to eq(2)
        expect(product.current_demand_count).to eq(3)
        expect(errors).to be_empty
      end
    end
  end

  describe '#cancel_order!' do
    let(:product) { create(:product, total_inventory: 10, total_reserved: 2, current_demand_count: 2) }
    let(:order_item) { build(:order_item, product:, quantity: 2) }

    context 'when the order has been cancelled' do
      let!(:order) { create(:order, order_status: "cancelled", order_items: [ order_item ]) }

      it 'returns an error' do
        result, error = order.cancel_order!
        expect(result).to be_nil
        expect(error).to eq("Order has been canceled")
      end
    end

    context 'when the order is valid' do
      let!(:order) { create(:order, order_items: [ order_item ]) }

      it 'cancel the order successfully' do
        result, error = order.cancel_order!
        expect(error).to be_nil
        expect(result.order_status).to eq("cancelled")
        product.reload
        expect(product.total_inventory).to eq(10)
        expect(product.total_reserved).to eq(0)
        expect(product.current_demand_count).to eq(2)
      end
    end

    context "when multiple threads cancel the order simultaneously" do
      let!(:order) { create(:order, order_items: [ order_item ]) }

      it "handles race conditions when many orders update the same product" do
        threads = []
        errors = []

        5.times do
          threads << Thread.new do
            begin
              order.cancel_order!
            rescue => e
              errors << e.message
            end
          end
        end

        # Wait for 5 threads to complete
        threads.each(&:join)

        product.reload

        expect(product.total_reserved).to eq(0)
        expect(product.current_demand_count).to eq(2)
        expect(errors).to be_empty
      end
    end
  end
end

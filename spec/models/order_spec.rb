require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:product) { create(:product, total_inventory: 10, total_reserved: 0) }
  let(:cart) { create(:cart, cart_items: [ cart_item ]) }
  let(:cart_item) { build(:cart_item, product:, quantity: 2) }

  describe '.place_order!' do
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
  end
end

require 'rails_helper'

RSpec.describe AddItemsToCartService do
  let(:product) { create(:product, inventory: { total_inventory: 10, total_reserved: 0 }) }
  let(:cart_items) { [ { product_id: product.id, quantity: 2 } ] }

  describe '.call' do
    context 'when cart does not exist' do
      it 'adds items to the cart and updates demand score' do
        result = described_class.call(cart_items:)
        expect(result.success?).to be true
        cart = result.payload
        expect(cart.cart_items).to eq(cart_items)
        expect(product.reload.demand_score).to eq(20)
      end
    end

    context 'when cart exists' do
      let(:cart) { create(:cart) }

      it 'adds items to the cart and updates demand score' do
        result = described_class.call(cart_id: cart.id, cart_items:)
        expect(result.success?).to be true
        new_cart = result.payload
        expect(new_cart.id).to eq(cart.id)
        expect(new_cart.cart_items).to eq(cart_items)
        expect(product.reload.demand_score).to eq(20)
      end
    end

    context 'when cart items are invalid' do
      let(:cart_items) { [ { product_id: nil, quantity: 0 } ] }

      it 'returns failure' do
        result = described_class.call(cart_items:)
        expect(result.success?).to be false
        expect(result.error).to match(/invalid item data/)
      end
    end

    context 'when product does not exist' do
      let(:cart_items) { [ { product_id: 123, quantity: 2 } ] }

      it 'returns failure' do
        result = described_class.call(cart_items:)
        expect(result.success?).to be false
        expect(result.error).to match(/product not found/)
      end
    end

    context 'when inventory is insufficient' do
      let(:cart_items) { [ { product_id: product.id, quantity: 20 } ] }

      it 'returns failure' do
        result = described_class.call(cart_items:)
        expect(result.success?).to be false
        expect(result.error).to match(/insufficient inventory/)
      end
    end

    context 'when no items are given' do
      let(:cart_items) { [] }

      it 'returns failure' do
        result = described_class.call(cart_items:)
        expect(result.success?).to be false
        expect(result.error).to match(/items cannot be empty/)
      end
    end
  end

  after do
    Mongoid.truncate!
  end
end

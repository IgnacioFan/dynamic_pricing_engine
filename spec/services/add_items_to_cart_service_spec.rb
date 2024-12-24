require 'rails_helper'

RSpec.describe AddItemsToCartService do
  let(:product) { create(:product, inventory: { total_inventory: 10, total_reserved: 0 }) }
  let(:cart_items) { [ { product_id: product.id, quantity: 2 } ] }

  describe '.call' do
    context 'when cart does not exist' do
      it 'adds items to the cart and updates demand score' do
        result = described_class.call(cart_id: nil, cart_items:)
        cart = result.payload
        expect(cart.persisted?).to eq(true)
        expect(cart.cart_items[0].product_id).to eq(product.id)
        expect(cart.cart_items[0].quantity).to eq(2)
        expect(product.reload.curr_added_frequency).to eq(20)
      end
    end

    context 'when cart exists' do
      let(:cart) { create(:cart) }

      it 'adds items to the cart and updates demand score' do
        result = described_class.call(cart_id: cart.id, cart_items:)
        new_cart = result.payload
        expect(new_cart.id).to eq(cart.id)
        expect(new_cart.cart_items[0].product_id).to eq(product.id)
        expect(new_cart.cart_items[0].quantity).to eq(2)
        expect(product.reload.curr_added_frequency).to eq(20)
      end
    end

    context 'when cart items are invalid' do
      let(:cart_items) { [ { product_id: nil, quantity: 0 } ] }

      it 'returns failure' do
        result = described_class.call(cart_items:)
        expect(result.success?).to be false
        expect(result.error).to eq("Invalid item data: #{cart_items.first}")
      end
    end

    context 'when product does not exist' do
      let(:cart_items) { [ { product_id: 123, quantity: 2 } ] }

      it 'returns failure' do
        result = described_class.call(cart_items:)
        expect(result.success?).to be false
        expect(result.error).to eq("Product not found ID (123)")
      end
    end

    context 'when inventory is insufficient' do
      let(:cart_items) { [ { product_id: product.id, quantity: 20 } ] }

      it 'returns failure' do
        result = described_class.call(cart_items:)
        expect(result.success?).to be false
        expect(result.error).to eq("Insufficient inventory for product #{product.id}")
      end
    end

    context 'when no items are given' do
      let(:cart_items) { [] }

      it 'returns failure' do
        result = described_class.call(cart_items:)
        expect(result.success?).to be false
        expect(result.error).to eq("Items cannot be empty")
      end
    end
  end

  after do
    Mongoid.truncate!
  end
end

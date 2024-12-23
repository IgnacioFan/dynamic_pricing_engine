require 'rails_helper'

RSpec.describe RemoveItemsFromCartService, type: :service do
  let!(:cart) { create(:cart) }
  let!(:cart_item) { create(:cart_item, cart:) }

  describe '.call' do
    context 'when cart and item exists' do
      it 'removes the item' do
        result = RemoveItemsFromCartService.call(cart_id: cart.id, cart_item_id: cart_item.id)
        expect(result).to be_success
        expect(result.payload).to eq(cart_item)
        expect(cart.reload.cart_items).to be_empty
      end
    end

    context 'when the cart_id is empty' do
      it 'returns failure with a not found message' do
        result = RemoveItemsFromCartService.call(cart_id: '', cart_item_id: cart_item.id)
        expect(result).not_to be_success
        expect(result.error).to eq('Cart not found')
      end
    end

    context 'when the cart_item_id is empty' do
      it 'returns failure' do
        result = RemoveItemsFromCartService.call(cart_id: cart.id, cart_item_id: '')
        expect(result).not_to be_success
        expect(result.error).to eq('Cart item not found')
      end
    end
  end

  after do
    Mongoid.truncate!
  end
end

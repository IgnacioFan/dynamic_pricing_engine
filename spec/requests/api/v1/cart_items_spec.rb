require 'rails_helper'

RSpec.describe Api::V1::CartItemsController, type: :request do
  let(:cart) { build(:cart) }
  let(:product) { build(:product) }
  let(:cart_id) { cart.id.to_s }

  describe 'POST /api/v1/carts/:cart_id/items' do
    before do
      allow(AddItemsToCartService).to receive(:call).and_return(result)
    end

    context 'when the request is valid' do
      let(:result) do
        cart.cart_items << build(:cart_item, product: product, quantity: 3)
        double('ServiceResult', success?: true, payload: cart)
      end

      it 'returns status created' do
        post api_v1_cart_items_path(cart_id: cart.id), params: {
          cart_item: {
            product_id: product.id,
            quantity: 3
          }
        }

        expect(response).to have_http_status(:created)
        parsed_response = JSON.parse(response.body, symbolize_names: true)
        expect(parsed_response[:cart_id]).to eq(cart_id)
        expect(parsed_response[:count]).to eq(1)
        expect(parsed_response[:cart_items][0][:product_id]).to eq(product.id.to_s)
        expect(parsed_response[:cart_items][0][:quantity]).to eq(3)
      end
    end

    context 'when the request is invalid' do
      let(:error_message) { 'invalid item data' }
      let(:result) { double('ServiceResult', success?: false, error: error_message) }

      it 'returns status bad request' do
        post api_v1_cart_items_path(cart_id: cart.id), params: {
          cart_item: {
            product_id: nil,
            quantity: 3
          }
        }
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include(error_message)
      end
    end
  end

  describe 'DELETE /api/v1/carts/:cart_id/items/:id' do
    let(:cart) { build(:cart, cart_items: [ cart_item ]) }
    let(:product) { build(:product) }
    let(:cart_item) { build(:cart_item, product: product, quantity: 3) }

    before do
      allow(RemoveItemsFromCartService).to receive(:call).and_return(result)
    end

    context 'when the cart item exists' do
      let(:result) { double('ServiceResult', success?: true, payload: cart_item) }

      it 'deletes the cart item and returns status ok' do
        delete api_v1_cart_item_path(cart_id: cart.id, id: cart_item.id)
        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body, symbolize_names: true)
        expect(parsed_response[:cart_item][:id]).to eq(cart_item.id.to_s)
        expect(parsed_response[:cart_item][:product_id]).to eq(product.id.to_s)
        expect(parsed_response[:cart_item][:quantity]).to eq(3)
      end
    end

    context 'when the cart is empty' do
      let(:cart) { build(:cart, cart_items: []) }
      let(:error_message) { 'cart is empty' }
      let(:result) { double('ServiceResult', success?: false, error: error_message) }

      it 'returns a bad request status' do
        delete api_v1_cart_item_path(cart_id: cart.id, id: cart_item.id)
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include('cart is empty')
      end
    end
  end
end

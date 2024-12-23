require 'rails_helper'

RSpec.describe 'Carts API', type: :request do
  describe 'GET /api/v1/carts/:id' do
    let(:cart_items) { [ { product_id: 123, quantity: 2 }, { product_id: 456, quantity: 1 } ] }
    let(:cart) { build(:cart, cart_items: cart_items) }

    before do
      allow(Cart).to receive(:find).and_return(cart)
    end

    it 'returns 200 and the cart' do
      get "/api/v1/carts/#{cart.id}"
      expect(response).to have_http_status(:ok)
      parsed_response = JSON.parse(response.body, symbolize_names: true)
      expect(parsed_response[:cart_id]).to eq(cart.id.to_s)
      expect(parsed_response[:cart_items]).to eq(cart_items)
    end
  end

  describe 'POST /api/v1/carts' do
    let(:cart_items) { [ { product_id: 123, quantity: 2 }, { product_id: 456, quantity: 1 } ] }
    let(:cart) { build(:cart, cart_items: cart_items) }

    before do
      allow(AddItemsToCartService).to receive(:call).and_return(result)
    end

    context 'when request is valid' do
      let(:result) { double('ServiceResult', success?: true, payload: cart) }

      it 'returns 201' do
        post '/api/v1/carts', params: { cart: { items: cart_items } }, as: :json
        expect(response).to have_http_status(:created)
        parsed_response = JSON.parse(response.body, symbolize_names: true)
        expect(parsed_response[:cart_id]).to eq(cart.id.to_s)
        expect(parsed_response[:cart_items]).to eq(cart_items)
      end
    end

    context 'when request is invalid' do
      let(:cart_items) { [ { product_id: nil, quantity: 2 } ] }
      let(:error_message) { 'Invalid request' }
      let(:result) { double('ServiceResult', success?: false, error: error_message) }

      it 'returns 400 and an error message' do
        post '/api/v1/carts', params: { cart: { items: cart_items } }, as: :json
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq(error_message)
      end
    end
  end
end

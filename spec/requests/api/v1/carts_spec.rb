require 'rails_helper'

RSpec.describe 'Carts API', type: :request do
  describe 'POST /api/v1/carts' do
    let(:product) { build(:product) }
    let(:cart) { build(:cart, cart_items: [ cart_item ]) }
    let(:cart_item) { build(:cart_item, product: product, quantity: 2) }

    before do
      allow(AddItemsToCartService).to receive(:call).with(cart_id: nil, cart_items: cart_items).and_return(result)
    end

    context 'when request is valid' do
      let(:cart_items) { [ { product_id: product.id.to_s, quantity: 2 } ] }
      let(:result) { double('ServiceResult', success?: true, payload: cart) }

      it 'returns status ok (200)' do
        post api_v1_carts_path, params: { cart: { items: [ cart_items ] } }
        expect(response).to have_http_status(:created)
        parsed_response = JSON.parse(response.body, symbolize_names: true)
        expect(parsed_response[:cart_id]).to eq(cart.id.to_s)
        expect(parsed_response[:count]).to eq(1)
        expect(parsed_response[:cart_items][0][:product_id]).to eq(product.id.to_s)
        expect(parsed_response[:cart_items][0][:quantity]).to eq(2)
      end
    end

    context 'when request is invalid' do
      let(:cart_items) { [ { product_id: nil, quantity: 2 } ] }
      let(:error_message) { 'Invalid request' }
      let(:result) { double('ServiceResult', success?: false, error: error_message) }

      it 'returns status bad request (400)' do
        post api_v1_carts_path, params: { cart: { items: cart_items } }, as: :json
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq(error_message)
      end
    end
  end
end

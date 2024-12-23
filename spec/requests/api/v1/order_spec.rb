require 'rails_helper'

RSpec.describe 'Orders API', type: :request do
  describe 'POST /api/v1/orders' do
    let(:cart_id) { BSON::ObjectId.new }
    let(:product) { build(:product) }
    let(:order) { build(:order, cart_id:, total_quantity: 2, total_price: 20.0, order_items: [ order_item ]) }
    let(:order_item) { build(:order_item, product: product, quantity: 2) }

    before { allow(Order).to receive(:place_order!).with(cart_id).and_return([ order, nil ]) }

    context 'when the order is placed successfully' do
      it 'returns status created (201)' do
        post api_v1_orders_path, params: { cart_id: cart_id }

        expect(response).to have_http_status(:created)
        parsed_response = JSON.parse(response.body, symbolize_names: true)
        expect(parsed_response[:id]).to eq(order.id.to_s)
        expect(parsed_response[:cart_id]).to eq(cart_id.to_s)
        expect(parsed_response[:total_quantity]).to eq(2)
        expect(parsed_response[:total_price]).to eq(20.0)
        expect(parsed_response[:order_items][0][:product_id]).to eq(product.id.to_s)
        expect(parsed_response[:order_items][0][:quantity]).to eq(2)
        expect(parsed_response[:order_items][0][:price]).to eq(10.0)
      end
    end

    context 'when the order fails to be placed' do
      let(:error_message) { "Cart not found" }

      before { allow(Order).to receive(:place_order!).with(cart_id).and_return([ nil, error_message ]) }

      it 'returns status bad request (400)' do
        post api_v1_orders_path, params: { cart_id: cart_id }

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include(error_message)
      end
    end
  end
end

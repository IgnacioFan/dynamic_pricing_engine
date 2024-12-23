module Api
  module V1
    class CartsController < ActionController::API
      def create
        result = AddItemsToCartService.call(cart_id: nil, cart_items: cart_items)
        if result.success?
          @cart = result.payload
          render :create, status: :created
        else
          render json: result.error, status: :bad_request
        end
      end

      private

      def cart_params
        params.require(:cart).permit(items: [ :product_id, :quantity ])
      end

      def cart_items
        cart_params[:items].map { |item| { product_id: item[:product_id], quantity: item[:quantity].to_i } }
      end
    end
  end
end

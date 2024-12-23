module Api
  module V1
    class CartItemsController < ActionController::API
      def create
        result = AddItemsToCartService.call(cart_id: params[:cart_id], cart_items: cart_items)
        if result.success?
          @cart = result.payload
          render :create, status: :created
        else
          render json: result.error, status: :bad_request
        end
      end

      def destroy
        result = RemoveItemsFromCartService.call(cart_id: params[:cart_id], cart_item_id: params[:id])
        if result.success?
          @cart_item = result.payload
          render :destroy
        else
          render json: result.error, status: :bad_request
        end
      end

      private

      def cart_item_params
        params.require(:cart_item).permit(:product_id, :quantity)
      end

      def cart_items
        [ { product_id: cart_item_params[:product_id], quantity: cart_item_params[:quantity].to_i } ]
      end
    end
  end
end

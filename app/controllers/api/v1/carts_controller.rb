module Api
  module V1
    class CartsController < ActionController::API
      def show
        @cart = Cart.find(params[:id])
      end

      def create
        result = AddItemsToCartService.call(items: cart_params[:items])
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
    end
  end
end

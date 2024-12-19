module Api
  module V1
    class ProductsController < ActionController::API
      def index
        @products = Product.all
        render json: @products
      end

      def show
        @product = Product.find_by(id: params[:id])
        @dynamic_price = @product.price_logs.last
      end
    end
  end
end

module Api
  module V1
    class ProductController < ActionController::API
      def index
        @products = Product.all
        render json: @products
      end

      def show
        @product = Product.find_by(id: params[:id])
        render json: @product
      end
    end
  end
end

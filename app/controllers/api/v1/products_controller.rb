module Api
  module V1
    class ProductsController < ActionController::API
      before_action :validate_file_format, only: [ :import ]

      def index
        @products = Product.all
        render json: @products
      end

      def show
        @product = Product.find_by(id: params[:id])
        @dynamic_price = @product.price_logs.last
      end

      def import
        result = ImportInventoryCsvService.call(params[:file].path)
        if result.success?
          @products = result.payload
          render :import, status: :created
        else
          render json: result.error, status: :bad_request
        end
      end

      private

      def validate_file_format
        if params[:file].blank?
          render json: { error: "File is required" }, status: :unprocessable_entity and return
        end

        unless params[:file].content_type == "text/csv"
          render json: { error: "Invalid file format (only csv)" }, status: :unprocessable_entity
        end
      end
    end
  end
end

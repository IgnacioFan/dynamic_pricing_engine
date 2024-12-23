module Api
  module V1
    class OrdersController < ActionController::API
      def create
        @order, error = Order.place_order!(params[:cart_id])
        if @order
          render :create, status: :created
        else
          render json: error, status: :bad_request
        end
      end
    end
  end
end

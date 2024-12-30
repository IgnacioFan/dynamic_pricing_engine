module Api
  module V1
    class OrdersController < ActionController::API
      before_action :find_order, only: [ :destroy ]

      def create
        @order, error = Order.place_order!(params[:cart_id])
        if @order
          render :create, status: :created
        else
          render json: { error: error }, status: :bad_request
        end
      end

      def destroy
        @order, error = @order.cancel_order!
        if @order
          render :destroy
        else
          render json: { error: error }, status: :bad_request
        end
      end

      private

      def find_order
        @order = Order.find(params["id"])
      rescue Mongoid::Errors::DocumentNotFound
        render json: { error: "Order is not found" }, status: :bad_request
      end
    end
  end
end

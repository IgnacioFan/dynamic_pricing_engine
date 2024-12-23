class RemoveItemsFromCartService < ApplicationService
  def initialize(args)
    @cart_id = args[:cart_id]
    @cart_item_id = args[:cart_item_id]
  end

  def call
    cart = Cart.find(@cart_id)
    cart_item, error = cart.remove_item(@cart_item_id)
    return failure(error) if error

    success(cart_item)
  rescue Mongoid::Errors::DocumentNotFound
    failure("Cart not found")
  end
end

class RemoveItemsFromCartService < ApplicationService
  def initialize(args)
    @cart = find_cart(args[:cart_id])
    @cart_item_id = args[:cart_item_id]
  end

  def call
    return failure("Cart not found") unless cart
    return failure("Cart is empty") unless cart.cart_items

    cart_item = find_cart_item(cart_item_id)
    return failure("Cart item not found") if cart_item.nil?

    cart_item.destroy!

    success(cart_item)
  end

  private

  attr_accessor :cart, :cart_item_id

  def find_cart(cart_id)
    Cart.find(cart_id)
  rescue Mongoid::Errors::DocumentNotFound
    nil
  end

  def find_cart_item(cart_item_id)
    cart.cart_items.find_by(id: cart_item_id)
  rescue Mongoid::Errors::DocumentNotFound
    nil
  end
end

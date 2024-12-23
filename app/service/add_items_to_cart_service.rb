class AddItemsToCartService < ApplicationService
  def initialize(args)
    @cart = args[:cart_id].nil? ? Cart.new : Cart.find(args[:cart_id])
    @cart_items = args[:cart_items]
  end

  def call
    error = validate_cart_items
    return error if error.present?

    error = add_items_to_cart
    return error if error.present?

    success(cart)
  rescue Mongoid::Errors::DocumentNotFound => e
    failure("product not found: #{e.message}")
  end

  private

  attr_accessor :cart, :cart_items

  def validate_cart_items
    return failure("items cannot be empty") if cart_items.blank?

    cart_items.each do |item|
      unless item[:product_id].present? && item[:quantity].to_i.positive?
        return failure("invalid item data: #{item.inspect}")
      end
    end

    nil
  end

  def add_items_to_cart
    cart_items.each do |item|
      product = Product.find(item[:product_id])

      unless product.available_inventory?(item[:quantity])
        return failure("insufficient inventory for product #{product.id}")
      end

      cart.add_product!(product.id, item[:quantity])
      product.update_demand_score(item[:quantity])
    end
    nil
  end
end

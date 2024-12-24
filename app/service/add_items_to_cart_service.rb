class AddItemsToCartService < ApplicationService
  def initialize(args)
    @cart = args[:cart_id].nil? ? Cart.new : Cart.find(args[:cart_id])
    @cart_items = args[:cart_items]
    @caches = {}
  end

  def call
    error = validate_cart_items
    return error if error.present?

    error = add_items_to_cart
    return error if error.present?

    success(cart)
  rescue Mongoid::Errors::DocumentNotFound
    failure("Cart not found")
  end

  private

  attr_accessor :cart, :cart_items, :caches

  def validate_cart_items
    return failure("Items cannot be empty") if cart_items.blank?

    cart_items.each do |item|
      unless item[:product_id].present? && item[:quantity].to_i.positive?
        return failure("Invalid item data: #{item.inspect}")
      end
    end
    nil
  end

  def add_items_to_cart
    errors = []

    cart_items.each do |item|
      product = Product.where(id: item[:product_id]).first

      unless product
        errors << "Product not found ID (#{item[:product_id]})"
        next
      end

      unless product.available_inventory?(item[:quantity])
        errors << "Insufficient inventory for product #{product.id}"
        next
      end

      caches[product] = item[:quantity]
      cart_item = cart.cart_items.find_or_initialize_by(product_id: product.id)
      cart_item.quantity = item[:quantity]
    end

    return failure(errors.join(", ")) if errors.any?

    if cart.save!
      update_product_frequencies
    end
    nil
  end

  def update_product_frequencies
    caches.each do |product, quantity|
      product.update_current_demand_count(quantity)
      TrackProductDemandJob.perform_async(product.id.to_s) if !Rails.env.test?
    end
  end
end

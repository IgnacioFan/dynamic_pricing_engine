class AdjustProductPriceService < ApplicationService
  PRICE_INCR_RATE = 1.10.freeze
  PRICE_DECR_RATE = 0.90.freeze
  PRICE_BOTTOM_LINE = 0.60.freeze

  def initialize(product_id)
    @product = find_product(product_id)
  end

  def call
    return failure("Product not found") unless product

    product.demand_price = adjust_demand_price
    product.inventory_price = adjust_inventory_price if inventory_profitable_range
    product.save!
    success(product)
  end

  private

  attr_accessor :product

  def find_product(id)
    Product.find(id)
  rescue Mongoid::Errors::DocumentNotFound
    nil
  end

  def adjust_demand_price
    # increase the price if the product is frequently added to carts or purchased
    if product.high_demand_product?
      (product.demand_price || product.default_price) * PRICE_INCR_RATE
    else
      product.demand_price
    end
  end

  def adjust_inventory_price
    # increase the price if the product's inventory level is low
    if product.low_inventory_level?
      (product.inventory_price || product.default_price) * PRICE_INCR_RATE
    # decrease the price if the product's inventory level is high
    elsif product.high_inventory_level?
      (product.inventory_price || product.default_price) * PRICE_DECR_RATE
    else
      product.inventory_price
    end
  end

  def inventory_profitable_range
    return true if product.inventory_price.nil?
    product.inventory_price > (product.default_price * PRICE_BOTTOM_LINE)
  end
end

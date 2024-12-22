class AdjustProductPriceService < ApplicationService
  DEMAND_INCR_RATE = 1.05.freeze
  INVENTORY_INCR_RATE = 1.10.freeze
  INVENTORY_DECR_RATE = 0.95.freeze

  def initialize(product_id)
    @product = Product.find(product_id)
  end

  def call
    return failure("Product price is locked now") unless price_unlocked?

    update_product_unlocked_time
    adjust_new_product_price
    success(@product)
  end

  private

  attr_accessor :product

  def price_unlocked?
    product.price_unlocked_at.nil? || Time.now.utc > product.price_unlocked_at
  end

  def update_product_unlocked_time
    product.price_unlocked_at = Time.now.utc + 30.minutes
  end

  def adjust_new_product_price
    if high_demand_product?
      new_price = product.current_price * DEMAND_INCR_RATE
      product.demand_score = 0
      product.update_price(
        price: new_price,
        source: "high demand"
      )
    elsif low_inventory_product?
      new_price = product.current_price * INVENTORY_INCR_RATE
      product.update_price(
        price: new_price,
        source: "low inventory"
      )
    elsif high_inventory_product?
      new_price = product.current_price * INVENTORY_DECR_RATE
      product.update_price(
        price: new_price,
        source: "high inventory"
      )
    end
  end

  def high_demand_product?
    product.demand_score > 50
  end

  def low_inventory_product?
    (product.inventory[:total_inventory] - product.inventory[:total_reserved]).to_f / product.inventory[:total_inventory] < 0.2
  end

  def high_inventory_product?
    (product.inventory[:total_inventory] - product.inventory[:total_reserved]).to_f / product.inventory[:total_inventory] > 0.8
  end
end

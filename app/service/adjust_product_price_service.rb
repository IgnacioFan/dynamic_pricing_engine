class AdjustProductPriceService < ApplicationService
  def initialize(product_id)
    @product = find_product(product_id)
  end

  def call
    return failure("Product not found") unless product

    product.update_inventory_level
    product.update_demand_level
    product.reset_current_demand_count
    product.calculate_dynamic_price
    # run the above before reset_dynamic_price_expiry
    product.reset_dynamic_price_expiry
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
end

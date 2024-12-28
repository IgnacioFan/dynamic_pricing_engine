class AdjustProductPriceService < ApplicationService
  def initialize(product_id)
    @product = find_product(product_id)
  end

  def call
    return failure("Product not found") unless product

    product.set_inventory_level
    product.set_demand_level
    product.calculate_dynamic_price_v2
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

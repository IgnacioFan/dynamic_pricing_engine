class CompareCompetitorPriceService < ApplicationService
  def initialize(competitor_products)
    @competitor_products = competitor_products
  end

  def call
    compare_price
    success
  end

  private

  def compare_price
    @competitor_products.each do |entry|
      my_product = find_my_product(entry[:name], entry[:category])
      next if my_product.nil?
      next if entry[:price] <= 0.0 || entry[:price] == my_product.current_price.to_f

      my_product.update_price(price: entry[:price].to_f, source: "compare_competitor_price_service")
    end
  end

  def find_my_product(name, category)
    Product.where(name:, category:).first
  end
end

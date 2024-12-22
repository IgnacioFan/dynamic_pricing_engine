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
    @competitor_products.each do |competitor_product|
      product = find_my_product(competitor_product[:name], competitor_product[:category])
      next if product.nil?

      comp_price = competitor_product[:price].to_f
      my_price = product.current_price.to_f
      next if comp_price <= 0.0 || comp_price == my_price

      if price_not_competitive?(comp_price, my_price)
        product.update_price(price: comp_price, source: "competitor")
      end
    end
  end

  def price_not_competitive?(comp_price, my_price)
    comp_price > my_price * 1.05 || comp_price < my_price * 0.95
  end

  def find_my_product(name, category)
    Product.where(name:, category:).first
  end
end

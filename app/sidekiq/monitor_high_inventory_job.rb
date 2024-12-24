class MonitorHighInventoryJob
  include Sidekiq::Job
  sidekiq_options retry: 2

  def perform
    Product.high_inventory_products.each do |product|
      AdjustProductPriceService.call(product.id.to_s)
    end
  end
end

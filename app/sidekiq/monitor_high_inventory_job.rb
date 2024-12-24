class MonitorHighInventoryJob
  include Sidekiq::Job
  sidekiq_options retry: 2

  def perform
    Product.high_inventory_products.each do |product|
      # debugger
      AdjustProductPriceService.call(product.id.to_s)
    end
  end
end

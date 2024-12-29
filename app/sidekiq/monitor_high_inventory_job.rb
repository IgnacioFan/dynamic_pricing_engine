# identify product above high inventory levels by reducing prices to boost sales.
#
class MonitorHighInventoryJob
  include Sidekiq::Job
  sidekiq_options retry: 2

  def perform
    Product.where(:inventory_level.in => [ :very_high, :high ]).pluck(:id).each do |product_id|
      AdjustProductPriceService.call(product_id.to_s)
    end
  end
end

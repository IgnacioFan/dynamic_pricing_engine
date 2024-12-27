# This job runs every day at midnight
#
class MonitorHighInventoryJob
  include Sidekiq::Job
  sidekiq_options retry: 2

  def perform
    Product.where(inventory_level: :high).each do |product|
      AdjustProductPriceService.call(product.id.to_s)
    end
  end
end

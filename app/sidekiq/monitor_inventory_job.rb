class MonitorInventoryJob
  include Sidekiq::Job
  sidekiq_options retry: 2

  def perform(product_id)
    AdjustProductPriceService.call(product_id.to_s)
  end
end

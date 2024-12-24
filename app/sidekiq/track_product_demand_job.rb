# This job runs when a product is added to cart or an order is created
#
class TrackProductDemandJob
  include Sidekiq::Job
  sidekiq_options retry: 2

  def perform(product_id)
    AdjustProductPriceService.call(product_id.to_s)
  end
end

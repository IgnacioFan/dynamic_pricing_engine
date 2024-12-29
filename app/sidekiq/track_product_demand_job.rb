# adjust dynamic price by tracking demand, inventory, and competitor price changes.
#
class TrackProductDemandJob
  include Sidekiq::Job
  sidekiq_options retry: 2

  def perform(product_id)
    AdjustProductPriceService.call(product_id.to_s)
  end
end

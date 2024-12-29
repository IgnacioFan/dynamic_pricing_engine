# update competitor prices by retrieving data from third-party APIs
#
class CompareSinatraPricingJob
  include Sidekiq::Job
  sidekiq_options retry: 2

  def perform(*args)
    response = fetch_product_prices
    case response.code
    when 200
      competitor_produts = format_products(response.parsed_response)
      CompareCompetitorPriceService.call(competitor_produts)
    when 500...600
      raise StandardError, "#{response.code}, internal server error: #{response.body}"
    else
      Rails.logger.error "Unexpected response code #{response.code}: #{response.body}"
    end
  end

  private

  def fetch_product_prices
    api_key = Rails.application.credentials.sinatra_pricing_api_key
    SinatraPricingApi.new(api_key).fetch_product_prices
  end

  def format_products(input)
    input.map do |row|
      {
        name: row["name"].to_s,
        category: row["category"].to_s,
        price: row["price"].to_f
      }
    end
  end
end

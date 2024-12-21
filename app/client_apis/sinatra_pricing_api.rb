class SinatraPricingApi
  include HTTParty
  base_uri "https://sinatra-pricing-api.fly.dev/".freeze
  HEADERS = { "Content-Type" => "application/json" }.freeze

  def initialize(api_key)
    @auth = { api_key: api_key }
  end

  def fetch_product_prices
    options = { query: @auth, headers: HEADERS }
    self.class.get("/prices", options)
  end
end

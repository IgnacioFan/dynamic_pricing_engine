require 'rails_helper'
require 'vcr'

RSpec.describe SinatraPricingApi do
  let(:api_key) { 'test' }

  describe '#fetch_product_prices' do
    context 'when API call is successful' do
      it 'returns products' do
        VCR.use_cassette('sinatra_pricing_api/fetch_product_prices_success') do
          response = described_class.new(api_key).fetch_product_prices

          expect(response.code).to eq(200)
          expect(response.parsed_response.first).to include("name", "category", "price", "qty")
        end
      end
    end
  end
end

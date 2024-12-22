require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe CompareSinatraPricingJob, type: :job do
  describe '#perform' do
    let(:mock_service) { instance_double(SinatraPricingApi) }

    before do
      allow(SinatraPricingApi).to receive(:new).and_return(mock_service)
    end

    context 'when the response code is 200' do
      let(:competitor_products) { [ { "name" => "Product A", "category" => "Category X", "price" => 100.0 } ] }
      let(:response) { double(code: 200, parsed_response: competitor_products) }

      before do
        allow(mock_service).to receive(:fetch_product_prices).and_return(response)
        allow(CompareCompetitorPriceService).to receive(:call)
      end

      it 'calls CompareCompetitorPriceService' do
        described_class.new.perform
        expect(CompareCompetitorPriceService).to have_received(:call).with(
          [ { name: "Product A", category: "Category X", price: 100.0 } ]
        )
        described_class.drain
      end
    end

    context 'when the response code is 500' do
      let(:response) { double(code: 500, body: { "error" => "Internal Server Error" }) }

      before do
        allow(mock_service).to receive(:fetch_product_prices).and_return(response)
      end

      it 'raises an exception and retries' do
        expect { described_class.new.perform }.to raise_error(StandardError, "500, internal server error: #{response.body}")
      end
    end
  end

  describe "sidekiq options" do
    it "sets retry to 2" do
      expect(described_class.sidekiq_options["retry"]).to eq(2)
    end
  end
end

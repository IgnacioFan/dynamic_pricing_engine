require 'rails_helper'

RSpec.describe AdjustProductPriceService, type: :service do
  let(:service) { described_class.call(product.id) }

  describe ".call" do
    context "when the product is not found" do
      it "returns an error" do
        result = described_class.call(9999)
        expect(result.error).to eq("Product not found")
      end
    end

    context "when the product exists" do
      let!(:product) do
        create(:product,
          default_price: 100,
          current_demand_count: 10,
          previous_demand_count: 9,
          total_inventory: 100,
          total_reserved: 96,
          inventory_thresholds: { very_low: 0.95, low: 0.80, medium: 0.60, high: 0.40, very_high: 0.20 },
          inventory_rates: { very_high: -0.30, high: -0.15, medium: -0.05, low: 0, very_low: 0.10 },
          demand_rates: { high: 0.05, medium: 0.025, low: 0 },
          dynamic_price_expiry: 3.hours.ago.utc
        )
      end

      it "update product's price, demand, and inventory levels" do
        product = service.payload
        expect(product.dynamic_price).to eq(115)
        expect(product.demand_level).to eq(:high)
        expect(product.inventory_level).to eq(:very_low)
      end
    end
  end
end

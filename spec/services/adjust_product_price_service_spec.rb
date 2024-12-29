require 'rails_helper'

RSpec.describe AdjustProductPriceService, type: :service do
  describe ".call" do
    let(:product) { create(:product, **product_attributes) }
    let(:service) { described_class.call(product.id) }

    context "when the product is not found" do
      it "returns an error" do
        result = described_class.call(9999)
        expect(result).not_to be_success
        expect(result.error).to eq("Product not found")
      end
    end

    context "when the product exists" do
      let(:product_attributes) do
        {
          default_price: 100,
          current_demand_count: 10,
          previous_demand_count: 9,
          total_inventory: 100,
          total_reserved: 96,
          inventory_thresholds: { very_low: 0.95, low: 0.80, medium: 0.60, high: 0.40, very_high: 0.20 },
          inventory_rates: { very_high: -0.30, high: -0.15, medium: -0.05, low: 0, very_low: 0.10 },
          demand_rates: { high: 0.05, medium: 0.025, low: 0 },
          dynamic_price_expiry: 3.hours.ago.utc
        }
      end

      before do
        service
        product.reload
      end

      it "updates the product's dynamic price" do
        expect(product.dynamic_price).to eq(115)
      end

      it "updates the product's demand level" do
        expect(product.demand_level).to eq(:high)
      end

      it "updates the product's inventory level" do
        expect(product.inventory_level).to eq(:very_low)
      end

      it "resets the current demand count" do
        expect(product.current_demand_count).to eq(0)
        expect(product.previous_demand_count).to eq(10)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe AdjustProductPriceService do
  let(:service) { described_class.call(product.id) }

  describe ".call" do
    context "when the product is not found" do
      it "returns an error message" do
        result = described_class.call(9999)
        expect(result.error).to eq("Product not found")
      end
    end

    context "when the product is high in demand" do
      let!(:product) { create(:product, current_price: 100.0, demand_score: 60) }

      it "increases the product price by 5% and resets the demand score" do
        result = service
        expect(result).to be_success
        expect(result.payload.current_price).to eq(105.0)
        expect(result.payload.demand_score).to eq(0)
        expect(result.payload.price_logs.last.source).to eq("high demand")
      end
    end

    context "when the product inventory is low" do
      let!(:product) { create(:product, current_price: 100.0, inventory: { total_inventory: 100, total_reserved: 90 }) }

      it "increases the product price by 10%" do
        result = service
        expect(result).to be_success
        expect(result.payload.current_price).to eq(110.0)
        expect(result.payload.price_logs.last.source).to eq("low inventory")
      end
    end

    context "when the product inventory is high" do
      let!(:product) { create(:product, current_price: 100.0, inventory: { total_inventory: 100, total_reserved: 10 }) }

      it "decreases the product price by 5%" do
        result = service
        expect(result).to be_success
        expect(result.payload.current_price).to eq(95.0)
        expect(result.payload.price_logs.last.source).to eq("high inventory")
      end
    end
  end

  after do
    Mongoid.truncate!
  end
end

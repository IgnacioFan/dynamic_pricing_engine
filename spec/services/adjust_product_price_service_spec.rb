require 'rails_helper'

RSpec.describe AdjustProductPriceService do
  let(:service) { described_class.new(product.id) }

  describe ".call" do
    context "when the product price is locked" do
      let!(:product) { create(:product, current_price: 100.0, demand_score: 0, price_unlocked_at: price_unlocked_at) }
      let(:price_unlocked_at) { Time.now.utc + 1.hour }

      it "returns a failure message" do
        result = service.call
        expect(result.error).to eq("Product price is locked now")
      end
    end

    context "when the product is high in demand" do
      let!(:product) { create(:product, current_price: 100.0, demand_score: 60) }

      it "increases the product price by 5% and resets the demand score" do
        result = service.call
        expect(result).to be_success
        expect(result.payload.current_price).to eq(105.0)
        expect(result.payload.demand_score).to eq(0)
        expect(result.payload.price_logs.last.source).to eq("high demand")
      end
    end

    context "when the product inventory is low" do
      let!(:product) { create(:product, current_price: 100.0, inventory: { total_inventory: 100, total_reserved: 90 }) }

      it "increases the product price by 10%" do
        result = service.call
        expect(result).to be_success
        expect(result.payload.current_price).to eq(110.0)
        expect(result.payload.price_logs.last.source).to eq("low inventory")
      end
    end

    context "when the product inventory is high" do
      let!(:product) { create(:product, current_price: 100.0, inventory: { total_inventory: 100, total_reserved: 10 }) }

      it "decreases the product price by 5%" do
        result = service.call
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

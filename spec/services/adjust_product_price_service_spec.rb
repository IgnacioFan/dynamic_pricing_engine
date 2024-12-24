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

    context "when the product is high in demand" do
      context "when demand_price is nil" do
        let!(:product) { create(:product, default_price: 100, current_demand_count: 65, previous_demand_count: 60) }

        it "increases the product demand price" do
          result = service.payload
          expect(result.demand_price).to eq(105.0)
        end
      end

      context "when demand_price is not nil" do
        let!(:product) { create(:product, demand_price: 110, current_demand_count: 70, previous_demand_count: 65) }

        it "increases the product demand price" do
          result = service.payload
          expect(result.demand_price).to eq(115.0)
        end
      end
    end

    context "when the product inventory is low" do
      context "when inventory_price is nil" do
        let!(:product) { create(:product, default_price: 100.0, inventory: { total_inventory: 100, total_reserved: 90 }) }

        it "increases the product inventory price" do
          result = service.payload
          expect(result.inventory_price).to eq(105.0)
        end
      end

      context "when inventory_price is not nil" do
        let!(:product) { create(:product, inventory_price: 110.0, inventory: { total_inventory: 100, total_reserved: 90 }) }

        it "increases the product inventory price" do
          result = service.payload
          expect(result.inventory_price).to eq(115.0)
        end
      end
    end

    context "when the product inventory is high" do
      context "when inventory_price is nil" do
        let!(:product) { create(:product, default_price: 100.0, inventory: { total_inventory: 100, total_reserved: 10 }) }

        it "decreases the inventory price" do
          result = service.payload
          expect(result.inventory_price).to eq(95.0)
        end
      end

      context "when inventory_price is nil" do
        let!(:product) { create(:product, inventory_price: 90.0, inventory: { total_inventory: 100, total_reserved: 10 }) }

        it "decreases the inventory price" do
          result = service.payload
          expect(result.inventory_price).to eq(85.0)
        end
      end
    end

    context "when the product inventory is high and the price reaches the bottom line" do
      let!(:product) { create(:product, inventory_price: 60.0, inventory: { total_inventory: 100, total_reserved: 10 }) }

      it "decreases the inventory price" do
        result = service.payload
        expect(result.inventory_price).to eq(60.0)
      end
    end
  end
end

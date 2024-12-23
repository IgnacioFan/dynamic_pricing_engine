require 'rails_helper'

RSpec.describe AdjustProductPriceService do
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
        let!(:product) { create(:product, default_price: 100, curr_added_frequency: 65, prev_added_frequency: 60) }

        it "increases the product demand price" do
          result = service.payload
          expect(result.demand_price).to eq(110.0)
        end
      end

      context "when demand_price is not nil" do
        let!(:product) { create(:product, demand_price: 110, curr_added_frequency: 70, prev_added_frequency: 65) }

        it "increases the product demand price" do
          result = service.payload
          expect(result.demand_price).to eq(121.0)
        end
      end
    end

    context "when the product inventory is low" do
      context "when inventory_price is nil" do
        let!(:product) { create(:product, default_price: 100.0, inventory: { total_inventory: 100, total_reserved: 90 }) }

        it "increases the product inventory price" do
          result = service.payload
          expect(result.inventory_price).to eq(110.0)
        end
      end

      context "when inventory_price is not nil" do
        let!(:product) { create(:product, inventory_price: 110.0, inventory: { total_inventory: 100, total_reserved: 90 }) }

        it "increases the product inventory price" do
          result = service.payload
          expect(result.inventory_price).to eq(121.0)
        end
      end
    end

    context "when the product inventory is high" do
      context "when inventory_price is nil" do
        let!(:product) { create(:product, default_price: 100.0, inventory: { total_inventory: 100, total_reserved: 10 }) }

        it "decreases the inventory price" do
          result = service.payload
          expect(result.inventory_price).to eq(90.0)
        end
      end

      context "when inventory_price is nil" do
        let!(:product) { create(:product, inventory_price: 90.0, inventory: { total_inventory: 100, total_reserved: 10 }) }

        it "decreases the inventory price" do
          result = service.payload
          expect(result.inventory_price).to eq(81.0)
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

  after do
    Mongoid.truncate!
  end
end

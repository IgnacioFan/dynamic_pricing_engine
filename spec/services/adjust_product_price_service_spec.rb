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

    context "when the product demand level is high" do
      context "and the inventory level is high" do
        let!(:product) do
          create(:product,
            default_price: 100,
            dynamic_price: 99,
            current_demand_count: 5,
            previous_demand_count: 1,
            total_inventory: 100,
            total_reserved: 10
          )
        end

        it {
          product = service.payload
          expect(product.dynamic_price).to eq(100.0) # select default_price
          expect(product.demand_level).to eq(:high)
          expect(product.inventory_level).to eq(:high)
        }
      end

      context "and the inventory level is medium" do
        let!(:product) do
          create(:product,
            default_price: 100,
            dynamic_price: 99,
            current_demand_count: 5,
            previous_demand_count: 1,
            total_inventory: 100,
            total_reserved: 50
          )
        end

        it {
          product = service.payload
          expect(product.dynamic_price).to eq(104.0) # select dynamic_price
          expect(product.demand_level).to eq(:high)
          expect(product.inventory_level).to eq(:medium)
        }
      end

      context "and the inventory level is low" do
        let!(:product) do
          create(:product,
            default_price: 100,
            dynamic_price: 99,
            current_demand_count: 5,
            previous_demand_count: 1,
            total_inventory: 100,
            total_reserved: 90
          )
        end

        it {
          product = service.payload
          expect(product.dynamic_price).to eq(109.0) # select dynamic_price
          expect(product.demand_level).to eq(:high)
          expect(product.inventory_level).to eq(:low)
        }
      end
    end

    context "when the product demand level is low" do
      context "and the inventory level is high" do
        let!(:product) do
          create(:product,
            default_price: 100,
            dynamic_price: 99,
            current_demand_count: 0,
            previous_demand_count: 10,
            total_inventory: 100,
            total_reserved: 10
          )
        end

        it {
          product = service.payload
          expect(product.dynamic_price).to eq(94.0) # select dynamic_price
          expect(product.demand_level).to eq(:low)
          expect(product.inventory_level).to eq(:high)
        }
      end

      context "and the inventory level is medium" do
        let!(:product) do
          create(:product,
            default_price: 100,
            dynamic_price: 99,
            current_demand_count: 0,
            previous_demand_count: 10,
            total_inventory: 100,
            total_reserved: 50
          )
        end

        it {
          product = service.payload
          expect(product.dynamic_price).to eq(99.0) # select dynamic_price
          expect(product.demand_level).to eq(:low)
          expect(product.inventory_level).to eq(:medium)
        }
      end

      context "and the inventory level is low" do
        let!(:product) do
          create(:product,
            default_price: 100,
            dynamic_price: 99,
            current_demand_count: 0,
            previous_demand_count: 10,
            total_inventory: 100,
            total_reserved: 90
          )
        end

        it {
          product = service.payload
          expect(product.dynamic_price).to eq(104.0) # select dynamic_price
          expect(product.demand_level).to eq(:low)
          expect(product.inventory_level).to eq(:low)
        }
      end
    end

    context "when the product inventory is high and the price is close the price floor" do
      let!(:product) do
        create(:product,
          default_price: 100,
          dynamic_price: 99,
          price_floor: 95,
          current_demand_count: 0,
          previous_demand_count: 10,
          total_inventory: 100,
          total_reserved: 10
        )
      end

      it "decreases the inventory price" do
        product = service.payload
        expect(product.dynamic_price).to eq(99.0)
        expect(product.demand_level).to eq(:low)
        expect(product.inventory_level).to eq(:high)
      end
    end
  end
end

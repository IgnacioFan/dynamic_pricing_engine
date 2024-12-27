require 'rails_helper'

RSpec.describe Product, type: :model do
  describe '#dynamic_price' do
    let(:dynamic_price_expried_at) { 3.hours.ago.utc }

    context "When product is in high inventory" do
      let!(:product) { create(:product, default_price: 100.0, inventory_level: :high, demand_level: :low, dynamic_price_expried_at:) }

      it "returns the lowest price" do
        product.calculate_dynamic_price
        expect(product.dynamic_price).to eq(95.0)
        expect(product.dynamic_price_expried_at > dynamic_price_expried_at).to eq(true)
      end
    end

    context "When product is in medium inventory" do
      let!(:product) { create(:product, default_price: 100.0, inventory_level: :medium, demand_level: :low, dynamic_price_expried_at:) }

      it "returns the lowest price" do
        product.calculate_dynamic_price
        expect(product.dynamic_price).to eq(100.0)
        expect(product.dynamic_price_expried_at > dynamic_price_expried_at).to eq(true)
      end
    end

    context "When product is in low inventory" do
      let!(:product) { create(:product, default_price: 100.0, inventory_level: :low, demand_level: :low, dynamic_price_expried_at:) }

      it "returns the highest price" do
        product.calculate_dynamic_price
        expect(product.dynamic_price).to eq(105.0)
        expect(product.dynamic_price_expried_at > dynamic_price_expried_at).to eq(true)
      end
    end

    context "When product is in high demand" do
      let!(:product) { create(:product, default_price: 100.0, inventory_level: :low, demand_level: :high, dynamic_price_expried_at:) }
      it "returns the highest price" do
        expect(product.calculate_dynamic_price).to eq(110.0)
      end
    end

    context "When product price is above the competitor price" do
      let!(:product) { create(:product, default_price: 100.0, competitor_price: 108.0, inventory_level: :low, demand_level: :high, dynamic_price_expried_at:) }

      it "returns the highest price" do
        product.calculate_dynamic_price
        expect(product.dynamic_price).to eq(108.0)
        expect(product.dynamic_price_expried_at > dynamic_price_expried_at).to eq(true)
      end
    end

    context "When product price is close to the price floor" do
      let!(:product) { create(:product, default_price: 100, dynamic_price: 80, price_floor: 80, inventory_level: :high, demand_level: :low, dynamic_price_expried_at:) }

      it "returns the price over the price floor" do
        product.calculate_dynamic_price
        expect(product.dynamic_price).to eq(80.0)
        expect(product.dynamic_price_expried_at > dynamic_price_expried_at).to eq(true)
      end
    end

    context "When product price is close to the default price floor" do
      let!(:product) { create(:product, default_price: 100, dynamic_price: 50, inventory_level: :high, demand_level: :low, dynamic_price_expried_at:) }

      it "returns the price over the price floor" do
        product.calculate_dynamic_price
        expect(product.dynamic_price).to eq(50.0)
        expect(product.dynamic_price_expried_at > dynamic_price_expried_at).to eq(true)
      end
    end
  end

  describe "#set_inventory_level" do
    context "when inventory is below the low bar" do
      let!(:product) { create(:product, total_inventory: 100, total_reserved: 96) }

      it { expect(product.set_inventory_level).to eq(:low) }
    end

    context "when inventory is between the low and high bar" do
      let!(:product) { create(:product, total_inventory: 100, total_reserved: 50) }

      it { expect(product.set_inventory_level).to eq(:medium) }
    end

    context "when inventory is above the high bar" do
      let!(:product) { create(:product, total_inventory: 100, total_reserved: 10) }

      it { expect(product.set_inventory_level).to eq(:high) }
    end
  end

  describe "#set_demand_level" do
    context "when the current demand exceeds the previous demand" do
      let!(:product) { create(:product, current_demand_count: 10, previous_demand_count: 6) }

      it { expect(product.set_demand_level).to eq(:high) }
    end

    context "when the current demand is below the previous demand" do
      let!(:product) { create(:product, current_demand_count: 1, previous_demand_count: 6) }

      it { expect(product.set_demand_level).to eq(:low) }
    end

    context "when the previous demand is 0" do
      let!(:product) { create(:product, current_demand_count: 1) }

      it { expect(product.set_demand_level).to eq(:low) }
    end
  end

  describe '#available_inventory?' do
    let(:product) { create(:product, total_inventory: 10, total_reserved: 5) }

    context 'when the inventory is sufficient' do
      it { expect(product.available_inventory?(3)).to be true }
    end

    context 'when the inventory is insufficient' do
      it { expect(product.available_inventory?(6)).to be false }
    end

    context 'when the quantity is zero or negative' do
      it do
        expect(product.available_inventory?(0)).to be false
        expect(product.available_inventory?(-1)).to be false
      end
    end
  end
end

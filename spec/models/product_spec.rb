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

  describe 'callback' do
    context "When dynamic_price_period is 2" do
      let(:product) { create(:product, dynamic_price_period: 2) }

      it "set the dynamic_price_expried_at field to 2 hours later" do
        product_expiration = (Time.now.utc + 2.hours).strftime("%Y-%m-%d %H:%M:%S")
        expect(product.dynamic_price_expried_at.strftime("%Y-%m-%d %H:%M:%S")).to eq(product_expiration)
      end
    end
  end

  describe '#dynamic_price_v2' do
    let(:dynamic_price_period) { 3 }
    let(:competitor_price) { nil }
    let!(:product) do
      create(
        :product,
        competitor_price:,
        default_price: 100.0,
        dynamic_price: 95.0,
        inventory_level: :very_low,
        demand_level: :high,
        inventory_rates: { very_high: -0.30, high: -0.15, medium: -0.05, low: 0, very_low: 0.10 },
        demand_rates: { high: 0.05, medium: 0.025, low: 0 },
        dynamic_price_expried_at:,
        dynamic_price_period:
      )
    end

    context "When product's price has not expired" do
      let(:dynamic_price_expried_at) { Time.now.utc + dynamic_price_period.hours }

      it "returns the current product price" do
        product.calculate_dynamic_price_v2
        expect(product.dynamic_price).to eq(95.0)
        expect(product.dynamic_price_expried_at).to eq(dynamic_price_expried_at)
      end
    end

    context "When product's price expired" do
      let(:dynamic_price_expried_at) { dynamic_price_period.hours.ago.utc }

      context "when product is in very low inventory level and high demand level" do
        it "returns the current product price" do
          product.calculate_dynamic_price_v2
          expect(product.dynamic_price).to eq(115.0)
          expect(product.dynamic_price_expried_at > dynamic_price_expried_at).to eq(true)
        end
      end

      context "when competitior price is lower than new product price" do
        let(:competitor_price) { 108.0 }

        it "returns the current product price" do
          product.calculate_dynamic_price_v2
          expect(product.dynamic_price).to eq(108.0)
          expect(product.dynamic_price_expried_at > dynamic_price_expried_at).to eq(true)
        end
      end
    end
  end

  describe "#inventory_factor" do
    let(:inventory_rates) { { very_high: -0.30, high: -0.15, medium: -0.05, low: 0, very_low: 0.10 } }

    context "when product's inventory level is very low" do
      let!(:product) { build(:product, default_price: 100, inventory_level: :very_low, inventory_rates:) }

      it { expect(product.inventory_factor).to eq(10) }
    end

    context "when product's inventory level is low" do
      let!(:product) { build(:product, default_price: 100, inventory_level: :low, inventory_rates:) }

      it { expect(product.inventory_factor).to eq(0) }
    end

    context "when product's inventory level is medium" do
      let!(:product) { build(:product, default_price: 100, inventory_level: :medium, inventory_rates:) }

      it { expect(product.inventory_factor).to eq(-5) }
    end

    context "when product's inventory level is high" do
      let!(:product) { build(:product, default_price: 100, inventory_level: :high, inventory_rates:) }

      it { expect(product.inventory_factor).to eq(-15) }
    end

    context "when product's inventory level is very high" do
      let!(:product) { build(:product, default_price: 100, inventory_level: :very_high, inventory_rates:) }

      it { expect(product.inventory_factor).to eq(-30) }
    end
  end

  describe "#set_inventory_level" do
    let(:inventory_thresholds) { { very_low: 0.95, low: 0.80, medium: 0.60, high: 0.40, very_high: 0.20 } }

    context "when inventory is in very low level" do
      let!(:product) { build(:product, inventory_thresholds:, total_inventory: 100, total_reserved: 95) }

      it { expect(product.set_inventory_level).to eq(:very_low) }
    end

    context "when inventory is in low level" do
      let!(:product) { build(:product, inventory_thresholds:, total_inventory: 100, total_reserved: 80) }

      it { expect(product.set_inventory_level).to eq(:low) }
    end

    context "when inventory is in medium level" do
      let!(:product) { build(:product, inventory_thresholds:, total_inventory: 100, total_reserved: 60) }

      it { expect(product.set_inventory_level).to eq(:medium) }
    end

    context "when inventory is in high level" do
      let!(:product) { build(:product, inventory_thresholds:, total_inventory: 100, total_reserved: 40) }

      it { expect(product.set_inventory_level).to eq(:high) }
    end

    context "when inventory is in very high level" do
      let!(:product) { build(:product, inventory_thresholds:, total_inventory: 100, total_reserved: 10) }

      it { expect(product.set_inventory_level).to eq(:very_high) }
    end
  end

  describe "#demand_factor" do
    let(:demand_rates) { { high: 0.10, medium: 0.05, low: 0 } }

    context "when the product demand level is high" do
      let!(:product) { build(:product, default_price: 100, demand_level: :high, demand_rates:) }

      it { expect(product.demand_factor).to eq(10) }
    end

    context "when the current demand is equql to the previous demand" do
      let!(:product) { build(:product, default_price: 100, demand_level: :medium, demand_rates:) }

      it { expect(product.demand_factor).to eq(5) }
    end

    context "when the current demand is below the previous demand" do
      let!(:product) { build(:product, default_price: 100, demand_level: :low, demand_rates:) }

      it { expect(product.demand_factor).to eq(0) }
    end
  end

  describe "#set_demand_level" do
    context "when the current demand exceeds the previous demand" do
      let!(:product) { build(:product, current_demand_count: 10, previous_demand_count: 6) }

      it { expect(product.set_demand_level).to eq(:high) }
    end

    context "when the current demand is equql to the previous demand" do
      let!(:product) { build(:product, current_demand_count: 6, previous_demand_count: 6) }

      it { expect(product.set_demand_level).to eq(:medium) }
    end

    context "when the current demand is below the previous demand" do
      let!(:product) { build(:product, current_demand_count: 1, previous_demand_count: 6) }

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

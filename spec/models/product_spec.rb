require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'callback' do
    context "when a product is initialized" do
      let(:product) { build(:product) }

      it { expect(product.dynamic_price).to be_nil }

      it { expect(product.dynamic_price_expiry).to be_nil }
    end

    context "When a product is created" do
      let(:product) { create(:product) }

      it { expect(product.dynamic_price).to eq(50.0) }

      it { expect(product.dynamic_price_expiry).not_to be_nil }
    end
  end

  describe '#calculate_dynamic_price' do
    context "when the dynamic price has not expired" do
      let(:dynamic_price_expiry) { Time.now.utc + 2.hours }
      let!(:product) { create(:product, dynamic_price: 75.0, dynamic_price_expiry:) }

      it "returns the current dynamic price" do
        product.calculate_dynamic_price
        expect(product.dynamic_price).to eq(75.0)
      end
    end

    context "when there is no competitor price" do
      let!(:product) {
        create(:product,
          default_price: 100,
          demand_level: :low,
          demand_rates: { high: 0.10, medium: 0, low: 0 },
          inventory_level: :very_high,
          inventory_rates: { very_high: -0.30, high: -0.15, medium: -0.05, low: 0, very_low: 0.10 },
          dynamic_price_expiry: 1.hours.ago.utc
        )
      }

      it "returns the inventory price as the dynamic price" do
        product.calculate_dynamic_price
        expect(product.dynamic_price).to eq(70.0)
      end
    end

    context "when the product is in low demand and very high inventory" do
      let!(:product) {
        create(:product,
          default_price: 100,
          competitor_price: competitor_price,
          demand_level: :low,
          demand_rates: { high: 0.10, medium: 0, low: 0 },
          inventory_level: :very_high,
          inventory_rates: { very_high: -0.30, high: -0.15, medium: -0.05, low: 0, very_low: 0.10 },
          dynamic_price_expiry: 1.hours.ago.utc
        )
      }

      context "when the competitor's price is lower than the inventory price" do
        let(:competitor_price) { 55.0 }

        it "returns the inventory price as the dynamic price" do
          product.calculate_dynamic_price
          expect(product.dynamic_price).to eq(70.0)
        end
      end

      context "when the competitor's price is higher than the inventory price" do
        let(:competitor_price) { 85.0 }

        it "returns the competitor's price as the dynamic price" do
          product.calculate_dynamic_price
          expect(product.dynamic_price).to eq(85.0)
        end
      end
    end

    context "when the product is in high demand and high inventory" do
      let!(:product) {
        create(:product,
          default_price: 100,
          competitor_price: competitor_price,
          demand_level: :high,
          demand_rates: { high: 0.10, medium: 0, low: 0 },
          inventory_level: :high,
          inventory_rates: { very_high: -0.30, high: -0.15, medium: -0.05, low: 0, very_low: 0.10 },
          dynamic_price_expiry: 1.hours.ago.utc
        )
      }

      context "when the competitor's price is greater than the inventory price" do
        let(:competitor_price) { 95 }

        it "returns the competitor's price plus the demand factor as the dynamic price" do
          product.calculate_dynamic_price
          expect(product.dynamic_price).to eq(105.0)
        end
      end

      context "when the competitor's price is less than the inventory price" do
        let(:competitor_price) { 80 }

        it "returns the inventory price plus the demand factor as the dynamic price" do
          product.calculate_dynamic_price
          expect(product.dynamic_price).to eq(95.0)
        end
      end
    end
  end

  describe '#reset_current_demand_count' do
    context "when the dynamic price has not expired" do
      let!(:product) { create(:product, current_demand_count: 10, previous_demand_count: 0, dynamic_price_expiry: Time.now.utc + 1.hours) }

      it "don't reset the counter" do
        product.reset_current_demand_count
        expect(product.current_demand_count).to eq(10)
        expect(product.previous_demand_count).to eq(0)
      end
    end

    context "when the current demand count is greater than 0" do
      let!(:product) { create(:product, current_demand_count: 5, previous_demand_count: 12, dynamic_price_expiry: 1.hours.ago.utc) }

      it "reset the counter" do
        product.reset_current_demand_count
        expect(product.current_demand_count).to eq(0)
        expect(product.previous_demand_count).to eq(5)
      end
    end

    context "when the current demand count is equal to 0" do
      let!(:product) { create(:product, current_demand_count: 0, previous_demand_count: 10, dynamic_price_expiry: 1.hours.ago.utc) }

      it "don't reset the counter" do
        product.reset_current_demand_count
        expect(product.current_demand_count).to eq(0)
        expect(product.previous_demand_count).to eq(10)
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

  describe "#update_inventory_level" do
    let(:inventory_thresholds) { { very_low: 0.95, low: 0.80, medium: 0.60, high: 0.40, very_high: 0.20 } }

    context "when inventory is in very low level" do
      let!(:product) { build(:product, inventory_thresholds:, total_inventory: 100, total_reserved: 95) }

      it { expect(product.update_inventory_level).to eq(:very_low) }
    end

    context "when inventory is in low level" do
      let!(:product) { build(:product, inventory_thresholds:, total_inventory: 100, total_reserved: 80) }

      it { expect(product.update_inventory_level).to eq(:low) }
    end

    context "when inventory is in medium level" do
      let!(:product) { build(:product, inventory_thresholds:, total_inventory: 100, total_reserved: 60) }

      it { expect(product.update_inventory_level).to eq(:medium) }
    end

    context "when inventory is in high level" do
      let!(:product) { build(:product, inventory_thresholds:, total_inventory: 100, total_reserved: 40) }

      it { expect(product.update_inventory_level).to eq(:high) }
    end

    context "when inventory is in very high level" do
      let!(:product) { build(:product, inventory_thresholds:, total_inventory: 100, total_reserved: 10) }

      it { expect(product.update_inventory_level).to eq(:very_high) }
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

  describe "#update_demand_level" do
    context "when the current demand exceeds the previous demand" do
      let!(:product) { build(:product, current_demand_count: 10, previous_demand_count: 6) }

      it { expect(product.update_demand_level).to eq(:high) }
    end

    context "when the current demand is equql to the previous demand" do
      let!(:product) { build(:product, current_demand_count: 6, previous_demand_count: 6) }

      it { expect(product.update_demand_level).to eq(:medium) }
    end

    context "when the current demand is below the previous demand" do
      let!(:product) { build(:product, current_demand_count: 1, previous_demand_count: 6) }

      it { expect(product.update_demand_level).to eq(:low) }
    end
  end

  describe '#available_inventory?' do
    let(:product) { build(:product, total_inventory: 10, total_reserved: 5) }

    context 'when the inventory is sufficient' do
      it { expect(product.available_inventory?(5)).to be true }

      it { expect(product.available_inventory?(-5)).to be true }
    end

    context 'when the inventory is insufficient' do
      it { expect(product.available_inventory?(6)).to be false }

      it { expect(product.available_inventory?(-6)).to be false }
    end
  end
end

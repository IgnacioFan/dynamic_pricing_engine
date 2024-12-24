require 'rails_helper'

RSpec.describe Product, type: :model do
  describe '#dynamic_price' do
    context "When product is in high demand" do
      let!(:product) { create(:product, demand_price: 105, competitor_price: 102, current_demand_count: 62, previous_demand_count: 50) }
      it "returns the highest price" do
        expect(product.dynamic_price).to eq(105.0)
      end
    end

    context "When product is in high inventory" do
      let!(:product) { create(:product, inventory_price: 95, competitor_price: 99, inventory: { total_inventory: 100, total_reserved: 10 }) }
      it "returns the lowest price" do
        expect(product.dynamic_price).to eq(95.0)
      end
    end

    context "When product is in low inventory" do
      let!(:product) { create(:product, inventory_price: 105, competitor_price: 102, inventory: { total_inventory: 100, total_reserved: 81 }) }
      it "returns the highest price" do
        expect(product.dynamic_price).to eq(105.0)
      end
    end

    context "When product is stable" do
      let!(:product) { create(:product, competitor_price: 102, inventory: { total_inventory: 100, total_reserved: 50 }) }
      it "returns the highest price" do
        expect(product.dynamic_price).to eq(102.0)
      end
    end
  end

  describe '#available_inventory?' do
    let(:product) { create(:product, inventory: { total_inventory: 10, total_reserved: 5 }) }

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

  describe "#high_demand_product?" do
    context "the current pointer is over 60" do
      let(:product) { build(:product, current_demand_count: 62, previous_demand_count: 50) }
      it { expect(product.high_demand_product?).to be(true) }
    end

    context "the difference between current pointer and previous pointer is greater than 5" do
      let(:product) { build(:product, current_demand_count: 65, previous_demand_count: 60) }
      it { expect(product.high_demand_product?).to be(true) }
    end

    context "the difference between current pointer and previous pointer is less than 5" do
      let(:product) { build(:product, current_demand_count: 96, previous_demand_count: 92) }
      it { expect(product.high_demand_product?).to be(false) }
    end
  end

  describe "#low_inventory_level?" do
    context "inventory level is below low bar" do
      let(:product) { build(:product, inventory: { total_inventory: 100, total_reserved: 90 }) }
      it { expect(product.low_inventory_level?).to be(true) }
    end

    context "inventory level is above low bar" do
      let(:product) { build(:product, inventory: { total_inventory: 100, total_reserved: 10 }) }
      it { expect(product.low_inventory_level?).to be(false) }
    end
  end

  describe "#high_inventory_level?" do
    context "inventory level is above high bar" do
      let(:product) { build(:product, inventory: { total_inventory: 100, total_reserved: 10 }) }
      it { expect(product.high_inventory_level?).to be(true) }
    end

    context "inventory level is below high bar" do
      let(:product) { build(:product, inventory: { total_inventory: 100, total_reserved: 70 }) }
      it { expect(product.high_inventory_level?).to be(false) }
    end
  end

  describe '.high_inventory_products' do
    let!(:high_inventory_product) { create(:product, name: "high", inventory: { total_inventory: 100, total_reserved: 10 }) }
    let!(:low_inventory_product) { create(:product, name: "low", inventory: { total_inventory: 100, total_reserved: 30 }) }
    let!(:empty_inventory_product) { create(:product, name: "empty", inventory: { total_inventory: 0, total_reserved: 0 }) }

    it 'returns high inventory products' do
      result = Product.high_inventory_products
      expect(result).to include(high_inventory_product)
      expect(result).not_to include(low_inventory_product)
      expect(result).not_to include(empty_inventory_product)
    end
  end

  describe '.high_demand_products' do
    let!(:high_demand_product) { create(:product, name: "high", current_demand_count: 70, previous_demand_count: 60) }
    let!(:low_demand_product) { create(:product, name: "low", current_demand_count: 50, previous_demand_count: 45) }
    let!(:midium_demand_product) { create(:product, name: "midium", current_demand_count: 65, previous_demand_count: 61) }

    it 'returns only high demand products' do
      result = Product.high_demand_products
      expect(result).to include(high_demand_product)
      expect(result).not_to include(low_demand_product)
      expect(result).not_to include(midium_demand_product)
    end

    it 'demand updates periodically' do
      midium_demand_product.update!(current_demand_count: 70, previous_demand_count: 65)

      result = Product.high_demand_products
      expect(result).to include(high_demand_product)
      expect(result).to include(midium_demand_product)
    end
  end
end

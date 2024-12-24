require 'rails_helper'

RSpec.describe Product, type: :model do
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
      let(:product) { build(:product, curr_added_frequency: 62, prev_added_frequency: 50) }
      it { expect(product.high_demand_product?).to be(true) }
    end

    context "the difference between current pointer and previous pointer is greater than 5" do
      let(:product) { build(:product, curr_added_frequency: 65, prev_added_frequency: 60) }
      it { expect(product.high_demand_product?).to be(true) }
    end

    context "the difference between current pointer and previous pointer is less than 5" do
      let(:product) { build(:product, curr_added_frequency: 96, prev_added_frequency: 92) }
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
      it { expect(product.low_inventory_level?).to be(false) }
    end

    context "inventory level is below high bar" do
      let(:product) { build(:product, inventory: { total_inventory: 100, total_reserved: 70 }) }
      it { expect(product.low_inventory_level?).to be(false) }
    end
  end

  after do
    Mongoid.truncate!
  end
end

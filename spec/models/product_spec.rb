require 'rails_helper'

RSpec.describe Product, type: :model do
  describe "#update_price" do
    let(:product_params) { { name: "Foo", category: "Bar" } }
    subject { described_class.new(product_params).update_price(price:, source:) }

    context "when the default price is empty" do
      let(:price) { 100 }
      let(:source) { "csv_imported" }

      it "returns a product" do
        product = subject

        expect(product.default_price).to eq(price)
        expect(product.current_price).to eq(price)

        latest_price_log = product.price_logs.first
        expect(latest_price_log.price).to eq(price)
        expect(latest_price_log.source).to eq(source)
      end
    end

    context "when the new price is not equal to the current price" do
      let(:product_params) { { name: "Foo", category: "Bar", default_price: default_price, current_price: default_price } }
      let(:default_price) { 100 }
      let(:price) { 120 }
      let(:source) { "demand_increased" }

      it "returns a product" do
        product = subject

        expect(product.default_price).to eq(default_price)
        expect(product.current_price).to eq(price)

        latest_price_log = product.price_logs.first
        expect(latest_price_log.price).to eq(price)
        expect(latest_price_log.source).to eq(source)
      end
    end

    context "when the current price is same" do
      let(:product_params) { { name: "Foo", category: "Bar", default_price: 100, current_price: 100 } }
      let(:price) { 100 }
      let(:source) { "" }

      it { expect(subject).to eq(nil) }
    end
  end

  describe "#update_inventory" do
    let(:product_params) { { name: "Foo", category: "Bar" } }
    subject { described_class.new(product_params).update_inventory(change:, type:) }

    context "when the inventory is empty" do
      let(:type) { "csv_imported" }

      context "when change is positive" do
        let(:change) { 100 }
        it "returns a product" do
          product = subject

          expect(product.inventory).to eq("total_available" => 100, "total_reserved" => 0)

          latest_inventory_log = product.inventory_logs.last
          expect(latest_inventory_log.change).to eq(change)
          expect(latest_inventory_log.type).to eq(type)
        end
      end

      context "when change is negative" do
        let(:change) { -100 }
        it { expect(subject).to eq(nil) }
      end
    end

    context "when the total inventory is available" do
      let(:product_params) { { name: "Foo", category: "Bar", inventory: { total_available: 10, total_reserved: 0 } } }
      let(:type) { "order_placed" }

      context "when change is positive" do
        let(:change) { 3 }
        it "returns a product" do
          product = subject

          expect(product.inventory).to eq("total_available" => 10, "total_reserved" => 3)

          latest_inventory_log = product.inventory_logs.first
          expect(latest_inventory_log.change).to eq(change)
          expect(latest_inventory_log.type).to eq(type)
        end
      end

      context "when change is negative" do
        let(:change) { -3 }
        it { expect(subject).to eq(nil) }
      end
    end

    context "when the change is over the total inventory" do
      let(:product_params) { { name: "Foo", category: "Bar", inventory: { total_available: 10, total_reserved: 0 } } }
      let(:change) { 11 }
      let(:type) { "order_placed" }

      it { expect(subject).to eq(nil) }
    end
  end

  after do
    Mongoid.truncate!
  end
end

require "rails_helper"

RSpec.describe CompareCompetitorPriceService do
  let!(:product_1) { create(:product, name: "Foo", category: "Test", current_price: 100.0) }
  let!(:product_2) { create(:product, name: "Bar", category: "Test", current_price: 200.0) }

  describe ".call" do
    subject { described_class.call(competitor_products) }

    context "when competitor price is higher by more than 5%" do
      let(:competitor_products) {
        [
          { name: "Foo", category: "Test", price: 110.0 }, # over 5%
          { name: "Bar", category: "Test", price: 209.0 }  # within 5%
        ]
      }

      it "updates the current product price" do
        subject
        expect(product_1.reload.current_price).to eq(110)
        expect(product_2.reload.current_price).to eq(200)
      end
    end

    context "when competitor price is lower by more than 5%" do
      let(:competitor_products) { [ { name: "Foo", category: "Test", price: 90.0 } ] }
      let(:competitor_products) {
        [
          { name: "Foo", category: "Test", price: 90.0 }, # over 5%
          { name: "Bar", category: "Test", price: 191.0 }  # within 5%
        ]
      }

      it "updates the current product price" do
        subject
        expect(product_1.reload.current_price).to eq(90)
        expect(product_2.reload.current_price).to eq(200)
      end
    end

    context "when competitor product not found" do
      let(:competitor_products) { [ { name: "Test", category: "Test", price: 50.0 } ] }

      it "no change" do
        subject
        expect(product_1.reload.current_price).to eq(100)
        expect(product_2.reload.current_price).to eq(200)
      end
    end

    context "when competitor price is invalid" do
      let(:competitor_products) {
        [
          { name: "Foo", category: "Test", price: 0.0 },
          { name: "Bar", category: "Test", price: 0.0 }
        ]
      }

      it "does not update the product price" do
        subject
        expect(product_1.reload.current_price).to eq(100)
        expect(product_2.reload.current_price).to eq(200)
      end
    end
  end

  after do
    Mongoid.truncate!
  end
end

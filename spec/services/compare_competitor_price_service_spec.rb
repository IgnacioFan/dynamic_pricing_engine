require "rails_helper"

RSpec.describe CompareCompetitorPriceService, type: :service do
  let!(:product_1) { create(:product, name: "Foo", category: "Test", competitor_price: 100.0) }
  let!(:product_2) { create(:product, name: "Bar", category: "Test", competitor_price: 200.0) }

  describe ".call" do
    subject { described_class.call(competitor_products) }

    context "when there are competitor products" do
      let(:competitor_products) {
        [
          { name: "Foo", category: "Test", price: 110.0 },
          { name: "Bar", category: "Test", price: 210.0 }
        ]
      }

      it "updates product competitor price" do
        subject
        expect(product_1.reload.competitor_price).to eq(110.0)
        expect(product_2.reload.competitor_price).to eq(210.0)
      end
    end

    context "when there is no competitor product" do
      let(:competitor_products) { [ { name: "Test", category: "Test", price: 50.0 } ] }

      it "products no change" do
        subject
        expect(product_1.reload.competitor_price).to eq(100.0)
        expect(product_2.reload.competitor_price).to eq(200.0)
      end
    end

    context "when competitor price is invalid" do
      let(:competitor_products) {
        [
          { name: "Foo", category: "Test", price: 0.0 },
          { name: "Bar", category: "Test", price: 0.0 }
        ]
      }

      it "products no change" do
        subject
        expect(product_1.reload.competitor_price).to eq(100.0)
        expect(product_2.reload.competitor_price).to eq(200.0)
      end
    end
  end
end

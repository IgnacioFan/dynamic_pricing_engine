require "rails_helper"

RSpec.describe CompareCompetitorPriceService do
  describe ".call" do
    let(:competitor_produts) do
      [
        { name: "Foo", category: "Test", price: 110.0 },
        { name: "Bar", category: "Test", price: 70.0 }
      ]
    end
    subject { described_class.call(competitor_produts) }

    context "when all products are priced lower than competitor's products" do
      let!(:product_1) { create(:product, name: "Foo", category: "Test", current_price: 100.0) }
      let!(:product_2) { create(:product, name: "Bar", category: "Test", current_price: 50.0) }

      it "updates all product prices successfully" do
        result = subject
        expect(result).to be_success
        expect(product_1.reload.current_price.to_f).to eq(110)
        expect(product_2.reload.current_price.to_f).to eq(70)
      end
    end

    context "when no product matches the competitor's products" do
      let!(:product_1) { create(:product, name: "A", category: "Test", current_price: 100.0) }
      let!(:product_2) { create(:product, name: "B", category: "Test", current_price: 50.0) }

      it "no product updates" do
        result = subject
        expect(result).to be_success
        expect(product_1.reload.current_price.to_f).to eq(100)
        expect(product_2.reload.current_price.to_f).to eq(50)      end
    end
  end

  after do
    Mongoid.truncate!
  end
end

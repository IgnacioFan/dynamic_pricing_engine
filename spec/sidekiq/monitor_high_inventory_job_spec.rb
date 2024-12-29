require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe MonitorHighInventoryJob, type: :job do
  before do
    Sidekiq::Testing.fake!
    allow(AdjustProductPriceService).to receive(:call)
  end

  describe "#perform" do
    context "when there is low inventory products" do
      let!(:medium_inventory_product) { create(:product, name: "low inventory", inventory_level: :medium) }
      let!(:high_inventory_product) { create(:product, name: "high inventory", inventory_level: :high) }
      let!(:very_high_inventory_product) { create(:product, name: "very high inventory", inventory_level: :very_high) }

      it "filters high inventory products" do
        MonitorHighInventoryJob.new.perform

        expect(AdjustProductPriceService).to have_received(:call).with(very_high_inventory_product.id.to_s).once
        expect(AdjustProductPriceService).to have_received(:call).with(high_inventory_product.id.to_s).once
        expect(AdjustProductPriceService).not_to have_received(:call).with(medium_inventory_product.id.to_s)
      end

      after do
        Mongoid.truncate!
      end
    end
  end

  describe "sidekiq options" do
    it "sets retry to 2" do
      expect(described_class.sidekiq_options["retry"]).to eq(2)
    end
  end
end

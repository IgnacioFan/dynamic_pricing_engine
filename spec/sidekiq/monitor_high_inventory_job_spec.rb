require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe MonitorHighInventoryJob, type: :job do
  before do
    Sidekiq::Testing.fake!
    allow(AdjustProductPriceService).to receive(:call)
  end

  describe "#perform" do
    context "when there is low inventory products" do
      let!(:low_inventory_product) { create(:product, name: "low inventory", inventory_level: :low) }
      let!(:high_inventory_product) { create(:product, name: "high inventory", inventory_level: :high) }

      it "filters high inventory products" do
        MonitorHighInventoryJob.new.perform

        expect(AdjustProductPriceService).to have_received(:call).with(high_inventory_product.id.to_s).once
        expect(AdjustProductPriceService).not_to have_received(:call).with(low_inventory_product.id.to_s)
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

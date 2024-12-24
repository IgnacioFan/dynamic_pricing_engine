require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe MonitorHighInventoryJob, type: :job do
  before do
    Sidekiq::Testing.fake!
  end

  before do
    allow(AdjustProductPriceService).to receive(:call)
  end

  describe "#perform" do
    it "enqueues the job" do
      expect { described_class.perform_async }.to change(described_class.jobs, :size).by(1)
    end

    context "when there is low inventory products" do
      let!(:low_inventory_product) { create(:product, name: "low inventory", inventory: { total_inventory: 100, total_reserved: 90 }) }
      let!(:high_inventory_product) { create(:product, name: "high inventory", inventory: { total_inventory: 100, total_reserved: 10 }) }

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

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe TrackProductDemandJob, type: :job do
  describe "#perform" do
    context "when the job runs successfully" do
      before do
        allow(AdjustProductPriceService).to receive(:call)
      end

      it "calls AdjustProductPriceService" do
        described_class.new.perform(9999)
        expect(AdjustProductPriceService).to have_received(:call).with("9999")
        described_class.drain
      end
    end
  end

  describe "sidekiq options" do
    it "sets retry to 2" do
      expect(described_class.sidekiq_options["retry"]).to eq(2)
    end
  end
end

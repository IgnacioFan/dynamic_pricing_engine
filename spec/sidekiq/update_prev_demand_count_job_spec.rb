require 'rails_helper'

RSpec.describe UpdatePrevDemandCountJob, type: :job do
  before { Sidekiq::Testing.fake! }

  context "when there is a high demand product" do
    let!(:high_demand_product) { create(:product, name: "high demand", current_demand_count: 70, previous_demand_count: 60) }
    let!(:low_demand_product) { create(:product, name: "low demand", current_demand_count: 50, previous_demand_count: 45) }

    let(:subjuct) { described_class.new.perform }

    it 'updates the previous_demand_count for high demand products' do
      expect { subjuct }.to change { high_demand_product.reload.previous_demand_count }.from(60).to(70)
    end

    it 'skip update for low demand products' do
      expect { subjuct }.not_to change { low_demand_product.reload.previous_demand_count }
    end

    after do
      Mongoid.truncate!
    end
  end

  describe "sidekiq options" do
    it "sets retry to 2" do
      expect(described_class.sidekiq_options["retry"]).to eq(2)
    end
  end
end

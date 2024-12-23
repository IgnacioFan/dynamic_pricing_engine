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

  after do
    Mongoid.truncate!
  end
end

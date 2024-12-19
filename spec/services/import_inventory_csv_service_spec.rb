require "rails_helper"
require "csv"

RSpec.describe ImportInventoryCsvService do
  describe ".call" do
    subject { described_class.call(csv_file.path) }

    context "when CSV is valid" do
      let(:csv_file) do
        Tempfile.new([ "test", ".csv" ]).tap do |f|
          f.write("NAME,CATEGORY,DEFAULT_PRICE,QTY\n")
          f.write("Foo,Category 1,10,100\n")
          f.write("Bar,Category 2,20,200\n")
          f.rewind
        end
      end

      it "imports all products successfully" do
        expect { subject }.to change { Product.count }.by(2)

        product = Product.find_by(name: "Foo")
        expect(product.category).to eq("Category 1")
        expect(product.default_price).to eq(10)
        expect(product.current_price).to eq(10)
        expect(product.price_logs.size).to eq(1)
        expect(product.inventory).to eq("total_available" => 100, "total_reserved" => 0)
        expect(product.inventory_logs.size).to eq(1)
      end
    end

    context "when CSV file has invalid headers" do
      let(:csv_file) do
        Tempfile.new([ "test", ".csv" ]).tap do |f|
          f.write("INVALID_HEADER\n")
          f.write("Product,Category,30,300\n")
          f.rewind
        end
      end

      it "returns an error" do
        result = subject

        expect(result).not_to be_success
        expect(result.error).to eq("Invalid headers in csv")
      end
    end
  end

  after do
    csv_file.close
    csv_file.unlink
    Mongoid.truncate!
  end
end

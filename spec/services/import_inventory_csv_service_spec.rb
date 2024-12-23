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
        result = subject.payload

        expect(result[0].name).to eq("Foo")
        expect(result[1].name).to eq("Bar")
        expect(result[0].category).to eq("Category 1")
        expect(result[1].category).to eq("Category 2")
        expect(result[0].default_price).to eq(10.0)
        expect(result[1].default_price).to eq(20.0)
        expect(result[0].inventory).to eq("total_inventory" => 100, "total_reserved" => 0)
        expect(result[1].inventory).to eq("total_inventory" => 200, "total_reserved" => 0)
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

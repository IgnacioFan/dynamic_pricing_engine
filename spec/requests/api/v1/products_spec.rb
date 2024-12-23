require 'rails_helper'

RSpec.describe "Products API", type: :request do
  describe "POST /api/v1/products/import" do
    let(:file_format) { 'text/csv' }
    let(:csv_file) { fixture_file_upload('valid_inventory.csv', file_format) }
    let(:product_1) { build(:product, name: "Foo", default_price: 100, inventory: { total_inventory: 100, total_reserved: 0 }) }
    let(:product_2) { build(:product, name: "Bar", default_price: 200, inventory: { total_inventory: 200, total_reserved: 0 }) }
    let(:service_result) { double(success?: true, payload: [ product_1, product_2 ]) }

    before do
      allow(ImportInventoryCsvService).to receive(:call).and_return(service_result)
    end

    context "when the file is valid and service succeeds" do
      it "returns status ok (200)" do
        post import_api_v1_products_path, params: { file: csv_file }

        expect(response).to have_http_status(:created)
        parsed_response = JSON.parse(response.body, symbolize_names: true)[:products]
        expect(parsed_response[0][:name]).to eq(product_1.name)
        expect(parsed_response[1][:name]).to eq(product_2.name)
        expect(parsed_response[0][:dynamic_price]).to eq(product_1.default_price)
        expect(parsed_response[1][:dynamic_price]).to eq(product_2.default_price)
        expect(parsed_response[0][:total_inventory]).to eq(product_1.inventory[:total_inventory])
        expect(parsed_response[1][:total_inventory]).to eq(product_2.inventory[:total_inventory])
      end
    end

    context "when the file format is not csv" do
      let(:file_format) { 'text/plain' }

      it "returns status unprocessable entity (422)" do
        post import_api_v1_products_path, params: { file: csv_file }

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)).to eq({ "error" => "Invalid file format (only csv)" })
      end
    end

    context "when the file is not provided" do
      it "returns status unprocessable entity (422)" do
        post import_api_v1_products_path

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ "error" => "File is required" })
      end
    end
  end
end

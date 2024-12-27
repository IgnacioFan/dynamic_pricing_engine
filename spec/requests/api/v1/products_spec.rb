require 'rails_helper'

RSpec.describe "Products API", type: :request do
  describe "GET /api/v1/products" do
    let(:product_1) { build(:product, name: "Foo", dynamic_price: 100.0, total_inventory: 100, total_reserved: 0) }
    let(:product_2) { build(:product, name: "Bar", dynamic_price: 200.0, total_inventory: 200, total_reserved: 0) }

    before { allow(Product).to receive(:all).and_return([ product_1, product_2 ]) }

    context "when products exist" do
      it "returns status ok (200)" do
        get api_v1_products_path

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body, symbolize_names: true)[:products]
        expect(parsed_response[0][:name]).to eq(product_1.name)
        expect(parsed_response[1][:name]).to eq(product_2.name)
        expect(parsed_response[0][:dynamic_price]).to eq(product_1.dynamic_price)
        expect(parsed_response[1][:dynamic_price]).to eq(product_2.dynamic_price)
        expect(parsed_response[0][:total_inventory]).to eq(product_1.total_inventory)
        expect(parsed_response[1][:total_inventory]).to eq(product_2.total_inventory)
      end
    end
  end

  describe "GET /api/v1/products/:id" do
    let(:product) { build(:product, name: "Foo", dynamic_price: 100.0, total_inventory: 100, total_reserved: 0) }

    before { allow(Product).to receive(:find).and_return(product) }

    context "when product exists" do
      it "returns status ok (200)" do
        get api_v1_product_path(product.id)

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body, symbolize_names: true)
        expect(parsed_response[:name]).to eq(product.name)
        expect(parsed_response[:dynamic_price]).to eq(product.dynamic_price)
        expect(parsed_response[:total_inventory]).to eq(product.total_inventory)
      end
    end
  end

  describe "POST /api/v1/products/import" do
    let(:file_format) { 'text/csv' }
    let(:csv_file) { fixture_file_upload('valid_inventory.csv', file_format) }
    let(:product_1) { build(:product, name: "Foo", dynamic_price: 100.0, total_inventory: 100, total_reserved: 0) }
    let(:product_2) { build(:product, name: "Bar", dynamic_price: 200.0, total_inventory: 200, total_reserved: 0) }
    let(:service_result) { double(success?: true, payload: [ product_1, product_2 ]) }

    before { allow(ImportInventoryCsvService).to receive(:call).and_return(service_result) }

    context "when the file is valid" do
      it "returns status created (201)" do
        post import_api_v1_products_path, params: { file: csv_file }

        expect(response).to have_http_status(:created)
        parsed_response = JSON.parse(response.body, symbolize_names: true)[:products]
        expect(parsed_response[0][:name]).to eq(product_1.name)
        expect(parsed_response[1][:name]).to eq(product_2.name)
        expect(parsed_response[0][:dynamic_price]).to eq(product_1.dynamic_price)
        expect(parsed_response[1][:dynamic_price]).to eq(product_2.dynamic_price)
        expect(parsed_response[0][:total_inventory]).to eq(product_1.total_inventory)
        expect(parsed_response[1][:total_inventory]).to eq(product_2.total_inventory)
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

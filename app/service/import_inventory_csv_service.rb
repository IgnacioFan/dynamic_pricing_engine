require "csv"

class ImportInventoryCsvService < ApplicationService
  HEADER = %w[NAME CATEGORY DEFAULT_PRICE QTY].freeze

  def initialize(csv_file)
    @csv = CSV.read(csv_file)
    @products = []
  end

  def call
    return failure("Invalid headers in csv") unless valid_header?

    process_csv
    success(@products)
  end

  private

  def process_csv
    @csv.each_with_index do |row, index|
      next if index == 0 # skip headers

      product = Product.find_or_initialize_by(name: row[0].to_s, category: row[1].to_s)
      next if product.persisted?

      product.assign_attributes(
        default_price: row[2].to_f,
        inventory: {
          total_inventory: row[3].to_i,
          total_reserved: 0
        }
      )
      product.save!
      @products << product
    end
  end

  def valid_header?
    @csv.first == HEADER
  end
end

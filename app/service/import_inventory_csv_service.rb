require "csv"

class ImportInventoryCsvService < ApplicationService
  HEADER = %w[NAME CATEGORY DEFAULT_PRICE QTY].freeze

  def initialize(csv_file)
    @csv = CSV.read(csv_file)
  end

  def call
    return failure("Invalid headers in csv") unless valid_header?

    handle_csv
    success("Complete!")
  end

  private

  def handle_csv
    @csv.each_with_index do |row, index|
      next if index == 0 # skip headers
      Product.create!(product_mapping(row))
    end
  end

  def valid_header?
    @csv.first == HEADER
  end

  def product_mapping(row)
    {
      name: row[0],
      category: row[1]&.to_s,
      default_price: row[2]&.to_f,
      inventory: {
        total_available: row[3]&.to_i,
        total_reserved: 0
      }
    }
  end
end

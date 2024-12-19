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

      product = Product.new(
        name: row[0],
        category: row[1]&.to_s,
      )
      product = product.update_price(
        price: row[2]&.to_f,
        source: :csv_imported,
        auto_save: false
      )
      product = product.update_inventory(
        change: row[3]&.to_i,
        type: :csv_imported,
        auto_save: false
      )
      product.save!
    end
  end

  def valid_header?
    @csv.first == HEADER
  end
end

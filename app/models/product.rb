class Product
  include Mongoid::Document
  include Mongoid::Timestamps

  INVENTORY_LOW_BAR = 0.2.freeze
  INVENTORY_HIGH_BAR = 0.8.freeze
  HIGH_DEMAND_BAR = 60.freeze

  field :name, type: String
  field :category, type: String

  field :competitor_price, type: BigDecimal
  field :default_price, type: BigDecimal
  field :demand_price, type: BigDecimal
  field :inventory_price, type: BigDecimal

  field :total_inventory, type: Integer, default: 0
  field :total_reserved, type: Integer, default: 0

  # use current_demand_count and previous_demand_count to track if the product is high in demand
  field :current_demand_count, type: Integer, default: 0
  field :previous_demand_count, type: Integer, default: 0

  index({ name: 1, category: 1 }, { unique: true })

  validates :name, presence: true
  validates :name, uniqueness: { scope: :category }
  validates :category, presence: true

  def dynamic_price
    if high_demand_product?
      [ competitor_price, default_price, demand_price ].compact.max
    elsif low_inventory_level?
      [ competitor_price, default_price, demand_price, inventory_price ].compact.max
    elsif high_inventory_level?
      [ competitor_price, default_price, demand_price, inventory_price ].compact.min
    else
      [ competitor_price, default_price ].compact.max
    end
  end

  def available_inventory?(quantity)
    return false if quantity <= 0

    self.total_reserved + quantity <= self.total_inventory
  end

  def high_demand_product?
    return false if current_demand_count < HIGH_DEMAND_BAR
    current_demand_count - previous_demand_count >= 5
  end

  def low_inventory_level?
    total_inventory = self.total_inventory.to_f
    total_reserved = self.total_reserved.to_f
    return false if total_inventory.zero?

    (total_inventory - total_reserved) / total_inventory < INVENTORY_LOW_BAR
  end

  def high_inventory_level?
    total_inventory = self.total_inventory.to_f
    total_reserved = self.total_reserved.to_f
    return false if total_inventory.zero?

    (total_inventory - total_reserved) / total_inventory > INVENTORY_HIGH_BAR
  end

  def self.high_inventory_products
    Product.where(
      :"total_inventory".gt => 0,
      :$expr => {
        :$gt => [
          { :$divide => [
              { :$subtract => [
                "$total_inventory",
                "$total_reserved"
                ]
              },
              "$total_inventory"
            ]
          },
          INVENTORY_HIGH_BAR
        ]
      }
    )
  end

  def self.high_demand_products
    Product.where(
      :"current_demand_count".gt => HIGH_DEMAND_BAR,
      :$expr => {
        :$gte => [
          {
            :$subtract => [
              "$current_demand_count",
              "$previous_demand_count"
            ]
          }, 5
        ]
      }
    )
  end

  def self.trigger_track_product_demand_jobs(product_ids)
    return if Rails.env.test?
    product_ids.each do |id|
      TrackProductDemandJob.perform_async(id)
    end
  end
end

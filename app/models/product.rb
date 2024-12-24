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

  # use current_demand_count and previous_demand_count to track if the product is high in demand
  field :current_demand_count, type: Integer, default: 0
  field :previous_demand_count, type: Integer, default: 0

  field :inventory, type: Hash, default: { total_inventory: 0, total_reserved: 0 }

  validates :name, presence: true
  validates :name, uniqueness: { scope: :category }
  validates :category, presence: true

  def dynamic_price
    [ competitor_price, default_price, demand_price, inventory_price ].compact.max
  end

  def available_inventory?(quantity)
    return false if quantity <= 0

    total_reserved = inventory[:total_reserved] + quantity
    total_reserved <= inventory[:total_inventory]
  end

  def update_current_demand_count(quantity)
    self.current_demand_count = ((self.inventory[:total_reserved] + quantity.to_f)/self.inventory[:total_inventory] * 100).ceil
    save!
  end

  def high_demand_product?
    return false if current_demand_count < HIGH_DEMAND_BAR
    current_demand_count - previous_demand_count >= 5
  end

  def low_inventory_level?
    total_inventory = inventory[:total_inventory].to_f
    total_reserved = inventory[:total_reserved].to_f
    return false if total_inventory.zero?

    (total_inventory - total_reserved) / total_inventory < INVENTORY_LOW_BAR
  end

  def high_inventory_level?
    total_inventory = inventory[:total_inventory].to_f
    total_reserved = inventory[:total_reserved].to_f
    return false if total_inventory.zero?

    (total_inventory - total_reserved) / total_inventory > INVENTORY_HIGH_BAR
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
end

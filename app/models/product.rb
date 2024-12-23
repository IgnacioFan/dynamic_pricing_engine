class Product
  include Mongoid::Document
  include Mongoid::Timestamps

  INVENTORY_LOW_BAR = 0.2.freeze
  INVENTORY_HIGH_BAR = 0.8.freeze

  field :name, type: String
  field :category, type: String

  field :competitor_price, type: BigDecimal
  field :default_price, type: BigDecimal
  field :demand_price, type: BigDecimal
  field :inventory_price, type: BigDecimal

  # use demand_score to calculate if product is high in demand
  field :demand_score, type: Integer, default: 0

  field :curr_added_frequency, type: Integer, default: 0
  field :prev_added_frequency, type: Integer, default: 0

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

  def update_demand_score(quantity, auto_save: true)
    self.demand_score = ((self.inventory[:total_reserved] + quantity.to_f)/self.inventory[:total_inventory] * 100).ceil
    save! if auto_save
  end

  def high_demand_product?
    return false if curr_added_frequency < 60
    curr_added_frequency - prev_added_frequency >= 5
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
end

class Product
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :category, type: String

  field :competitor_price, type: BigDecimal
  field :default_price, type: BigDecimal
  field :demand_price, type: BigDecimal
  field :inventory_price, type: BigDecimal

  field :current_price, type: BigDecimal
  # use demand_score to calculate if product is high in demand
  field :demand_score, type: Integer, default: 0

  field :inventory, type: Hash, default: { total_inventory: 0, total_reserved: 0 }

  embeds_many :price_logs, class_name: "PriceLog"
  embeds_many :inventory_logs, class_name: "InventoryLog"

  validates :name, presence: true
  validates :name, uniqueness: { scope: :category }
  validates :category, presence: true

  def dynamic_price
    [ competitor_price, default_price, demand_price, inventory_price ].compact.max
  end

  def update_price(price:, source:, auto_save: true)
    return unless price != self.current_price

    self.price_logs.build(
      price: price,
      source: source
    )

    self.default_price = price if self.default_price.blank?
    self.current_price = price

    save! if auto_save
    self
  end

  # change can be either positive or nagetive
  def update_inventory(change:, type:, order_id: nil, auto_save: true)
    return unless change != 0 && (zero_inventory?(change) || available_inventory?(change))

    self.inventory_logs.build(
      change: change,
      type: type,
      order_id: order_id
    )

    if zero_inventory?(change)
      self.inventory[:total_inventory] = change
    else
      self.inventory[:total_reserved] += change
    end

    save! if auto_save
    self
  end

  def zero_inventory?(change)
    change > 0 && self.inventory[:total_inventory] == 0
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
end

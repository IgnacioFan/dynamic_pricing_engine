class Product
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :category, type: String
  field :default_price, type: BigDecimal
  field :current_price, type: BigDecimal, default: -> { default_price }

  field :inventory, type: Hash, default: { total_available: 0, total_reserved: 0 }

  embeds_many :price_logs, class_name: "PriceLog"
  embeds_many :inventory_logs, class_name: "InventoryLog"

  validates :name, presence: true
  validates :name, uniqueness: { scope: :category }
  validates :category, presence: true

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
      self.inventory[:total_available] = change
    else
      self.inventory[:total_reserved] += change
    end

    save! if auto_save
    self
  end

  def zero_inventory?(change)
    change > 0 && self.inventory[:total_available] == 0
  end

  def available_inventory?(change)
    (self.inventory[:total_reserved] + change <= self.inventory[:total_available]) &&
    (self.inventory[:total_reserved] + change >= 0)
  end
end

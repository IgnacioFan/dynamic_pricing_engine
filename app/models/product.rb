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
end

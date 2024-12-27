class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  # For inventory_level field
  INVENTORY_LOW_BAR = 0.2.freeze
  INVENTORY_HIGH_BAR = 0.8.freeze
  # For dynamic_price field
  DEMAND_PRICE_INCR_RATE = 0.05.freeze
  INVENTORY_PRICE_INCR_RATE = 0.05.freeze
  INVENTORY_PRICE_DECR_RATE = 0.05.freeze
  # For price_floor field
  DEFAULT_PRICE_FLOOR_RATE = 0.5.freeze

  field :name, type: String
  field :category, type: String

  field :competitor_price, type: BSON::Decimal128
  field :default_price, type: BSON::Decimal128
  field :dynamic_price, type: BSON::Decimal128
  field :dynamic_price_expried_at, type: DateTime, default: -> { Time.now.utc + 3.hours }

  field :price_floor, type: BSON::Decimal128

  field :inventory_level, type: Symbol, default: :high
  field :demand_level, type: Symbol, default: :low

  field :total_inventory, type: Integer, default: 0
  field :total_reserved, type: Integer, default: 0

  # use current_demand_count and previous_demand_count to track if the product is high in demand
  field :current_demand_count, type: Integer, default: 0
  field :previous_demand_count, type: Integer, default: 0

  index({ name: 1, category: 1 }, { unique: true })

  validates :name, presence: true
  validates :name, uniqueness: { scope: :category }
  validates :category, presence: true
  validates :inventory_level, inclusion: { in: [ :low, :medium, :high ] }
  validates :demand_level, inclusion: { in: [ :low, :high ] }

  before_save :set_price_floor, :set_default_dynamic_price

  def calculate_dynamic_price
    return dynamic_price if Time.now.utc <= dynamic_price_expried_at

    inventory_price = case inventory_level
    when :high
      # decrease the price if the product's inventory level is high
      dynamic_price - (default_price * INVENTORY_PRICE_DECR_RATE)
    when :medium
      dynamic_price
    when :low
      # increase the price if the product's inventory level is low
      dynamic_price + (default_price * INVENTORY_PRICE_INCR_RATE)
    end
    # prevent the dynamic price from lowering the price floor
    if inventory_price < price_floor
      inventory_price = dynamic_price
    end

    demand_adjusted_price = if high_demand?
      # increase the price if the product is frequently added to carts or placed order
      [ inventory_price + (default_price * DEMAND_PRICE_INCR_RATE), default_price ].compact.max
    elsif low_demand_low_inventory?
      [ inventory_price, default_price ].compact.max
    else
      [ inventory_price, default_price ].compact.min
    end

    self.dynamic_price_expried_at = Time.now.utc + 3.hours
    self.dynamic_price = [ demand_adjusted_price, competitor_price ].compact.min
  end

  def set_inventory_level
    if total_inventory.zero?
      self.inventory_level = :high
    else
      available_ratio = (total_inventory - total_reserved).to_f / total_inventory
      self.inventory_level = case available_ratio
      when 0.0...INVENTORY_LOW_BAR
        :low
      when INVENTORY_LOW_BAR...INVENTORY_HIGH_BAR
        :medium
      else
        :high
      end
    end
  end

  def set_demand_level
    self.demand_level = if previous_demand_count.zero?
      :low
    else
      current_demand_count > previous_demand_count ? :high : :low
    end
  end

  def high_demand?
    self.demand_level == :high
  end

  def low_demand_low_inventory?
    self.demand_level == :low && self.inventory_level == :low
  end

  def available_inventory?(quantity)
    return false if quantity <= 0

    self.total_reserved + quantity <= self.total_inventory
  end

  def self.trigger_track_product_demand_jobs(product_ids)
    return if Rails.env.test?
    product_ids.each do |id|
      TrackProductDemandJob.perform_async(id)
    end
  end

  private

  def set_price_floor
    self.price_floor ||= default_price * DEFAULT_PRICE_FLOOR_RATE
  end

  def set_default_dynamic_price
    self.dynamic_price ||= default_price
  end
end

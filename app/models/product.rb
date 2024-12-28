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

  field :price_floor, type: BSON::Decimal128

  field :inventory_level, type: Symbol, default: :high
  field :demand_level, type: Symbol, default: :low

  field :total_inventory, type: Integer, default: 0
  field :total_reserved, type: Integer, default: 0

  # use dynamic_price_expried_at to prevent price fluctuation
  field :dynamic_price_expried_at, type: DateTime
  # use dynamic_price_period to set the next price expiry
  field :dynamic_price_period, type: Integer, default: 3
  # use inventory_rates to calculate inventory_factor
  field :inventory_rates, type: Hash, default: { very_high: -0.30, high: -0.15, medium: -0.05, low: 0, very_low: 0.10 }
  # use demand_rates to calculate demand_factor
  field :demand_rates, type: Hash, default: { high: 0.05, medium: 0.025, low: 0 }
  # use inventory_thresholds to scope the product's inventory level
  field :inventory_thresholds, type: Hash, default: { very_low: 95, low: 80, medium: 60, high: 40, very_high: 20 }
  # use current_demand_count and previous_demand_count to scope product's demand level
  field :current_demand_count, type: Integer, default: 0
  field :previous_demand_count, type: Integer, default: 0

  index({ name: 1, category: 1 }, { unique: true })

  validates :name, presence: true
  validates :name, uniqueness: { scope: :category }
  validates :category, presence: true
  validates :inventory_level, inclusion: { in: [ :very_low, :low, :medium, :high, :very_high ] }
  validates :demand_level, inclusion: { in: [ :low, :medium, :high ] }

  before_save :set_price_floor, :set_default_dynamic_price
  before_save :set_dynamic_price_expried_at


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

  def calculate_dynamic_price_v2
    return if Time.now.utc <= dynamic_price_expried_at

    new_price = default_price + inventory_factor + demand_factor

    self.dynamic_price_expried_at = Time.now.utc + dynamic_price_period.hours
    self.dynamic_price = [ new_price, competitor_price ].compact.min
  end

  def inventory_factor
    case inventory_level
    when :very_high
      default_price * inventory_rates[:very_high]
    when :high
      default_price * inventory_rates[:high]
    when :medium
      default_price * inventory_rates[:medium]
    when :low
      default_price * inventory_rates[:low]
    when :very_low
      default_price * inventory_rates[:very_low]
    end
  end

  def demand_factor
    case demand_level
    when :high
      default_price * demand_rates[:high]
    when :medium
      default_price * demand_rates[:medium]
    when :low
      default_price * demand_rates[:low]
    end
  end

  def set_inventory_level
    inventory_ratio = total_reserved.to_f / total_inventory

    self.inventory_level = case inventory_ratio
    when inventory_thresholds[:very_low]...1
      :very_low
    when inventory_thresholds[:low]...inventory_thresholds[:very_low]
      :low
    when inventory_thresholds[:medium]...inventory_thresholds[:low]
      :medium
    when inventory_thresholds[:high]...inventory_thresholds[:medium]
      :high
    else
      :very_high
    end
  end

  def set_demand_level
    self.demand_level = if current_demand_count > previous_demand_count
      :high
    elsif current_demand_count == previous_demand_count
      :medium
    else
      :low
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

  def set_dynamic_price_expried_at
    self.dynamic_price_expried_at ||= Time.now.utc + dynamic_price_period.hours
  end
end

class Product
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :category, type: String

  field :competitor_price, type: BSON::Decimal128
  field :default_price, type: BSON::Decimal128
  field :dynamic_price, type: BSON::Decimal128
  field :dynamic_price_expiry, type: DateTime
  field :dynamic_price_duration, type: Integer, default: 3 # in hours

  field :inventory_level, type: Symbol, default: :very_high
  field :demand_level, type: Symbol, default: :low
  field :total_inventory, type: Integer, default: 0
  field :total_reserved, type: Integer, default: 0

  # Configurable thresholds and rates
  field :inventory_rates, type: Hash, default: { very_high: -0.30, high: -0.15, medium: -0.05, low: 0, very_low: 0.10 }
  field :demand_rates, type: Hash, default: { high: 0.05, medium: 0.025, low: 0 }
  field :inventory_thresholds, type: Hash, default: { very_low: 95, low: 80, medium: 60, high: 40, very_high: 20 }

  # Demand tracking
  field :current_demand_count, type: Integer, default: 0
  field :previous_demand_count, type: Integer, default: 0

  index({ name: 1, category: 1 }, { unique: true })

  validates :name, presence: true
  validates :name, uniqueness: { scope: :category }
  validates :category, presence: true
  validates :inventory_level, inclusion: { in: [ :very_low, :low, :medium, :high, :very_high ] }
  validates :demand_level, inclusion: { in: [ :low, :medium, :high ] }
  validates :total_inventory, numericality: { greater_than_or_equal_to: 0 }
  validates :total_reserved, numericality: { greater_than_or_equal_to: 0 }

  before_create :calculate_dynamic_price
  before_create :initialize_dynamic_price_expiry

  def dynamic_price_expired?
    dynamic_price_expiry.nil? || Time.now.utc > dynamic_price_expiry
  end

  def calculate_dynamic_price
    return unless dynamic_price_expired?
    # the inventory_price is adjusted by inventory level,
    # and can be seen as a predictable profit range for the product
    inventory_price = default_price + inventory_factor
    # the adjustment_price takes the higher one as the result
    adjustment_price = [ inventory_price, competitor_price ].compact.max
    # the final price will be the adjustment price plus the demand factor to leaverge profits
    self.dynamic_price = adjustment_price + demand_factor
  end

  def reset_current_demand_count
    return unless dynamic_price_expired? && current_demand_count.positive?

    self.previous_demand_count = current_demand_count
    self.current_demand_count = 0
  end

  def reset_dynamic_price_expiry
    return unless dynamic_price_expired?

    self.dynamic_price_expiry = Time.now.utc + dynamic_price_duration.hours
  end

  def inventory_factor
    adjustment_rate = inventory_rates[inventory_level] || 0
    default_price * adjustment_rate
  end

  def demand_factor
    adjustment_rate = demand_rates[demand_level] || 0
    default_price * adjustment_rate
  end

  def update_inventory_level
    inventory_ratio = total_inventory.zero? ? 1 : total_reserved.to_f / total_inventory

    self.inventory_level = case inventory_ratio
    when inventory_thresholds[:very_low]...1                          then :very_low
    when inventory_thresholds[:low]...inventory_thresholds[:very_low] then :low
    when inventory_thresholds[:medium]...inventory_thresholds[:low]   then :medium
    when inventory_thresholds[:high]...inventory_thresholds[:medium]  then :high
    else                                                              :very_high
    end
  end

  def update_demand_level
    self.demand_level = if current_demand_count > previous_demand_count
      :high
    elsif current_demand_count == previous_demand_count
      :medium
    else
      :low
    end
  end

  def available_inventory?(quantity)
    self.total_reserved + quantity >= 0 && self.total_reserved + quantity <= self.total_inventory
  end

  def self.trigger_track_product_demand_jobs(product_ids)
    return if Rails.env.test?
    product_ids.each do |id|
      TrackProductDemandJob.perform_async(id.to_s)
    end
  end

  private

  def initialize_dynamic_price_expiry
    self.dynamic_price_expiry ||= Time.now.utc + dynamic_price_duration.hours
  end
end

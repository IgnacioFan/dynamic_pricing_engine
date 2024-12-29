FactoryBot.define do
  factory :product do
    name { "Foo" }
    category { "Test" }

    default_price { 100.0 }
    competitor_price { nil }

    inventory_rates { { very_high: -0.50, high: -0.25, medium: 0, low: 0.10, very_low: 0.20 } }
    inventory_level { :very_high }
    total_inventory { 100 }
    total_reserved { 0 }

    demand_rates { { high: 0.05, medium: 0, low: 0 } }
    demand_level { :low }
    current_demand_count { 0 }
    previous_demand_count { 0 }

    dynamic_price_duration { 1 }

    created_at { Time.now.utc }
    updated_at { Time.now.utc }
  end
end

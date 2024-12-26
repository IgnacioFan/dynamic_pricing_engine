FactoryBot.define do
  factory :product do
    name { "Foo" }
    category { "Test" }

    default_price { 100.0 }

    current_demand_count { 0 }
    previous_demand_count { 0 }

    total_inventory { 100 }
    total_reserved { 0 }

    created_at { Time.now.utc }
    updated_at { Time.now.utc }
  end
end

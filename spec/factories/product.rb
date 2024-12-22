FactoryBot.define do
  factory :product do
    name { "Foo" }
    category { "Test" }
    default_price { 100.0 }
    current_price { 100.0 }
    demand_score { 0 }

    inventory {
      {
        total_inventory: 100,
        total_reserved: 0
      }
    }
  end
end

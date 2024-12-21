FactoryBot.define do
  factory :product do
    name { "Foo" }
    category { "Test" }
    default_price { 100.0 }
    current_price { 100.0 }
  end
end

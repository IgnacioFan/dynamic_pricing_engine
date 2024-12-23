FactoryBot.define do
  factory :order do
    total_price { 0 }
    total_quantity { 0 }
    created_at { Time.now.utc }
    updated_at { Time.now.utc }
  end
end

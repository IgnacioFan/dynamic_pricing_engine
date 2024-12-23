FactoryBot.define do
  factory :order_item do
    association :product
    price { 10 }
    quantity { 1 }
  end
end

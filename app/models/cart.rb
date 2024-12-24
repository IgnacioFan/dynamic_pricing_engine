class Cart
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :cart_items
  has_one :order, class_name: "Order", inverse_of: :cart
end

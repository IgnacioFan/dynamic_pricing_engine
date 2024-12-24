class Cart
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :cart_items
end

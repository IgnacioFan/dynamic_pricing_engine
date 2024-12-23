class CartItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :product_id, type: BSON::ObjectId
  field :quantity, type: Integer, default: 0

  embedded_in :cart
  belongs_to :product

  def product_name
    product&.name
  end

  def product_total_reserved
    product&.inventory[:total_reserved]
  end

  def product_total_inventory
    product&.inventory[:total_inventory]
  end

  def product_total_price
    product&.price.to_f * quantity
  end
end

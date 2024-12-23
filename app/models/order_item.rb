class OrderItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :product_id, type: BSON::ObjectId
  field :price, type: BigDecimal
  field :quantity, type: Integer, default: 0

  embedded_in :order
  belongs_to :product
end

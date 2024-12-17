class InventoryLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :change, type: Integer
  field :type, type: String
  field :order_id, type: BSON::ObjectId

  embedded_in :product
end

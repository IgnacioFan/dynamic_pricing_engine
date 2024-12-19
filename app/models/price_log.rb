class PriceLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :price, type: BigDecimal
  field :source, type: String

  embedded_in :product
end

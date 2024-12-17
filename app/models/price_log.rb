class PriceLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :price, type: BigDecimal

  embedded_in :product
end

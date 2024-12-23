class Order
  include Mongoid::Document
  include Mongoid::Timestamps

  field :cart_id, type: BSON::ObjectId
  field :total_price, type: BigDecimal
  field :total_quantity, type: Integer

  embeds_many :order_items

  def self.place_order!(cart_id)
    cart = Cart.find(cart_id)
    order = new(cart_id:)

    errors = []
    total_price = 0
    total_quantity = 0

    errors << "Cart is empty" unless cart.cart_items.any?

    cart.cart_items.each do |item|
      product = item.product
      if product.available_inventory?(item.quantity)
        order.order_items.build(
          product_id: item.product_id,
          quantity: item.quantity,
          price: product.dynamic_price
        )
        total_price += product.dynamic_price * item.quantity
        total_quantity += item.quantity
      else
        errors << "Product #{product.name} (ID: #{item.product_id}) is unavailable"
      end
    end

    if errors.any?
      [ nil, errors.join(", ") ]
    else
      order.total_price = total_price
      order.total_quantity = total_quantity
      order.save!
      [ order, nil ]
    end
  rescue Mongoid::Errors::DocumentNotFound
    [ nil, "Cart not found" ]
  end
end

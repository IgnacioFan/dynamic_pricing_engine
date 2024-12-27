class Order
  include Mongoid::Document
  include Mongoid::Timestamps

  field :cart_id, type: BSON::ObjectId
  field :total_price, type: BigDecimal
  field :total_quantity, type: Integer

  embeds_many :order_items
  belongs_to :cart, class_name: "Cart", inverse_of: :order

  def self.place_order!(cart_id)
    cart = find_cart(cart_id)
    return [ nil, "Cart not found" ] unless cart

    order = find_or_initialize_order(cart)
    return [ nil, "Order has been created" ] if order.persisted?

    errors, caches, totals = process_cart_items(cart, order)
    return [ nil, errors.join(", ") ] if errors.any?

    store_order(order, totals, caches)
  end

  private

  def self.find_cart(cart_id)
    Cart.find(cart_id)
  rescue Mongoid::Errors::DocumentNotFound
    nil
  end

  def self.find_or_initialize_order(cart)
    cart.order.presence || new(cart_id: cart.id)
  end

  def self.process_cart_items(cart, order)
    errors = []
    caches = {}
    totals = { price: 0, quantity: 0 }

    if cart.cart_items.empty?
      errors << "Cart is empty"
      return [ errors, caches, totals ]
    end

    cart.cart_items.each do |item|
      product = item.product
      if product.available_inventory?(item.quantity)
        order.order_items.build(
          product_id: item.product_id,
          quantity: item.quantity,
          price: product.dynamic_price
        )
        totals[:price] += product.dynamic_price * item.quantity
        totals[:quantity] += item.quantity

        caches[product.id.to_s] = {
          update_one: {
            filter: { _id: product.id },
            update: {
              "$set" => {
                "current_demand_count" => product.current_demand_count + 1,
                "total_reserved" => product.total_reserved + item.quantity
              }
            }
          }
        }
      else
        errors << "Product #{product.name} (ID: #{item.product_id}) is insufficient"
      end
    end

    [ errors, caches, totals ]
  end

  def self.store_order(order, totals, caches)
    order.assign_attributes(total_price: totals[:price], total_quantity: totals[:quantity])

    if Product.collection.bulk_write(caches.values).acknowledged? && order.save!
      Product.trigger_track_product_demand_jobs(caches.keys)
      [ order, nil ]
    else
      [ nil, "Failed to save order" ]
    end
  end
end

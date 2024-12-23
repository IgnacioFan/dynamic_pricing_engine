class Cart
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :cart_items

  def add_product!(product_id, quantity)
    existing_item = find_cart_item(product_id)

    if existing_item.present?
      existing_item[:quantity] += quantity
    else
      cart_items << { product_id:, quantity: }
    end
  end

  def remove_item(item_id)
    return [ nil, "Cart is empty" ] if cart_items.empty?

    item = cart_items.find_by(id: item_id)

    item.destroy

    [ item, nil ]
  rescue Mongoid::Errors::DocumentNotFound
    [ nil, "Cart item not found" ]
  end

  private

  def find_cart_item(product_id)
    cart_items.detect { _1[:product_id] == product_id }
  end
end

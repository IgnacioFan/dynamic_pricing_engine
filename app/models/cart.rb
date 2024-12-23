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
    return "cart is empty" unless cart_items.any?

    item = @cart.cart_items.find(params[:product_id])
    return "cart item not found" unless item

    item.destroy
    nil
  end

  private

  def find_cart_item(product_id)
    cart_items.detect { _1[:product_id] == product_id }
  end
end

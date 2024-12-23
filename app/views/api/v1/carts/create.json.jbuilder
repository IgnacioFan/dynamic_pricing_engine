json.cart_id @cart.id
json.count   @cart.cart_items.size
json.cart_items @cart.cart_items, partial: "api/v1/cart_items/cart_item", as: :item

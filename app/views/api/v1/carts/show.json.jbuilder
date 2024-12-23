json.cart_id @cart.id
json.cart_items @cart.cart_items do |item|
  json.product_id item[:product_id]
  json.quantity item[:quantity]
end

json.id @order.id
json.cart_id @order.cart_id
json.total_quantity @order.total_quantity
json.total_price @order.total_price.to_f
json.created_at @order.created_at.strftime("%Y-%m-%d %H:%M:%S")
json.updated_at @order.updated_at.strftime("%Y-%m-%d %H:%M:%S")

json.order_items @order.order_items, partial: "order_item", as: :order_item

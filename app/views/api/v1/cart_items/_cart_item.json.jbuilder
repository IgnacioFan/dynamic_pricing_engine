json.id item.id
json.product_id item.product_id
json.product_name item.product_name
json.product_total_reserved item.product_total_reserved
json.product_total_inventory item.product_total_inventory
json.quantity item.quantity
json.product_url api_v1_product_url(item.product_id)
json.remove_item_url api_v1_cart_item_url(item.cart.id, item.id)

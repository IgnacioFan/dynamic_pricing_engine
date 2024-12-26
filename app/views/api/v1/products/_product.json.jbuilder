json.id product.id
json.name product.name
json.category product.category
json.dynamic_price product.dynamic_price.to_f
json.total_inventory product.total_inventory
json.total_reserved product.total_reserved
json.created_at product.created_at.strftime("%Y-%m-%d %H:%M:%S")
json.updated_at product.updated_at.strftime("%Y-%m-%d %H:%M:%S")

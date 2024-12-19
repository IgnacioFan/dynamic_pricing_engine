json.id product.id
json.name product.name
json.category product.category
json.dynamic_price do
  json.id dynamic_price.id
  json.price dynamic_price.price.to_f
end
json.inventory product.inventory

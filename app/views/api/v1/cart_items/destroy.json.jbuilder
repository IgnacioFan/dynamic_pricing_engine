json.cart_item do
  json.partial! partial: "cart_item", locals: { item: @cart_item }
end

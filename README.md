# Dynamic Pricing Engine

## Overview

This e-commerce platform is built with **Ruby on Rails**, **MongoDB**, **Redis**, and **Sidekiq** to feature realtime price adjustments. The dynamic pricing engine adjusts product prices in real-time based on demand, inventory levels, and competitor pricing.

### System Architecture

Client: Sends requests to the API server.

API Server: Handles requests, processes business logic, and interacts with MongoDB for data persistence.

Background Jobs: Runs via Sidekiq to ensure real-time updates to product prices.

### Dynamic Pricing

The platform uses four pricing fields to determine product dynamic pricing:
- `default_price`: The base price of the product.
- `demand_price`: Adjusted for products in high demand.
- `inventory_price`: Adjusted for inventory levels.
- `competitor_price`: Based on competitor product pricing.

### Dynamic Pricing Algorithm

The dynamic price of a product is determined using the following conditions:
- **High Demand**: Select the maximum price among `competitor_price`, `default_price`, and `demand_price` to increase profit margins.
- **High Inventory**: Select the maximum price among `competitor_price`, `default_price`, `demand_pric`, and `inventory_price` to encourage sales.
- **Low Inventory**: Select the maximum price among `competitor_price`, `default_price`, `demand_pric`, and `inventory_price` to optimize profitability.
- **Default Case**: Select the maximum price `competitor_price` and `default_price`, to ensure profit margins.

### Background Jobs

To ensure prices are updated in real-time, the platform relies on several background jobs:
- `CompareSinatraPricingJob`: Runs hourly to update competitor prices by retrieving data from third-party APIs.
- `MonitorHighInventoryJob`: Runs nightly to adjust inventory prices for high-inventory products to stimulate sales by lowering prices.
- `TrackProductDemandJob`: Triggers on cart creation, adding items to a cart, or order creation to adjust demand and inventory prices.
- `UpdatePrevDemandCountJob`: Runs every two hours to update historical demand data, determining whether a product remains in high demand.

How to know if a product is in high demand?

High demand is identified by comparing `current_demand_count` and `previous_demand_count`. If the difference between the two values is greater than or equal to **5**, the product is considered in high demand. The `UpdatePrevDemandCountJob` updates the `previous_demand_count` from the `current_demand_count` to ensure accurate tracking of demand trends.

## API Documentation

### `GET /api/v1/products`

Description: Lists all products with dynamic prices.

#### Request
```
GET /api/v1/products
```

#### Response
```
Status: 200 OK
{
  "products": [
    {
      "id": "BSON::ObjectId",
      "name": "Foo",
      "category": "Test"
      "dynamic_price": 120.0,
      "total_inventory": 100,
      "total_reserved": 20
      "created_at": "2024-12-24 01:00:00",
      "updated_at": "2024-12-24 04:00:00"
    }
  ]
}
```

### `GET /api/v1/products/:id`

Description: Retrieves details of a specific product.

#### Request
```
GET /api/v1/products/:id
```

#### Response
```
Status: 200 OK
{
  "id": "BSON::ObjectId",
  "name": "Foo",
  "category": "Test"
  "dynamic_price": 120.0,
  "total_inventory": 100,
  "total_reserved": 20
  "created_at": "2024-12-24 01:00:00",
  "updated_at": "2024-12-24 04:00:00"
}
```

### `POST /api/v1/products/import`

Description: Imports product data via CSV file.

#### Request
```
POST /api/v1/products/import
Headers: { "Content-Type": "multipart/form-data" }
Body:
{
  "file": <CSV file>
}
```

#### Response
```
Status: 201 Created
{
  "products": [
    {
      "id": "BSON::ObjectId",
      "name": "Foo",
      "category": "Test"
      "dynamic_price": 120.0,
      "total_inventory": 100,
      "total_reserved": 20
      "created_at": "2024-12-24 01:00:00",
      "updated_at": "2024-12-24 04:00:00"
    }
  ]
}
```

### `POST /api/v1/carts`

Description: Creates a shopping cart.

#### Request
```
POST /api/v1/carts
Headers: { "Content-Type": "application/json" }
Body:
{
  "cart": {
    "items": [
      {
        "product_id": "BSON::ObjectId",
        "quantity": 1
      }
    ]
  }
}
```

#### Response
```
Status: 201 Created
{
  "cart_id": "BSON::ObjectId",
  "count": 1,
  "cart_items": [
    {
      "id": "BSON::ObjectId",
      "product_id": "BSON::ObjectId",
      "product_name": "Foo",
      "product_total_reserved": 0,
      "product_total_inventory": 100,
      "quantity": 1
    }
  ]
}
```

### `POST /api/v1/carts/:cart_id/items`

Description: Adds items to a shopping cart.

#### Request
```
POST /api/v1/carts/:cart_id/items
Headers: { "Content-Type": "application/json" }
Body:
{
  "cart_item": {
    "product_id": "BSON::ObjectId",
    "quantity": 1
  }
}
```

#### Response
```
Status: 201 Created
{
  "cart_id": "BSON::ObjectId",
  "count": 2,
  "cart_items": [
    {
      "id": "BSON::ObjectId",
      "product_id": "BSON::ObjectId",
      "product_name": "Foo",
      "product_total_reserved": 0,
      "product_total_inventory": 100,
      "quantity": 1,
    },
    {
      "id": "BSON::ObjectId",
      "product_id": "BSON::ObjectId",
      "product_name": "Bar",
      "product_total_reserved": 10,
      "product_total_inventory": 80,
      "quantity": 1,
    }
  ]
}
```

### `DELETE /api/v1/carts/:cart_id/items/:id`

Description: Removes an item from the shopping cart.

#### Request
```
DELETE /api/v1/carts/:cart_id/items/:id
```

#### Response
```
Status: 200 OK
{
  "cart_item": {
    "id": "BSON::ObjectId",
    "product_id": "BSON::ObjectId",
    "product_name": "Foo",
    "product_total_reserved": 0,
    "product_total_inventory": 100,
    "quantity": 1,
  }
}
```

### `POST /api/v1/order`

Description: Creates an order from a cart.

#### Request
```
POST /api/v1/order
Headers: { "Content-Type": "application/json" }
Body:
{
  "cart_id": "BSON::ObjectId"
}
```

#### Response
```
Status: 201 Created
{
  "id": "BSON::ObjectId",
  "cart_id": "BSON::ObjectId",
  "total_quantity": 2,
  "total_price": 220.0,
  "created_at": "2024-12-24 01:00:00",
  "updated_at": "2024-12-24 04:00:00",
  "order_items": [
    {
      "product_id": "BSON::ObjectId",
      "product_name": "Foo",
      "quantity": 1,
      "price": 100.0
    },
    {
      "product_id": "BSON::ObjectId",
      "product_name": "Bar",
      "quantity": 1,
      "price": 120.0
    }
  ]
}
```

## How to Set Up Locally

### Setup Steps
1. Clone the Repository:
   ```
   git clone https://github.com/IgnacioFan/dynamic_pricing_engine.git
   cd dynamic-pricing-engine
   ```

2. Start the Application Using Docker Compose
   ```
   rails server
   ```
   This command will set up and run the application along with its dependencies.

3. Access the Application
   Open your browser and navigate to http://localhost:3000.

### Testing
1. Run Test Suite:
   ```
   rspec
   ```
2. Run Linting:
   ```
   rubocop
   ```



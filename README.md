# Dynamic Pricing Engine

## Overview

This e-commerce platform is built with **Ruby on Rails**, **MongoDB**, **Redis**, and **Sidekiq** to feature realtime price adjustments. The dynamic pricing engine adjusts product prices in real-time based on demand, inventory levels, and competitor pricing.

## System Architecture

### Ruby on Rails API Server
Handles client requests, processes business logic, and interacts with the MongoDB database for storing and retrieving persisted data.

### MongoDB
Document-based storage used to manage data like product and order data.

### Background Jobs
Runs via Sidekiq and Redis to maintain real-time price updates and process jobs like demand tracking and competitor price adjustments.

## Dynamic Pricing

The platform adjusts product pricing based on demand, inventory levels, and competitor pricing. The following fields are used in the pricing process:

- `default_price`: The base price of the product.
- `dynamic_price`: The adjusted price based on demand and inventory levels.
- `competitor_price`: Pricing data from competitors.
- `price_floor`: The minimum price for the product.

### Dynamic Pricing Algorithm

The `dynamic_price` is calculated considering the following factors:

#### step 1: Inventory Levels:
  - Prices are adjusted according to the inventory level: decreased for high inventory, increased for low inventory, and unchanged for medium inventory.
  - The adjusted price will not drop below the `price_floor`.

#### step 2: Demand Levels:
  - High demand leads to an increase in price.
  - For low demand: Products with low inventory maintain higher pricing; Products with high inventory prioritize lower pricing.

#### step 3: Competitor Pricing:
  - The final price is capped by the lower of the adjusted price and the `competitor_price`.

The adjusted `dynamic_price` is valid for **3 hours** to ensure price stability and prevent rapid fluctuations.

### Background Jobs

To ensure prices are updated in real-time, the platform relies on the following background jobs:
- `CompareSinatraPricingJob`: Runs hourly to update competitor prices by retrieving data from third-party APIs.
- `MonitorHighInventoryJob`: Runs every midnight to identify and reduce prices for high-inventory products, encouraging sales.
- `TrackProductDemandJob`: Triggers on cart creation, adding items to a cart, or order creation to adjust demand and inventory prices.
- `UpdatePrevDemandCountJob`: Runs every three hours to update historical demand data for high-demand products.

### High-Demand Tracking

Products are classified as high demand if they frequently appear in carts or orders. The system uses two fields to track demand trends:

- `current_demand_count`: Increments when a product is added to a cart or an order is created.
- `previous_demand_count`: Represents the highest demand count historically.

The `UpdatePrevDemandCountJob` ensures the `previous_demand_count` is always updated for high-demand products to reflect maximum historical demand.

## API Documentation

If you use Postman, download and import [Dynamic-Pricing.postman_collection.json](/doc/Dynamic-Pricing.postman_collection.json) to help you test API mannually.

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

Description: Imports product data via CSV file. [Sample CSV file](/doc/inventory.csv).

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
      "product_category": "Test",
      "product_dynamic_price": 100.0,
      "product_total_reserved": 0,
      "product_total_inventory": 50,
      "subtotal": 100.0,
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
      "product_category": "Test",
      "product_dynamic_price": 100.0,
      "product_total_reserved": 0,
      "product_total_inventory": 50,
      "subtotal": 100.0,
      "quantity": 1,
    },
    {
      "id": "BSON::ObjectId",
      "product_id": "BSON::ObjectId",
      "product_name": "Bar",
      "product_category": "Test",
      "product_dynamic_price": 200.0,
      "product_total_reserved": 10,
      "product_total_inventory": 80,
      "subtotal": 200.0,
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
    "product_category": "Test",
    "product_dynamic_price": 100.0,
    "product_total_reserved": 0,
    "product_total_inventory": 100,
    "subtotal": 100.0,
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
      "product_category": "Test",
      "quantity": 1,
      "price": 100.0
    },
    {
      "product_id": "BSON::ObjectId",
      "product_name": "Bar",
      "product_category": "Test",
      "quantity": 1,
      "price": 120.0
    }
  ]
}
```

## How to Set Up Locally

### Prerequisites

- Ruby version: `ruby-3.2.0` install already
- Docker installed already

### Setup Steps
1. Clone the Repository:
   ```
   git clone https://github.com/IgnacioFan/dynamic_pricing_engine.git
   cd dynamic-pricing-engine
   ```

2. Set Up Master Key and Credentials
  - Create a `master.key` file in the config directory.
  - Enter credentials.yml.enc to view the following credentials, run (`EDITOR="code --wait" rails credentials:edit`).
  - Note: If you haven't installed Rails under Ruby 3.2.0, you will need to run bundle install first.
    ```
    sinatra_pricing_api_key: ""
    sidekiqweb:
      username: ""
      password: ""
    ```

3. Build and Run the API server
   ```
   docker compose up -d
   ```
   This command will set up and run the application along with its dependencies.

4. Access the Application
  - Check if the API server is running (`localhost:3000/up`)
  - Open your terminal or [Postman](#api-documentation) to test the APIs.
  - Enter `localhost:3000/sidekiq`, username and password are in the credentials.yml.enc

### Testing
1. Run Test Suite:
   ```
   make test
   ```

2. Run individual Test :
   ```
   make test path="..."

   or

   make bash
   rspec spec/...
   ```

3. Access the API container environment
   ```
   make bash
   ```

3. Access the Rails console
   ```
   make console
   ```

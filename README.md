# TC Dynamic Pricing Engine

## Overview

TC Dynamic Pricing Engine is an ecommerce API built with **Ruby on Rails**, **MongoDB**, **Redis**, and **Sidekiq**. It supports real-time price adjustments based on:

- Demand: Prices increase when products are frequently added to carts or purchased.
- Inventory Levels: Prices decrease when inventory levels are high and increase when inventory is low.
- Competitor Prices: Prices adapt based on competitor pricing retrieved from a third-party API.

## How to Set Up Locally

### Prerequisites

- Ruby version: 3.2.0
- Docker

### Setup Steps
1. Clone the Repository:
   ```bash
   git clone https://github.com/IgnacioFan/dynamic_pricing_engine.git
   cd dynamic-pricing-engine
   ```

2. Set up `master.key`:
    The credentials for third-party APIs and Sidekiq web are stored in `config/credentials.yml.enc`. To access them, add a master.key file with the key c158f56e88b65c5db58647e2922799fb under the config directory. Right now, there is nothing sensitive, so it's fine to put the key in public. :)

    To edit credentials using VS Code:
    ```bash
    EDITOR="code --wait" rails credentials:edit
    ```

    Ensure bundle install is run if you just installed Ruby 3.2.0. The credentials.yml.enc file should look like this:
    ```bash
    sinatra_pricing_api_key: ""

    sidekiqweb:
      username: ""
      password: ""
    ```

3. Build and Run Services:
   ```bash
   docker compose up -d
   <!-- For logs, omit -d -->
   docker compose up
   ```

4. Access Services:

  - Use `make bash` to access the Rails container.
  - Use `make console` to open the Rails console.
  - Access the Sidekiq web at `localhost:3000/sidekiq` (enter **admin** for username and password).

### Testing

Tests are implemented using RSpec for unit, service, job, and request testing.

- Run all tests: `make test`
- Run specific tests: `make test path="spec/..."`. Alternatively, `make bash` access the Rails container and run: `rspec spec/...`.

## System Architecture

1. **Ruby on Rails**: Handles client requests, processes business logic, and interacts with MongoDB.
2. **MongoDB**: Stores product and order data in a document-based format.
3. **Background Jobs**: Powered by Sidekiq and Redis to enable price adjustments and job processing.

## Dynamic Pricing

### Pricing Fields

| Field              | Type              | Description                                      |
|--------------------|-------------------|--------------------------------------------------|
| `competitor_price` | Decimal | Price from competitors fetched via API.          |
| `default_price`    | Decimal | Base price set during product import.            |
| `dynamic_price`    | Decimal | Price calculated based on competitor's price, demand, and inventory. |

### Dynamic Pricing Algorithm

The `dynamic_price` is calculated considering the three steps:

1. calculate an inventory price:
A base price is decided by the product's inventory level. This provides a predictable profit range for the product.

2. calculate an adjustment price:
It compares the inventory price with the competitor's price. Generally, it takes the higher one as the result, unless the competitor's price is lower than the inventory price, in which case the inventory price is used.

3. Apply the demand factor to the adjustment price:
The final price takes the adjustment price and applies the demand factor to advance profits.

For example, product in high inventory and low demand scenarios.

| High Inventory & Low Demand   | Inventory Price | Adjustment Price | Final Price | Total |
|---------------------------------------------------------------------|-----------------|------------------|-------------|------|
| Default $100 <br> Competitor $50 <br> Inventory Factor -$20 <br> Demand Factor +$0 | $100 - 20 | $80 > $50 | $80 + 0 | $80 |
| Default $100 <br> Competitor $90 <br> Inventory Factor -$20 <br> Demand Factor +$0 | $100 - 20 | $80 < $90 | $90 + 0 | $90 |


### Background Jobs

| Job                        | Description                                                       |
|----------------------------|-------------------------------------------------------------------|
| `CompareSinatraPricingJob` | runs hourly to update competitor prices from third-party APIs.    |
| `MonitorHighInventoryJob`  | runs hourly to reduce prices for high-inventory products.      |
| `TrackProductDemandJob`    | triggered by events to adjust demand and inventory prices|

## API Documentation

If you use Postman, download and import [Dynamic-Pricing.postman_collection.json](/doc/Dynamic-Pricing.postman_collection.json) to help you test API manually. Alternatively, you can use the following curl commands.

### `GET /api/v1/products`

Description: Lists all products with dynamic prices.

#### Request
```bash
curl -X GET http://localhost:3000/api/v1/products
```

#### Response
```json
// Status: 200 OK
{
  "products": [
    {
      "id": "BSON::ObjectId",
      "name": "Foo",
      "category": "Test",
      "dynamic_price": 120.0,
      "total_inventory": 100,
      "total_reserved": 20,
      "created_at": "2024-12-24 01:00:00",
      "updated_at": "2024-12-24 04:00:00"
    }
  ]
}
```

### `GET /api/v1/products/:id`

Description: Retrieves a specific product.

#### Request
```bash
curl -X GET http://localhost:3000/api/v1/products/:id
```

#### Response
```json
// Status: 200 OK
{
  "id": "BSON::ObjectId",
  "name": "Foo",
  "category": "Test",
  "dynamic_price": 120.0,
  "total_inventory": 100,
  "total_reserved": 20,
  "created_at": "2024-12-24 01:00:00",
  "updated_at": "2024-12-24 04:00:00"
}
```

### `POST /api/v1/products/import`

Description: Imports product data via a CSV file. [Sample CSV file](/doc/inventory.csv).

#### Request
```bash
curl -X POST http://localhost:3000/api/v1/products/import \
-H "Content-Type: multipart/form-data" \
-F "file=file_path"
```

#### Response
```json
// Status: 201 Created
{
  "products": [
    {
      "id": "BSON::ObjectId",
      "name": "Foo",
      "category": "Test",
      "dynamic_price": 120.0,
      "total_inventory": 100,
      "total_reserved": 20,
      "created_at": "2024-12-24 01:00:00",
      "updated_at": "2024-12-24 04:00:00"
    }
  ]
}
```

### `POST /api/v1/carts`

Description: Creates a shopping cart.

#### Request
```bash
curl -X POST http://localhost:3000/api/v1/carts \
-H "Content-Type: application/json" \
-d '{
  "cart": {
    "items": [
      {
        "product_id": "BSON::ObjectId",
        "quantity": 1
      }
    ]
  }
}'

```

#### Response
```json
// Status: 201 Created
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
```bash
curl -X POST http://localhost:3000/api/v1/carts/:cart_id/items \
-H "Content-Type: application/json" \
-d '{
  "cart_item": {
    "product_id": "BSON::ObjectId",
    "quantity": 1
  }
}'
```

#### Response
```json
// Status: 201 Created
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
```bash
curl -X DELETE http://localhost:3000/api/v1/carts/:cart_id/items/:id
```

#### Response
```json
// Status: 200 OK
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
```bash
curl -X POST http://localhost:3000/api/v1/order \
-H "Content-Type: application/json" \
-d '{
  "cart_id": "BSON::ObjectId"
}'
```

#### Response
```json
// Status: 201 Created
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

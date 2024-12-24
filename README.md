# Dynamic Pricing Engine

An e-commerce dynamic pricing engine built with Ruby on Rails, Redis, and MongoDB, featuring realtime price adjustments.

## Overview
project description

architecture

## API

- `GET /api/v1/products`
  - Description: List products with dynamic price
- `GET /api/v1/products/:id`
  - Description: Get specific product details
- `POST /api/v1/products/import`
  - Description: Create product data through CSV file
- `POST /api/v1/carts`
  - Description: Create a shopping cart with product items
- `POST /api/v1/carts/:cart_id/items`
  - Description: Add items to the shopping cart
- `DELETE /api/v1/carts/:cart_id/items/:id`
  - Description: Remove specific item from the shopping cart
- `POST /api/v1/order`
  - Description: Create an order

## How to run

prerequisites

set up env

testing

## Deployment


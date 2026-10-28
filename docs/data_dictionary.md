# Olist Brazilian E-Commerce: PostgreSQL Schema Summary

Source: Kaggle `olistbr/brazilian-ecommerce` (9 CSV files, UTF-8).

## Load order (respects foreign keys)

1. `product_category_name_translation`
2. `customers`, `sellers`, `geolocation`
3. `products`
4. `orders`
5. `order_items`, `order_payments`, `order_reviews`

## Relationships

```
customers 1──* orders 1──* order_items *──1 products *──1 category_translation
                 │                 └──*──1 sellers
                 ├──* order_payments
                 └──* order_reviews
geolocation: linked to customers/sellers by zip prefix only (no FK; zip is not unique there)
```

## 1. `product_category_name_translation` (file: `product_category_name_translation.csv`, ~71 rows)

| Column | Data Type | Description | Nullable | Key |
| :--- | :--- | :--- | :--- | :--- |
| `product_category_name` | `TEXT` | Category name in Portuguese | NO | Primary Key |
| `product_category_name_english` | `TEXT` | Category name in English | NO | |


## 2. `customers` (file: `olist_customers_dataset.csv`, ~99,441 rows)

| Column | Data Type | Description | Nullable | Key |
| :--- | :--- | :--- | :--- | :--- |
| `customer_id` | `CHAR(32)` | Order-specific customer ID (a customer gets a new one per order) | NO | Primary Key |
| `customer_unique_id` | `CHAR(32)` | Identifies the real person across orders | NO | |
| `customer_zip_code_prefix` | `CHAR(5)` | First 5 digits of zip (load as text) | NO | |
| `customer_city` | `VARCHAR(50)` | City name (lowercase, may lack accents) | NO | |
| `customer_state` | `CHAR(2)` | Brazilian state code (SP, RJ, ...) | NO | |

## 3. `sellers` (file: `olist_sellers_dataset.csv`, ~3,095 rows)

| Column | Data Type | Description | Nullable | Key |
| :--- | :--- | :--- | :--- | :--- |
| `seller_id` | `CHAR(32)` | Unique seller ID | NO | Primary Key |
| `seller_zip_code_prefix` | `CHAR(5)` | Seller zip prefix (load as text) | NO | |
| `seller_city` | `VARCHAR(50)` | Seller city | NO | |
| `seller_state` | `CHAR(2)` | Seller state code | NO | |

## 4. `geolocation` (file: `olist_geolocation_dataset.csv`, ~1,000,163 rows)

| Column | Data Type | Description | Nullable | Key |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `INT GENERATED ALWAYS AS IDENTITY` | Surrogate key (the zip prefix repeats many times) | NO | Primary Key |
| `geolocation_zip_code_prefix` | `CHAR(5)` | Zip prefix | NO | |
| `geolocation_lat` | `DOUBLE PRECISION` | Latitude | NO | |
| `geolocation_lng` | `DOUBLE PRECISION` | Longitude | NO | |
| `geolocation_city` | `VARCHAR(50)` | City (spelling variants and accents are inconsistent) | NO | |
| `geolocation_state` | `CHAR(2)` | State code | NO | |


## 5. `products` (file: `olist_products_dataset.csv`, ~32,951 rows)

CSV headers contain typos (`product_name_lenght`, `product_description_lenght`, `product_photos_qty`). Rename on load if you wish.

| Column | Data Type | Description | Nullable | Key |
| :--- | :--- | :--- | :--- | :--- |
| `product_id` | `CHAR(32)` | Unique product ID | NO | Primary Key |
| `product_category_name` | `TEXT` | Category (Portuguese) | YES (~610 nulls) | |
| `product_name_length` | `INTEGER` | Characters in product name | YES | |
| `product_description_length` | `INTEGER` | Characters in product description | YES | |
| `product_photos_qty` | `INTEGER` | Number of photos | YES | |
| `product_weight_g` | `INTEGER` | Weight in grams | YES (~2 nulls) | |
| `product_length_cm` | `INTEGER` | Length in cm | YES (~2 nulls) | |
| `product_height_cm` | `INTEGER` | Height in cm | YES (~2 nulls) | |
| `product_width_cm` | `INTEGER` | Width in cm | YES (~2 nulls) | |

Note: the numeric columns appear as floats in the CSV (e.g. `40.0`). Load into a staging table first or cast before inserting into INTEGER columns.

## 6. `orders` (file: `olist_orders_dataset.csv`, ~99,441 rows)

| Column | Data Type | Description | Nullable | Key |
| :--- | :--- | :--- | :--- | :--- |
| `order_id` | `CHAR(32)` | Unique order ID | NO | Primary Key |
| `customer_id` | `CHAR(32)` | Customer who placed the order | NO | FK → `customers(customer_id)` |
| `order_status` | ENUM( One of: delivered, invoiced, shipped, processing, unavailable, canceled, created, approved) | NO | |
| `order_purchase_timestamp` | `TIMESTAMP` | When the order was placed | NO | |
| `order_approved_at` | `TIMESTAMP` | When payment was approved | YES (~160) | |
| `order_delivered_carrier_date` | `TIMESTAMP` | When handed to the logistics carrier | YES (~1,783) | |
| `order_delivered_customer_date` | `TIMESTAMP` | Actual delivery to customer | YES (~2,965) | |
| `order_estimated_delivery_date` | `TIMESTAMP` | Estimated delivery date shown at purchase | NO | |

## 7. `order_items` (file: `olist_order_items_dataset.csv`, ~112,650 rows)

| Column | Data Type | Description | Nullable | Key |
| :--- | :--- | :--- | :--- | :--- |
| `order_id` | `CHAR(32)` | Order | NO | PK (composite), FK → `orders` |
| `order_item_id` | `INTEGER` | Item sequence number within the order (1, 2, 3...) | NO | PK (composite) |
| `product_id` | `CHAR(32)` | Product | NO | FK → `products` |
| `seller_id` | `CHAR(32)` | Seller | NO | FK → `sellers` |
| `shipping_limit_date` | `TIMESTAMP` | Seller's deadline to hand the item to the carrier | NO | |
| `price` | `NUMERIC(10,2)` | Item price (BRL) | NO | |
| `freight_value` | `NUMERIC(10,2)` | Freight cost for this item (BRL) | NO | |

## 8. `order_payments` (file: `olist_order_payments_dataset.csv`, ~103,886 rows)

| Column | Data Type | Description | Nullable | Key |
| :--- | :--- | :--- | :--- | :--- |
| `order_id` | `CHAR(32)` | Order | NO | PK (composite), FK → `orders` |
| `payment_sequential` | `INTEGER` | Sequence when an order is paid with several methods | NO | PK (composite) |
| `payment_type` | `TEXT` + `CHECK` | credit_card, boleto, voucher, debit_card, not_defined | NO | |
| `payment_installments` | `INTEGER` | Number of installments (a few rows are 0) | NO | |
| `payment_value` | `NUMERIC(10,2)` | Amount paid (a few rows are 0) | NO | |

## 9. `order_reviews` (file: `olist_order_reviews_dataset.csv`, ~99,224 rows)


| Column | Data Type | Description | Nullable | Key |
| :--- | :--- | :--- | :--- | :--- |
| `review_id` | `CHAR(32)` | Review ID (NOT unique on its own) | NO | PK (composite) |
| `order_id` | `CHAR(32)` | Reviewed order | NO | PK (composite), FK → `orders` |
| `review_score` | `SMALLINT` | Score 1 to 5 | NO | `CHECK (review_score BETWEEN 1 AND 5)` |
| `review_comment_title` | `TEXT` | Optional title (mostly empty) | YES | |
| `review_comment_message` | `TEXT` | Optional comment body | YES | |
| `review_creation_date` | `TIMESTAMP` | When the satisfaction survey was sent | NO | |
| `review_answer_timestamp` | `TIMESTAMP` | When the customer answered the survey | NO | |


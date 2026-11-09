-- Phase 6: define typed, standardized staging tables.
-- Source business keys are retained (and trimmed from raw CHAR columns) for
-- lineage. Geolocation retains its raw-table surrogate key because ZIP prefixes
-- and full location records are not unique.
CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE IF NOT EXISTS staging.customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32) NOT NULL,
    zip_code_prefix VARCHAR(5) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state CHAR(2) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging.product_category_translations (
    category_name TEXT PRIMARY KEY,
    category_name_english TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS staging.sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    zip_code_prefix VARCHAR(5) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state CHAR(2) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging.geolocation (
    source_geolocation_id INTEGER PRIMARY KEY,
    zip_code_prefix VARCHAR(5) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    city VARCHAR(50) NOT NULL,
    state CHAR(2) NOT NULL
);

CREATE TABLE IF NOT EXISTS staging.products (
    product_id VARCHAR(32) PRIMARY KEY,
    category_name TEXT,
    category_name_english TEXT,
    name_length INTEGER,
    description_length INTEGER,
    photos_qty INTEGER,
    weight_g INTEGER,
    length_cm INTEGER,
    height_cm INTEGER,
    width_cm INTEGER,
    volume_cm3 BIGINT,
    has_complete_dimensions BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS staging.orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32) NOT NULL REFERENCES staging.customers(customer_id),
    status VARCHAR(30) NOT NULL,
    purchased_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    approved_at TIMESTAMP WITHOUT TIME ZONE,
    carrier_handoff_at TIMESTAMP WITHOUT TIME ZONE,
    customer_delivered_at TIMESTAMP WITHOUT TIME ZONE,
    estimated_delivery_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    purchase_date DATE NOT NULL,
    purchase_month DATE NOT NULL,
    delivery_duration_hours NUMERIC(12, 2),
    approval_before_purchase BOOLEAN NOT NULL,
    carrier_before_purchase BOOLEAN NOT NULL,
    carrier_before_approval BOOLEAN NOT NULL,
    delivery_before_purchase BOOLEAN NOT NULL,
    delivery_before_carrier BOOLEAN NOT NULL,
    delivered_status_missing_delivery BOOLEAN NOT NULL,
    non_delivered_status_has_delivery BOOLEAN NOT NULL,
    is_late_delivery BOOLEAN
);

CREATE TABLE IF NOT EXISTS staging.order_items (
    order_id VARCHAR(32) NOT NULL REFERENCES staging.orders(order_id),
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(32) NOT NULL REFERENCES staging.products(product_id),
    seller_id VARCHAR(32) NOT NULL REFERENCES staging.sellers(seller_id),
    shipping_limit_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    price_brl NUMERIC(10, 2) NOT NULL,
    freight_brl NUMERIC(10, 2) NOT NULL,
    item_total_brl NUMERIC(11, 2) NOT NULL,
    shipping_limit_before_purchase BOOLEAN NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE IF NOT EXISTS staging.order_payments (
    order_id VARCHAR(32) NOT NULL REFERENCES staging.orders(order_id),
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(30) NOT NULL,
    installments INTEGER NOT NULL,
    payment_value_brl NUMERIC(10, 2) NOT NULL,
    has_invalid_installments BOOLEAN NOT NULL,
    is_zero_value BOOLEAN NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE IF NOT EXISTS staging.order_reviews (
    review_id VARCHAR(32) NOT NULL,
    order_id VARCHAR(32) NOT NULL REFERENCES staging.orders(order_id),
    review_score SMALLINT NOT NULL,
    comment_title TEXT,
    comment_message TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    answered_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    response_hours NUMERIC(12, 2) NOT NULL,
    created_before_purchase BOOLEAN NOT NULL,
    PRIMARY KEY (review_id, order_id)
);

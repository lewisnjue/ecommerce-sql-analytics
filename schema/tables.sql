CREATE TABLE IF NOT EXISTS customers (
    customer_id CHAR(32) PRIMARY KEY,
    customer_unique_id CHAR(32) NOT NULL,
    customer_zip_code_prefix CHAR(5) NOT NULL,
    customer_city VARCHAR(50) NOT NULL,
    customer_state CHAR(2) NOT NULL
);

CREATE TABLE IF NOT EXISTS product_category_name_translation (
    product_category_name TEXT PRIMARY KEY,
    product_category_name_english TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sellers (
    seller_id CHAR(32) PRIMARY KEY,
    seller_zip_code_prefix CHAR(5) NOT NULL,
    seller_city VARCHAR(50) NOT NULL,
    seller_state CHAR(2) NOT NULL
);

CREATE TABLE IF NOT EXISTS geolocation (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    geolocation_zip_code_prefix CHAR(5) NOT NULL,
    geolocation_lat DOUBLE PRECISION NOT NULL,
    geolocation_lng DOUBLE PRECISION NOT NULL,
    geolocation_city VARCHAR(50) NOT NULL,
    geolocation_state CHAR(2) NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
    product_id CHAR(32) PRIMARY KEY,
    product_category_name TEXT,
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

CREATE TABLE IF NOT EXISTS orders (
    order_id CHAR(32) PRIMARY KEY,
    customer_id CHAR(32) NOT NULL,
    order_status VARCHAR(30) NOT NULL CHECK (order_status IN ('delivered', 'invoiced', 'shipped', 'processing', 'unavailable', 'canceled', 'created', 'approved')),
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id CHAR(32) NOT NULL,
    order_item_id INT NOT NULL,
    product_id CHAR(32) NOT NULL,
    seller_id CHAR(32) NOT NULL,
    shipping_limit_date TIMESTAMP NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    freight_value NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE IF NOT EXISTS order_payments (
    order_id CHAR(32) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(30) NOT NULL CHECK (payment_type IN ('credit_card', 'boleto', 'voucher', 'debit_card', 'not_defined')),
    payment_installments INT NOT NULL,
    payment_value NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE IF NOT EXISTS order_reviews (
    review_id CHAR(32) NOT NULL,
    order_id CHAR(32) NOT NULL,
    review_score SMALLINT NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP NOT NULL,
    review_answer_timestamp TIMESTAMP NOT NULL,
    PRIMARY KEY (review_id, order_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

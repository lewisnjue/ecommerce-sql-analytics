-- Rebuild the staging data from the unchanged public source tables.
-- Run after 01_create_staging_tables.sql. This transaction replaces only
-- staging rows and keeps the raw/public tables untouched.
BEGIN;

TRUNCATE TABLE
    staging.order_reviews,
    staging.order_payments,
    staging.order_items,
    staging.orders,
    staging.products,
    staging.geolocation,
    staging.sellers,
    staging.product_category_translations,
    staging.customers;

INSERT INTO staging.customers (
    customer_id, customer_unique_id, zip_code_prefix, city, state
)
SELECT BTRIM(customer_id), BTRIM(customer_unique_id),
       BTRIM(customer_zip_code_prefix), BTRIM(customer_city),
       BTRIM(customer_state)
FROM public.customers;

INSERT INTO staging.product_category_translations (
    category_name, category_name_english
)
SELECT product_category_name, product_category_name_english
FROM public.product_category_name_translation;

INSERT INTO staging.sellers (seller_id, zip_code_prefix, city, state)
SELECT BTRIM(seller_id), BTRIM(seller_zip_code_prefix),
       BTRIM(seller_city), BTRIM(seller_state)
FROM public.sellers;

INSERT INTO staging.geolocation (
    source_geolocation_id, zip_code_prefix, latitude, longitude, city, state
)
SELECT id, BTRIM(geolocation_zip_code_prefix), geolocation_lat,
       geolocation_lng, BTRIM(geolocation_city), BTRIM(geolocation_state)
FROM public.geolocation;

INSERT INTO staging.products (
    product_id, category_name, category_name_english, name_length,
    description_length, photos_qty, weight_g, length_cm, height_cm, width_cm,
    volume_cm3, has_complete_dimensions
)
SELECT BTRIM(p.product_id), p.product_category_name,
       t.product_category_name_english, p.product_name_lenght,
       p.product_description_lenght, p.product_photos_qty, p.product_weight_g,
       p.product_length_cm, p.product_height_cm, p.product_width_cm,
       CASE
           WHEN p.product_length_cm IS NOT NULL
            AND p.product_height_cm IS NOT NULL
            AND p.product_width_cm IS NOT NULL
           THEN p.product_length_cm::BIGINT
                * p.product_height_cm::BIGINT
                * p.product_width_cm::BIGINT
       END,
       p.product_weight_g IS NOT NULL
       AND p.product_length_cm IS NOT NULL
       AND p.product_height_cm IS NOT NULL
       AND p.product_width_cm IS NOT NULL
FROM public.products p
LEFT JOIN public.product_category_name_translation t
    ON t.product_category_name = p.product_category_name;

INSERT INTO staging.orders (
    order_id, customer_id, status, purchased_at, approved_at,
    carrier_handoff_at, customer_delivered_at, estimated_delivery_at,
    purchase_date, purchase_month, delivery_duration_hours,
    approval_before_purchase, carrier_before_purchase, carrier_before_approval,
    delivery_before_purchase, delivery_before_carrier,
    delivered_status_missing_delivery, non_delivered_status_has_delivery,
    is_late_delivery
)
SELECT BTRIM(o.order_id), BTRIM(o.customer_id), o.order_status,
       o.order_purchase_timestamp::TIMESTAMP WITHOUT TIME ZONE,
       o.order_approved_at::TIMESTAMP WITHOUT TIME ZONE,
       o.order_delivered_carrier_date::TIMESTAMP WITHOUT TIME ZONE,
       o.order_delivered_customer_date::TIMESTAMP WITHOUT TIME ZONE,
       o.order_estimated_delivery_date::TIMESTAMP WITHOUT TIME ZONE,
       o.order_purchase_timestamp::DATE,
       DATE_TRUNC('month', o.order_purchase_timestamp)::DATE,
       CASE WHEN o.order_delivered_customer_date IS NOT NULL
            THEN ROUND(
                (EXTRACT(EPOCH FROM (
                    o.order_delivered_customer_date - o.order_purchase_timestamp
                )) / 3600)::NUMERIC,
                2
            )
       END,
       COALESCE(o.order_approved_at < o.order_purchase_timestamp, FALSE),
       COALESCE(o.order_delivered_carrier_date < o.order_purchase_timestamp, FALSE),
       COALESCE(
           o.order_approved_at IS NOT NULL
           AND o.order_delivered_carrier_date < o.order_approved_at,
           FALSE
       ),
       COALESCE(o.order_delivered_customer_date < o.order_purchase_timestamp, FALSE),
       COALESCE(
           o.order_delivered_customer_date IS NOT NULL
           AND o.order_delivered_carrier_date IS NOT NULL
           AND o.order_delivered_customer_date < o.order_delivered_carrier_date,
           FALSE
       ),
       COALESCE(
           o.order_status = 'delivered'
           AND o.order_delivered_customer_date IS NULL,
           FALSE
       ),
       o.order_status <> 'delivered'
           AND o.order_delivered_customer_date IS NOT NULL,
       CASE WHEN o.order_status = 'delivered'
                  AND o.order_delivered_customer_date IS NOT NULL
            THEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
       END
FROM public.orders o;

INSERT INTO staging.order_items (
    order_id, order_item_id, product_id, seller_id, shipping_limit_at,
    price_brl, freight_brl, item_total_brl, shipping_limit_before_purchase
)
SELECT BTRIM(oi.order_id), oi.order_item_id, BTRIM(oi.product_id),
       BTRIM(oi.seller_id),
       oi.shipping_limit_date::TIMESTAMP WITHOUT TIME ZONE,
       oi.price, oi.freight_value, oi.price + oi.freight_value,
       oi.shipping_limit_date < o.order_purchase_timestamp
FROM public.order_items oi
JOIN public.orders o ON o.order_id = oi.order_id;

INSERT INTO staging.order_payments (
    order_id, payment_sequential, payment_type, installments,
    payment_value_brl, has_invalid_installments, is_zero_value
)
SELECT BTRIM(op.order_id), op.payment_sequential, op.payment_type,
       op.payment_installments, op.payment_value,
       op.payment_installments < 1, op.payment_value = 0
FROM public.order_payments op;

INSERT INTO staging.order_reviews (
    review_id, order_id, review_score, comment_title, comment_message,
    created_at, answered_at, response_hours, created_before_purchase
)
SELECT BTRIM(r.review_id), BTRIM(r.order_id), r.review_score,
       NULLIF(BTRIM(r.review_comment_title), ''),
       NULLIF(BTRIM(r.review_comment_message), ''),
       r.review_creation_date::TIMESTAMP WITHOUT TIME ZONE,
       r.review_answer_timestamp::TIMESTAMP WITHOUT TIME ZONE,
       ROUND(
           (EXTRACT(EPOCH FROM (
               r.review_answer_timestamp - r.review_creation_date
           )) / 3600)::NUMERIC,
           2
       ),
       r.review_creation_date < o.order_purchase_timestamp
FROM public.order_reviews r
JOIN public.orders o ON o.order_id = r.order_id;

COMMIT;

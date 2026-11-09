-- Phase 5: distinguish key collisions from repeated non-key/business data.
-- Primary-key duplicates cannot be inserted under this schema's constraints;
-- these checks verify the loaded relations and document that guarantee.
SELECT 'customers.customer_id' AS duplicate_key, COUNT(*) AS duplicate_groups
FROM (
    SELECT customer_id FROM customers GROUP BY customer_id HAVING COUNT(*) > 1
) AS duplicates
UNION ALL
SELECT 'products.product_id', COUNT(*)
FROM (
    SELECT product_id FROM products GROUP BY product_id HAVING COUNT(*) > 1
) AS duplicates
UNION ALL
SELECT 'sellers.seller_id', COUNT(*)
FROM (
    SELECT seller_id FROM sellers GROUP BY seller_id HAVING COUNT(*) > 1
) AS duplicates
UNION ALL
SELECT 'orders.order_id', COUNT(*)
FROM (
    SELECT order_id FROM orders GROUP BY order_id HAVING COUNT(*) > 1
) AS duplicates
UNION ALL
SELECT 'order_items.order_id + order_item_id', COUNT(*)
FROM (
    SELECT order_id, order_item_id
    FROM order_items GROUP BY order_id, order_item_id HAVING COUNT(*) > 1
) AS duplicates
UNION ALL
SELECT 'order_payments.order_id + payment_sequential', COUNT(*)
FROM (
    SELECT order_id, payment_sequential
    FROM order_payments
    GROUP BY order_id, payment_sequential
    HAVING COUNT(*) > 1
) AS duplicates
UNION ALL
SELECT 'order_reviews.review_id + order_id', COUNT(*)
FROM (
    SELECT review_id, order_id
    FROM order_reviews GROUP BY review_id, order_id HAVING COUNT(*) > 1
) AS duplicates
UNION ALL
SELECT 'product_category_name_translation.product_category_name', COUNT(*)
FROM (
    SELECT product_category_name
    FROM product_category_name_translation
    GROUP BY product_category_name
    HAVING COUNT(*) > 1
) AS duplicates
UNION ALL
SELECT 'geolocation.id', COUNT(*)
FROM (
    SELECT id FROM geolocation GROUP BY id HAVING COUNT(*) > 1
) AS duplicates;

-- Geolocation legitimately repeats ZIP prefixes. Count only repeated full records.
SELECT
    COUNT(*) FILTER (WHERE record_count > 1) AS duplicated_record_groups,
    COALESCE(SUM(record_count - 1) FILTER (WHERE record_count > 1), 0)
        AS excess_duplicate_rows
FROM (
    SELECT geolocation_zip_code_prefix, geolocation_lat, geolocation_lng,
           geolocation_city, geolocation_state, COUNT(*) AS record_count
    FROM geolocation
    GROUP BY geolocation_zip_code_prefix, geolocation_lat, geolocation_lng,
             geolocation_city, geolocation_state
) AS repeated_records;

-- Identical order attributes under different order IDs are potential business
-- duplicates, while distinct orders at the same time are not assumed duplicates.
SELECT
    COUNT(*) FILTER (WHERE order_count > 1) AS repeated_order_signatures,
    COALESCE(SUM(order_count - 1) FILTER (WHERE order_count > 1), 0)
        AS excess_orders
FROM (
    SELECT customer_id, order_status, order_purchase_timestamp,
           order_approved_at, order_delivered_carrier_date,
           order_delivered_customer_date, order_estimated_delivery_date,
           COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id, order_status, order_purchase_timestamp,
             order_approved_at, order_delivered_carrier_date,
             order_delivered_customer_date, order_estimated_delivery_date
) AS order_signatures;

-- A customer_unique_id is a person-level identifier and may map to multiple
-- order-specific customer_id values; this is expected rather than a key defect.
SELECT
    COUNT(*) FILTER (WHERE customer_ids > 1) AS people_with_multiple_customer_ids,
    COALESCE(SUM(customer_ids - 1) FILTER (WHERE customer_ids > 1), 0)
        AS additional_customer_ids
FROM (
    SELECT customer_unique_id, COUNT(*) AS customer_ids
    FROM customers
    GROUP BY customer_unique_id
) AS customer_identity;

-- Joining items to one-to-many payments expands rows; measure that fan-out so
-- downstream item totals are not accidentally inflated.
SELECT
    COUNT(*) AS item_rows_after_order_and_payment_join,
    COUNT(DISTINCT ROW(oi.order_id, oi.order_item_id)) AS distinct_order_items,
    COUNT(*) - COUNT(DISTINCT ROW(oi.order_id, oi.order_item_id))
        AS extra_rows_from_payment_fanout
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
LEFT JOIN order_payments op ON op.order_id = o.order_id;

-- Review IDs repeat across different orders in the source; identify scope.
SELECT
    COUNT(*) FILTER (WHERE orders_per_review_id > 1) AS repeated_review_ids,
    COALESCE(SUM(orders_per_review_id - 1)
             FILTER (WHERE orders_per_review_id > 1), 0) AS excess_review_rows
FROM (
    SELECT review_id, COUNT(DISTINCT order_id) AS orders_per_review_id
    FROM order_reviews
    GROUP BY review_id
) AS review_identity;

SELECT r.review_id,
       COUNT(DISTINCT r.order_id) AS linked_orders,
       COUNT(DISTINCT r.review_score) AS distinct_scores,
       STRING_AGG(DISTINCT r.review_score::TEXT, ', ' ORDER BY r.review_score::TEXT)
           AS observed_scores
FROM order_reviews r
JOIN (
    SELECT review_id
    FROM order_reviews
    GROUP BY review_id
    HAVING COUNT(DISTINCT order_id) > 1
) repeated USING (review_id)
GROUP BY r.review_id
ORDER BY linked_orders DESC, r.review_id
LIMIT 10;

WITH repeated_review_ids AS (
    SELECT review_id
    FROM order_reviews
    GROUP BY review_id
    HAVING COUNT(DISTINCT order_id) > 1
),
review_content_profiles AS (
    SELECT r.review_id,
           COUNT(DISTINCT ROW(
               r.review_score, r.review_comment_title, r.review_comment_message,
               r.review_creation_date, r.review_answer_timestamp
           )) AS distinct_content_profiles
    FROM order_reviews r
    JOIN repeated_review_ids d USING (review_id)
    GROUP BY r.review_id
)
SELECT COUNT(*) AS repeated_review_ids,
       COUNT(*) FILTER (WHERE distinct_content_profiles = 1)
           AS ids_with_identical_content_and_timestamps,
       COUNT(*) FILTER (WHERE distinct_content_profiles > 1)
           AS ids_with_content_or_timestamp_variation
FROM review_content_profiles;

-- Geolocation ZIP prefixes are non-unique; inspect a few full-record repetitions.
SELECT geolocation_zip_code_prefix, geolocation_lat, geolocation_lng,
       geolocation_city, geolocation_state, COUNT(*) AS repeated_rows
FROM geolocation
GROUP BY geolocation_zip_code_prefix, geolocation_lat, geolocation_lng,
         geolocation_city, geolocation_state
HAVING COUNT(*) > 1
ORDER BY repeated_rows DESC, geolocation_zip_code_prefix
LIMIT 10;

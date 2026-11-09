-- Phase 5: validate event ordering, status/date consistency, and future dates.
-- Late delivery is a service KPI, not an invalid date, and is reported separately.
SELECT 'approval before purchase' AS check_name, COUNT(*) AS affected_rows
FROM orders
WHERE order_approved_at < order_purchase_timestamp
UNION ALL
SELECT 'carrier handoff before purchase', COUNT(*)
FROM orders
WHERE order_delivered_carrier_date < order_purchase_timestamp
UNION ALL
SELECT 'carrier handoff before approval', COUNT(*)
FROM orders
WHERE order_approved_at IS NOT NULL
  AND order_delivered_carrier_date < order_approved_at
UNION ALL
SELECT 'customer delivery before purchase', COUNT(*)
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp
UNION ALL
SELECT 'customer delivery before carrier handoff', COUNT(*)
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date < order_delivered_carrier_date
UNION ALL
SELECT 'estimated delivery before purchase', COUNT(*)
FROM orders
WHERE order_estimated_delivery_date < order_purchase_timestamp
UNION ALL
SELECT 'shipping limit before purchase', COUNT(*)
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE oi.shipping_limit_date < o.order_purchase_timestamp
UNION ALL
SELECT 'review created before purchase', COUNT(*)
FROM order_reviews r
JOIN orders o ON o.order_id = r.order_id
WHERE r.review_creation_date < o.order_purchase_timestamp
UNION ALL
SELECT 'review answered before review creation', COUNT(*)
FROM order_reviews
WHERE review_answer_timestamp < review_creation_date
UNION ALL
SELECT 'delivered order missing customer delivery timestamp', COUNT(*)
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL
UNION ALL
SELECT 'non-delivered order has customer delivery timestamp', COUNT(*)
FROM orders
WHERE order_status <> 'delivered'
  AND order_delivered_customer_date IS NOT NULL
UNION ALL
SELECT 'delivered after estimated date (late, not invalid)', COUNT(*)
FROM orders
WHERE order_delivered_customer_date > order_estimated_delivery_date
UNION ALL
SELECT 'orders with purchase timestamp in future', COUNT(*)
FROM orders WHERE order_purchase_timestamp > CURRENT_TIMESTAMP
UNION ALL
SELECT 'orders with approval timestamp in future', COUNT(*)
FROM orders WHERE order_approved_at > CURRENT_TIMESTAMP
UNION ALL
SELECT 'orders with carrier timestamp in future', COUNT(*)
FROM orders WHERE order_delivered_carrier_date > CURRENT_TIMESTAMP
UNION ALL
SELECT 'orders with customer delivery timestamp in future', COUNT(*)
FROM orders WHERE order_delivered_customer_date > CURRENT_TIMESTAMP
UNION ALL
SELECT 'orders with estimated delivery date in future', COUNT(*)
FROM orders WHERE order_estimated_delivery_date > CURRENT_TIMESTAMP
UNION ALL
SELECT 'order items with shipping limit in future', COUNT(*)
FROM order_items WHERE shipping_limit_date > CURRENT_TIMESTAMP
UNION ALL
SELECT 'reviews with creation date in future', COUNT(*)
FROM order_reviews WHERE review_creation_date > CURRENT_TIMESTAMP
UNION ALL
SELECT 'reviews with answer date in future', COUNT(*)
FROM order_reviews WHERE review_answer_timestamp > CURRENT_TIMESTAMP
ORDER BY check_name;

-- Show representative chronology violations for diagnosis if any are found.
SELECT order_id, order_status, order_purchase_timestamp,
       order_approved_at, order_delivered_carrier_date,
       order_delivered_customer_date, order_estimated_delivery_date
FROM orders
WHERE (order_approved_at < order_purchase_timestamp)
   OR (order_delivered_carrier_date < order_purchase_timestamp)
   OR (order_approved_at IS NOT NULL
       AND order_delivered_carrier_date < order_approved_at)
   OR (order_delivered_customer_date < order_purchase_timestamp)
   OR (order_delivered_customer_date IS NOT NULL
       AND order_delivered_carrier_date IS NOT NULL
       AND order_delivered_customer_date < order_delivered_carrier_date)
   OR (order_estimated_delivery_date < order_purchase_timestamp)
ORDER BY order_purchase_timestamp
LIMIT 10;

SELECT order_id, order_status, order_approved_at,
       order_delivered_carrier_date, order_delivered_customer_date
FROM orders
WHERE (order_approved_at IS NOT NULL
       AND order_delivered_carrier_date < order_approved_at)
   OR (order_delivered_customer_date IS NOT NULL
       AND order_delivered_carrier_date IS NOT NULL
       AND order_delivered_customer_date < order_delivered_carrier_date)
ORDER BY order_purchase_timestamp
LIMIT 10;

SELECT order_id, order_status, order_purchase_timestamp,
       order_delivered_customer_date, order_estimated_delivery_date
FROM orders
WHERE (order_status = 'delivered' AND order_delivered_customer_date IS NULL)
   OR (order_status <> 'delivered' AND order_delivered_customer_date IS NOT NULL)
ORDER BY order_purchase_timestamp
LIMIT 20;

SELECT order_id, order_status, order_approved_at, order_delivered_carrier_date
FROM orders
WHERE order_delivered_carrier_date < order_approved_at
ORDER BY order_purchase_timestamp
LIMIT 10;

SELECT order_id, order_status, order_purchase_timestamp,
       order_delivered_carrier_date
FROM orders
WHERE order_delivered_carrier_date < order_purchase_timestamp
ORDER BY order_purchase_timestamp
LIMIT 10;

SELECT order_id, order_status, order_delivered_carrier_date,
       order_delivered_customer_date
FROM orders
WHERE order_delivered_customer_date < order_delivered_carrier_date
ORDER BY order_purchase_timestamp
LIMIT 10;

SELECT r.review_id, r.order_id, o.order_status,
       o.order_purchase_timestamp, r.review_creation_date, r.review_answer_timestamp
FROM order_reviews r
JOIN orders o ON o.order_id = r.order_id
WHERE r.review_creation_date < o.order_purchase_timestamp
ORDER BY r.review_creation_date
LIMIT 10;

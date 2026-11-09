-- Phase 15: delivery/logistics performance and relationship to review scores.
WITH eligible_deliveries AS (
    SELECT *
    FROM staging.orders
    WHERE status = 'delivered'
      AND customer_delivered_at IS NOT NULL
      AND delivery_duration_hours >= 0
)
SELECT COUNT(*) AS eligible_deliveries,
       ROUND(AVG(delivery_duration_hours)::NUMERIC, 2) AS average_delivery_hours,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delivery_duration_hours)
           AS median_delivery_hours,
       COUNT(*) FILTER (WHERE is_late_delivery) AS late_deliveries,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_late_delivery) / COUNT(*), 2)
           AS late_delivery_rate_pct
FROM eligible_deliveries;

-- Delivery time by customer destination state.
SELECT c.state AS customer_state, COUNT(*) AS delivered_orders,
       ROUND(AVG(o.delivery_duration_hours)::NUMERIC, 2) AS average_hours,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY o.delivery_duration_hours)
           AS median_hours,
       ROUND(100.0 * COUNT(*) FILTER (WHERE o.is_late_delivery) / COUNT(*), 2)
           AS late_rate_pct
FROM staging.orders o
JOIN staging.customers c ON c.customer_id = o.customer_id
WHERE o.status = 'delivered'
  AND o.delivery_duration_hours >= 0
GROUP BY c.state
ORDER BY average_hours DESC;

-- Seller-level delivery uses distinct seller/order pairs to avoid item fan-out.
WITH seller_orders AS (
    SELECT DISTINCT oi.seller_id, o.order_id, o.delivery_duration_hours,
           o.is_late_delivery
    FROM staging.order_items oi
    JOIN staging.orders o ON o.order_id = oi.order_id
    WHERE o.status = 'delivered'
      AND o.delivery_duration_hours >= 0
)
SELECT s.seller_id, s.state,
       COUNT(*) AS delivered_orders,
       ROUND(AVG(so.delivery_duration_hours)::NUMERIC, 2) AS average_hours,
       PERCENTILE_CONT(0.5) WITHIN GROUP (
           ORDER BY so.delivery_duration_hours
       ) AS median_hours,
       ROUND(100.0 * COUNT(*) FILTER (WHERE so.is_late_delivery) / COUNT(*), 2)
           AS late_rate_pct
FROM seller_orders so
JOIN staging.sellers s ON s.seller_id = so.seller_id
GROUP BY s.seller_id, s.state
HAVING COUNT(*) >= 20
ORDER BY average_hours DESC
LIMIT 20;

-- Delivery performance by product category, at distinct order/category grain.
WITH order_categories AS (
    SELECT DISTINCT o.order_id,
           COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
               AS category,
           o.delivery_duration_hours, o.is_late_delivery
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    JOIN staging.products p ON p.product_id = oi.product_id
    WHERE o.status = 'delivered'
      AND o.delivery_duration_hours >= 0
)
SELECT category, COUNT(*) AS delivered_order_category_pairs,
       ROUND(AVG(delivery_duration_hours)::NUMERIC, 2) AS average_hours,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delivery_duration_hours)
           AS median_hours,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_late_delivery) / COUNT(*), 2)
           AS late_rate_pct
FROM order_categories
GROUP BY category
ORDER BY average_hours DESC;

-- Satisfaction comparison for eligible deliveries with an associated review.
SELECT CASE WHEN o.is_late_delivery THEN 'Late' ELSE 'On time' END AS delivery_group,
       COUNT(*) AS review_rows,
       COUNT(DISTINCT r.order_id) AS reviewed_orders,
       ROUND(AVG(r.review_score)::NUMERIC, 3) AS average_review_score,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY r.review_score)
           AS median_review_score
FROM staging.orders o
JOIN staging.order_reviews r ON r.order_id = o.order_id
WHERE o.status = 'delivered'
  AND o.delivery_duration_hours >= 0
  AND o.is_late_delivery IS NOT NULL
GROUP BY o.is_late_delivery
ORDER BY o.is_late_delivery;

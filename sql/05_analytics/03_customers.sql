-- Phase 9: customer analytics at person grain (customer_unique_id).
-- Transaction value is delivered merchandise price; all orders count toward
-- frequency and timing. A customer account can represent only one order, so
-- customer_id must not be used as the returning-person grain.
-- Run from the repository root:
-- docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/03_customers.sql

WITH customer_orders AS (
    SELECT c.customer_unique_id,
           o.order_id,
           o.purchased_at,
           o.status,
           COALESCE(SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered'), 0)
               AS delivered_merchandise_brl
    FROM staging.customers c
    JOIN staging.orders o ON o.customer_id = c.customer_id
    LEFT JOIN staging.order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_unique_id, o.order_id, o.purchased_at, o.status
),
customer_summary AS (
    SELECT customer_unique_id,
           COUNT(*) AS order_count,
           COUNT(*) FILTER (WHERE status = 'delivered') AS delivered_order_count,
           SUM(delivered_merchandise_brl) AS delivered_merchandise_brl,
           MIN(purchased_at) AS first_order_at,
           MAX(purchased_at) AS last_order_at
    FROM customer_orders
    GROUP BY customer_unique_id
)
SELECT COUNT(*) AS unique_customers,
       COUNT(*) FILTER (WHERE order_count = 1) AS one_order_customers,
       COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers,
       ROUND(
           100.0 * COUNT(*) FILTER (WHERE order_count > 1) / COUNT(*),
           2
       ) AS repeat_customer_pct,
       ROUND(AVG(delivered_merchandise_brl), 2)
           AS average_delivered_spend_per_customer,
       ROUND(AVG(delivered_merchandise_brl)
             FILTER (WHERE delivered_order_count > 0), 2)
           AS average_spend_per_customer_with_delivered_order
FROM customer_summary;

-- Order-frequency and spend distribution by person. Includes unique customers
-- with no delivered orders, whose delivered merchandise spend is zero.
WITH customer_orders AS (
    SELECT c.customer_unique_id, o.order_id, o.status,
           COALESCE(SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered'), 0)
               AS delivered_merchandise_brl
    FROM staging.customers c
    JOIN staging.orders o ON o.customer_id = c.customer_id
    LEFT JOIN staging.order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_unique_id, o.order_id, o.status
),
customer_summary AS (
    SELECT customer_unique_id,
           COUNT(*) AS order_count,
           SUM(delivered_merchandise_brl) AS delivered_merchandise_brl
    FROM customer_orders
    GROUP BY customer_unique_id
)
SELECT CASE
           WHEN order_count = 1 THEN '1 order'
           WHEN order_count = 2 THEN '2 orders'
           WHEN order_count = 3 THEN '3 orders'
           ELSE '4+ orders'
       END AS order_frequency,
       COUNT(*) AS customers,
       ROUND(AVG(delivered_merchandise_brl), 2)
           AS average_delivered_spend_brl,
       SUM(delivered_merchandise_brl) AS total_delivered_spend_brl
FROM customer_summary
GROUP BY CASE
             WHEN order_count = 1 THEN '1 order'
             WHEN order_count = 2 THEN '2 orders'
             WHEN order_count = 3 THEN '3 orders'
             ELSE '4+ orders'
         END
ORDER BY MIN(order_count);

-- Highest-value customers by delivered merchandise spend; tie-break by ID.
WITH customer_order_value AS (
    SELECT c.customer_unique_id, o.order_id, o.status,
           COALESCE(SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered'), 0)
               AS delivered_merchandise_brl
    FROM staging.customers c
    JOIN staging.orders o ON o.customer_id = c.customer_id
    LEFT JOIN staging.order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_unique_id, o.order_id, o.status
),
customer_summary AS (
    SELECT customer_unique_id,
           COUNT(*) AS order_count,
           COUNT(*) FILTER (WHERE status = 'delivered') AS delivered_order_count,
           SUM(delivered_merchandise_brl) AS delivered_merchandise_brl
    FROM customer_order_value
    GROUP BY customer_unique_id
)
SELECT customer_unique_id, order_count, delivered_order_count,
       delivered_merchandise_brl,
       ROUND(
           delivered_merchandise_brl / NULLIF(delivered_order_count, 0),
           2
       ) AS average_delivered_order_value_brl,
       RANK() OVER (ORDER BY delivered_merchandise_brl DESC) AS customer_value_rank
FROM customer_summary
ORDER BY delivered_merchandise_brl DESC, customer_unique_id
LIMIT 20;

-- Purchases per customer and time between consecutive purchases.
WITH customer_purchase_events AS (
    SELECT DISTINCT c.customer_unique_id, o.order_id, o.purchased_at
    FROM staging.customers c
    JOIN staging.orders o ON o.customer_id = c.customer_id
),
purchase_intervals AS (
    SELECT customer_unique_id, order_id, purchased_at,
           purchased_at - LAG(purchased_at) OVER (
               PARTITION BY customer_unique_id ORDER BY purchased_at, order_id
           ) AS time_since_previous_order
    FROM customer_purchase_events
),
repeat_customer_intervals AS (
    SELECT *
    FROM purchase_intervals
    WHERE time_since_previous_order IS NOT NULL
)
SELECT COUNT(DISTINCT customer_unique_id) AS repeat_customers_with_interval,
       COUNT(*) AS repeat_purchase_intervals,
       ROUND(AVG(EXTRACT(EPOCH FROM time_since_previous_order) / 86400)::NUMERIC, 2)
           AS average_days_between_orders,
       PERCENTILE_CONT(0.5) WITHIN GROUP (
           ORDER BY EXTRACT(EPOCH FROM time_since_previous_order) / 86400
       ) AS median_days_between_orders,
       MIN(time_since_previous_order) AS shortest_interval,
       MAX(time_since_previous_order) AS longest_interval
FROM repeat_customer_intervals;

-- Region ranking by unique customers and delivered merchandise spend.
WITH customer_order_sales AS (
    SELECT c.customer_unique_id,
           c.state,
           o.order_id,
           o.status,
           COALESCE(SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered'), 0)
               AS delivered_merchandise_brl
    FROM staging.customers c
    JOIN staging.orders o ON o.customer_id = c.customer_id
    LEFT JOIN staging.order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_unique_id, c.state, o.order_id, o.status
),
customer_state_summary AS (
    SELECT customer_unique_id, state,
           COUNT(*) AS order_count,
           SUM(delivered_merchandise_brl) AS delivered_merchandise_brl
    FROM customer_order_sales
    GROUP BY customer_unique_id, state
)
SELECT state,
       COUNT(*) AS unique_customers,
       SUM(order_count) AS orders,
       SUM(delivered_merchandise_brl) AS delivered_merchandise_brl,
       ROUND(AVG(delivered_merchandise_brl), 2)
           AS average_delivered_spend_per_customer_brl,
       RANK() OVER (ORDER BY AVG(delivered_merchandise_brl) DESC)
           AS average_customer_value_rank
FROM customer_state_summary
GROUP BY state
ORDER BY average_delivered_spend_per_customer_brl DESC, state;

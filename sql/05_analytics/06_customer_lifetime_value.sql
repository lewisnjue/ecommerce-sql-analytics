-- Phase 12: historical customer value and a constrained 12-month CLV proxy.
-- Delivered merchandise sales only; this is revenue, not gross profit.
-- The forward-looking proxy is emitted only for repeat buyers with at least
-- 30 days between first and last delivered purchase; shorter windows produce
-- unstable annualization and are not extrapolated.
WITH customer_orders AS (
    SELECT c.customer_unique_id, o.order_id, o.purchased_at, o.status,
           SUM(oi.price_brl) AS delivered_revenue_brl
    FROM staging.customers c
    JOIN staging.orders o ON o.customer_id = c.customer_id
    LEFT JOIN staging.order_items oi
        ON oi.order_id = o.order_id AND o.status = 'delivered'
    GROUP BY c.customer_unique_id, o.order_id, o.purchased_at, o.status
),
customer_value AS (
    SELECT customer_unique_id,
           COUNT(*) FILTER (WHERE status = 'delivered') AS total_orders,
           COALESCE(SUM(delivered_revenue_brl), 0) AS total_revenue_brl,
           MIN(purchased_at) FILTER (WHERE status = 'delivered') AS first_purchase_at,
           MAX(purchased_at) FILTER (WHERE status = 'delivered') AS last_purchase_at
    FROM customer_orders
    GROUP BY customer_unique_id
),
customer_metrics AS (
    SELECT *,
           EXTRACT(EPOCH FROM (last_purchase_at - first_purchase_at)) / 86400
               AS customer_lifespan_days,
           total_revenue_brl / NULLIF(total_orders, 0) AS average_order_value_brl,
           CASE WHEN last_purchase_at - first_purchase_at >= INTERVAL '30 days'
                THEN total_orders * 365.25
                     / (EXTRACT(EPOCH FROM (
                         last_purchase_at - first_purchase_at
                     )) / 86400)
           END AS annual_purchase_frequency
    FROM customer_value
),
ltv_estimates AS (
    SELECT *,
           CASE WHEN total_orders >= 2 AND annual_purchase_frequency IS NOT NULL
                THEN average_order_value_brl * annual_purchase_frequency
           END AS estimated_12m_ltv_proxy_brl
    FROM customer_metrics
)
SELECT CASE WHEN total_orders >= 2 THEN 'Repeat delivered buyer'
            WHEN total_orders = 1 THEN 'One delivered order'
            ELSE 'No delivered order'
       END AS customer_type,
       COUNT(*) AS customers,
       ROUND(AVG(total_revenue_brl), 2) AS average_historical_revenue_brl,
       ROUND(AVG(average_order_value_brl)
             FILTER (WHERE total_orders > 0), 2) AS average_order_value_brl,
       ROUND(AVG(customer_lifespan_days)
             FILTER (WHERE total_orders >= 2), 1) AS average_observed_lifespan_days,
       ROUND(AVG(annual_purchase_frequency)
             FILTER (WHERE annual_purchase_frequency IS NOT NULL), 2)
           AS average_annual_purchase_frequency,
       ROUND(AVG(estimated_12m_ltv_proxy_brl)
             FILTER (WHERE estimated_12m_ltv_proxy_brl IS NOT NULL), 2)
           AS average_estimated_12m_ltv_proxy_brl
FROM ltv_estimates
GROUP BY customer_type
ORDER BY customer_type;

-- Customer-level history and estimated proxy; one-time customers deliberately
-- have no forward value estimate because repeat frequency is not observed.
WITH customer_orders AS (
    SELECT c.customer_unique_id, o.order_id, o.purchased_at, o.status,
           SUM(oi.price_brl) AS delivered_revenue_brl
    FROM staging.customers c
    JOIN staging.orders o ON o.customer_id = c.customer_id
    LEFT JOIN staging.order_items oi
        ON oi.order_id = o.order_id AND o.status = 'delivered'
    GROUP BY c.customer_unique_id, o.order_id, o.purchased_at, o.status
),
customer_value AS (
    SELECT customer_unique_id,
           COUNT(*) FILTER (WHERE status = 'delivered') AS total_orders,
           COALESCE(SUM(delivered_revenue_brl), 0) AS total_revenue_brl,
           MIN(purchased_at) FILTER (WHERE status = 'delivered') AS first_purchase_at,
           MAX(purchased_at) FILTER (WHERE status = 'delivered') AS last_purchase_at
    FROM customer_orders
    GROUP BY customer_unique_id
),
metrics AS (
    SELECT *,
           EXTRACT(EPOCH FROM (last_purchase_at - first_purchase_at)) / 86400
               AS customer_lifespan_days,
           total_revenue_brl / NULLIF(total_orders, 0) AS average_order_value_brl,
           CASE WHEN last_purchase_at - first_purchase_at >= INTERVAL '30 days'
                THEN total_orders * 365.25
                     / (EXTRACT(EPOCH FROM (
                         last_purchase_at - first_purchase_at
                     )) / 86400)
           END AS annual_purchase_frequency
    FROM customer_value
)
SELECT customer_unique_id, total_orders, total_revenue_brl,
       ROUND(average_order_value_brl, 2) AS average_order_value_brl,
       ROUND(customer_lifespan_days::NUMERIC, 1) AS customer_lifespan_days,
       ROUND(annual_purchase_frequency::NUMERIC, 2)
           AS annual_purchase_frequency,
       ROUND((average_order_value_brl * annual_purchase_frequency)::NUMERIC, 2)
           AS estimated_12m_ltv_proxy_brl
FROM metrics
WHERE total_orders >= 2 AND annual_purchase_frequency IS NOT NULL
ORDER BY estimated_12m_ltv_proxy_brl DESC, customer_unique_id
LIMIT 20;

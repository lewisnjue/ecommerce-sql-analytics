-- Phase 17: advanced SQL patterns using the staged Olist data.

-- Conditional aggregation: order-status mix by customer destination state.
SELECT c.state AS customer_state,
       COUNT(*) AS all_orders,
       COUNT(*) FILTER (WHERE o.status = 'delivered') AS delivered_orders,
       COUNT(*) FILTER (WHERE o.status = 'canceled') AS canceled_orders,
       COUNT(*) FILTER (
           WHERE o.status NOT IN ('delivered', 'canceled')
       ) AS other_status_orders
FROM staging.customers c
JOIN staging.orders o ON o.customer_id = c.customer_id
GROUP BY c.state
ORDER BY all_orders DESC;

-- Subquery and correlated subquery: products whose delivered sales exceed
-- the average product sales in their own category.
WITH product_sales AS (
    SELECT p.product_id,
           COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
               AS category,
           SUM(oi.price_brl) AS revenue_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    JOIN staging.products p ON p.product_id = oi.product_id
    WHERE o.status = 'delivered'
    GROUP BY p.product_id,
             COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
)
SELECT ps.product_id, ps.category, ps.revenue_brl,
       (
           SELECT AVG(peer.revenue_brl)
           FROM product_sales peer
           WHERE peer.category = ps.category
       ) AS category_average_product_revenue_brl
FROM product_sales ps
WHERE ps.revenue_brl > (
    SELECT AVG(peer.revenue_brl)
    FROM product_sales peer
    WHERE peer.category = ps.category
)
ORDER BY ps.revenue_brl DESC, ps.product_id
LIMIT 25;

-- Ordered-set percentiles on delivered merchandise order values.
WITH order_values AS (
    SELECT o.order_id, SUM(oi.price_brl) AS merchandise_value_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY o.order_id
)
SELECT COUNT(*) AS delivered_orders,
       ROUND(AVG(merchandise_value_brl), 2) AS mean_order_value_brl,
       PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY merchandise_value_brl)
           AS median_order_value_brl,
       PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY merchandise_value_brl)
           AS p90_order_value_brl,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY merchandise_value_brl)
           AS p95_order_value_brl
FROM order_values;

-- Window functions: previous/next month, cumulative sales, and trailing
-- three-month average over a complete calendar series.
WITH monthly_sales AS (
    SELECT o.purchase_month AS revenue_month, SUM(oi.price_brl) AS revenue_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY o.purchase_month
),
calendar AS (
    SELECT GENERATE_SERIES(
               DATE_TRUNC('month', MIN(purchased_at)),
               DATE_TRUNC('month', MAX(purchased_at)),
               INTERVAL '1 month'
           )::DATE AS revenue_month
    FROM staging.orders
),
monthly AS (
    SELECT c.revenue_month, COALESCE(ms.revenue_brl, 0::NUMERIC) AS revenue_brl
    FROM calendar c
    LEFT JOIN monthly_sales ms USING (revenue_month)
),
monthly_windows AS (
    SELECT revenue_month, revenue_brl,
           LAG(revenue_brl) OVER (ORDER BY revenue_month) AS previous_month_brl,
           LEAD(revenue_brl) OVER (ORDER BY revenue_month) AS next_month_brl,
           SUM(revenue_brl) OVER (
               ORDER BY revenue_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS cumulative_revenue_brl,
           AVG(revenue_brl) OVER (
               ORDER BY revenue_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
           ) AS trailing_three_month_avg_brl
    FROM monthly
)
SELECT revenue_month, revenue_brl, previous_month_brl, next_month_brl,
       cumulative_revenue_brl,
       ROUND(trailing_three_month_avg_brl, 2) AS trailing_three_month_avg_brl
FROM monthly_windows
ORDER BY revenue_month;

-- Pareto analysis: determine how many products generate the first 80% of
-- delivered merchandise sales and expose cumulative share for the top 20.
WITH product_sales AS (
    SELECT oi.product_id, SUM(oi.price_brl) AS revenue_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY oi.product_id
),
pareto AS (
    SELECT product_id, revenue_brl,
           SUM(revenue_brl) OVER (
               ORDER BY revenue_brl DESC, product_id
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS cumulative_revenue_brl,
           SUM(revenue_brl) OVER () AS total_revenue_brl,
           ROW_NUMBER() OVER (ORDER BY revenue_brl DESC, product_id) AS product_rank
    FROM product_sales
)
SELECT MIN(product_rank) FILTER (
           WHERE cumulative_revenue_brl >= 0.80 * total_revenue_brl
       ) AS products_needed_to_reach_80_pct,
       MAX(total_revenue_brl) AS total_delivered_revenue_brl
FROM pareto;

WITH product_sales AS (
    SELECT oi.product_id, SUM(oi.price_brl) AS revenue_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY oi.product_id
),
pareto AS (
    SELECT product_id, revenue_brl,
           SUM(revenue_brl) OVER (
               ORDER BY revenue_brl DESC, product_id
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS cumulative_revenue_brl,
           SUM(revenue_brl) OVER () AS total_revenue_brl
    FROM product_sales
)
SELECT product_id, revenue_brl, cumulative_revenue_brl,
       ROUND(100.0 * cumulative_revenue_brl / total_revenue_brl, 2)
           AS cumulative_revenue_share_pct
FROM pareto
ORDER BY revenue_brl DESC, product_id
LIMIT 20;

-- Top-N-per-group: three highest-revenue sellers in each seller state.
WITH seller_sales AS (
    SELECT s.state, s.seller_id, SUM(oi.price_brl) AS revenue_brl
    FROM staging.sellers s
    JOIN staging.order_items oi ON oi.seller_id = s.seller_id
    JOIN staging.orders o ON o.order_id = oi.order_id
    WHERE o.status = 'delivered'
    GROUP BY s.state, s.seller_id
),
ranked_sellers AS (
    SELECT state, seller_id, revenue_brl,
           ROW_NUMBER() OVER (
               PARTITION BY state ORDER BY revenue_brl DESC, seller_id
           ) AS state_revenue_row
    FROM seller_sales
)
SELECT state, seller_id, revenue_brl, state_revenue_row
FROM ranked_sellers
WHERE state_revenue_row <= 3
ORDER BY state, state_revenue_row;

-- First/last event analysis: earliest and most recent order per person.
WITH customer_orders AS (
    SELECT c.customer_unique_id, o.order_id, o.purchased_at,
           COUNT(*) OVER (PARTITION BY c.customer_unique_id) AS order_count,
           FIRST_VALUE(o.order_id) OVER (
               PARTITION BY c.customer_unique_id
               ORDER BY o.purchased_at, o.order_id
           ) AS first_order_id,
           FIRST_VALUE(o.purchased_at) OVER (
               PARTITION BY c.customer_unique_id
               ORDER BY o.purchased_at, o.order_id
           ) AS first_order_at,
           LAST_VALUE(o.order_id) OVER (
               PARTITION BY c.customer_unique_id
               ORDER BY o.purchased_at, o.order_id
               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
           ) AS last_order_id,
           LAST_VALUE(o.purchased_at) OVER (
               PARTITION BY c.customer_unique_id
               ORDER BY o.purchased_at, o.order_id
               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
           ) AS last_order_at
    FROM staging.customers c
    JOIN staging.orders o ON o.customer_id = c.customer_id
)
SELECT DISTINCT customer_unique_id, order_count,
       first_order_id, first_order_at, last_order_id, last_order_at
FROM customer_orders
WHERE order_count > 1
ORDER BY order_count DESC, customer_unique_id
LIMIT 25;

-- The dataset has no natural hierarchy for a recursive CTE. A generated
-- calendar is used above instead of adding a recursive example without a
-- relevant business use case.

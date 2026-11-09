-- Phase 8: revenue analysis.
-- Primary metric: delivered merchandise sales = order-item price for orders
-- whose order status is delivered. Freight is reported separately. This avoids
-- counting payment installments as separate revenue and excludes unfulfilled
-- orders. All monetary values are BRL.
-- Run from the repository root:
-- docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/02_revenue.sql

-- Overall sales and order value. An order can contain multiple order-item rows.
WITH delivered_order_totals AS (
    SELECT o.order_id,
           SUM(oi.price_brl) AS merchandise_revenue_brl,
           SUM(oi.freight_brl) AS freight_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY o.order_id
)
SELECT COUNT(*) AS delivered_orders,
       SUM(merchandise_revenue_brl) AS total_merchandise_revenue_brl,
       SUM(freight_brl) AS total_freight_brl,
       SUM(merchandise_revenue_brl + freight_brl) AS total_with_freight_brl,
       ROUND(AVG(merchandise_revenue_brl), 2) AS average_order_value_brl,
       ROUND(AVG(merchandise_revenue_brl + freight_brl), 2)
           AS average_order_value_with_freight_brl
FROM delivered_order_totals;

-- Monthly trend, including zero-order months. A missing prior-month baseline
-- or zero prior-month sales returns NULL growth instead of a misleading rate.
WITH month_bounds AS (
    SELECT DATE_TRUNC('month', MIN(purchased_at))::DATE AS first_month,
           DATE_TRUNC('month', MAX(purchased_at))::DATE AS last_month
    FROM staging.orders
),
calendar_months AS (
    SELECT GENERATE_SERIES(first_month, last_month, INTERVAL '1 month')::DATE
               AS revenue_month
    FROM month_bounds
),
monthly_sales AS (
    SELECT o.purchase_month AS revenue_month,
           COUNT(DISTINCT o.order_id) AS delivered_orders,
           SUM(oi.price_brl) AS merchandise_revenue_brl,
           SUM(oi.freight_brl) AS freight_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY o.purchase_month
),
complete_months AS (
    SELECT cm.revenue_month,
           COALESCE(ms.delivered_orders, 0) AS delivered_orders,
           COALESCE(ms.merchandise_revenue_brl, 0::NUMERIC)
               AS merchandise_revenue_brl,
           COALESCE(ms.freight_brl, 0::NUMERIC) AS freight_brl
    FROM calendar_months cm
    LEFT JOIN monthly_sales ms USING (revenue_month)
),
monthly_comparison AS (
    SELECT revenue_month, delivered_orders, merchandise_revenue_brl, freight_brl,
           LAG(merchandise_revenue_brl) OVER (ORDER BY revenue_month)
               AS previous_month_revenue_brl,
           SUM(merchandise_revenue_brl) OVER (
               ORDER BY revenue_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS cumulative_revenue_brl,
           AVG(merchandise_revenue_brl) OVER (
               ORDER BY revenue_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
           ) AS rolling_3_month_average_brl,
           RANK() OVER (
               ORDER BY merchandise_revenue_brl DESC
           ) AS revenue_rank,
           DENSE_RANK() OVER (
               ORDER BY merchandise_revenue_brl DESC
           ) AS dense_revenue_rank
    FROM complete_months
)
SELECT revenue_month, delivered_orders, merchandise_revenue_brl, freight_brl,
       previous_month_revenue_brl,
       ROUND(
           100.0 * (merchandise_revenue_brl - previous_month_revenue_brl)
           / NULLIF(previous_month_revenue_brl, 0),
           2
       ) AS mom_growth_pct,
       cumulative_revenue_brl,
       ROUND(rolling_3_month_average_brl, 2) AS rolling_3_month_average_brl,
       revenue_rank,
       dense_revenue_rank
FROM monthly_comparison
ORDER BY revenue_month;

-- Annual delivered merchandise sales and freight.
SELECT EXTRACT(YEAR FROM o.purchased_at)::INTEGER AS revenue_year,
       COUNT(DISTINCT o.order_id) AS delivered_orders,
       SUM(oi.price_brl) AS merchandise_revenue_brl,
       SUM(oi.freight_brl) AS freight_brl
FROM staging.orders o
JOIN staging.order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'delivered'
GROUP BY EXTRACT(YEAR FROM o.purchased_at)::INTEGER
ORDER BY revenue_year;

-- Product category ranking. Products without category metadata are retained.
SELECT COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
           AS product_category,
       COUNT(DISTINCT o.order_id) AS delivered_orders,
       COUNT(*) AS item_rows,
       SUM(oi.price_brl) AS merchandise_revenue_brl,
       SUM(oi.freight_brl) AS freight_brl,
       RANK() OVER (ORDER BY SUM(oi.price_brl) DESC) AS revenue_rank
FROM staging.orders o
JOIN staging.order_items oi ON oi.order_id = o.order_id
JOIN staging.products p ON p.product_id = oi.product_id
WHERE o.status = 'delivered'
GROUP BY COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
ORDER BY merchandise_revenue_brl DESC, product_category;

-- Geographic revenue by customer state.
SELECT c.state AS customer_state,
       COUNT(DISTINCT o.order_id) AS delivered_orders,
       SUM(oi.price_brl) AS merchandise_revenue_brl,
       RANK() OVER (ORDER BY SUM(oi.price_brl) DESC) AS revenue_rank
FROM staging.orders o
JOIN staging.customers c ON c.customer_id = o.customer_id
JOIN staging.order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'delivered'
GROUP BY c.state
ORDER BY merchandise_revenue_brl DESC, customer_state;

-- Seller ranking by merchandise sales attributed to the order-item seller.
WITH seller_sales AS (
    SELECT s.seller_id, s.state AS seller_state,
           COUNT(DISTINCT o.order_id) AS delivered_orders,
           COUNT(*) AS delivered_item_rows,
           SUM(oi.price_brl) AS merchandise_revenue_brl,
           SUM(oi.freight_brl) AS freight_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    JOIN staging.sellers s ON s.seller_id = oi.seller_id
    WHERE o.status = 'delivered'
    GROUP BY s.seller_id, s.state
)
SELECT seller_id, seller_state, delivered_orders, delivered_item_rows,
       merchandise_revenue_brl, freight_brl,
       RANK() OVER (ORDER BY merchandise_revenue_brl DESC) AS revenue_rank
FROM seller_sales
ORDER BY merchandise_revenue_brl DESC, seller_id
LIMIT 20;

-- Product ranking and contribution of the top ten products to total
-- delivered merchandise sales. Window aggregates retain the all-product base.
WITH product_sales AS (
    SELECT p.product_id,
           COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
               AS product_category,
           COUNT(DISTINCT o.order_id) AS delivered_orders,
           COUNT(*) AS delivered_item_rows,
           SUM(oi.price_brl) AS merchandise_revenue_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    JOIN staging.products p ON p.product_id = oi.product_id
    WHERE o.status = 'delivered'
    GROUP BY p.product_id,
             COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
),
ranked_products AS (
    SELECT *,
           RANK() OVER (ORDER BY merchandise_revenue_brl DESC) AS revenue_rank,
           SUM(merchandise_revenue_brl) OVER (
               ORDER BY merchandise_revenue_brl DESC, product_id
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS cumulative_revenue_brl,
           SUM(merchandise_revenue_brl) OVER () AS total_revenue_brl
    FROM product_sales
)
SELECT product_id, product_category, delivered_orders, delivered_item_rows,
       merchandise_revenue_brl, revenue_rank,
       ROUND(100.0 * merchandise_revenue_brl / NULLIF(total_revenue_brl, 0), 4)
           AS revenue_share_pct,
       ROUND(100.0 * cumulative_revenue_brl / NULLIF(total_revenue_brl, 0), 2)
           AS cumulative_revenue_share_pct
FROM ranked_products
ORDER BY revenue_rank, product_id
LIMIT 20;

WITH product_sales AS (
    SELECT p.product_id, SUM(oi.price_brl) AS merchandise_revenue_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    JOIN staging.products p ON p.product_id = oi.product_id
    WHERE o.status = 'delivered'
    GROUP BY p.product_id
),
ranked_products AS (
    SELECT product_id, merchandise_revenue_brl,
           ROW_NUMBER() OVER (
               ORDER BY merchandise_revenue_brl DESC, product_id
           ) AS product_position
    FROM product_sales
)
SELECT SUM(merchandise_revenue_brl) AS top_10_product_revenue_brl,
       MAX(total.total_revenue_brl) AS total_merchandise_revenue_brl,
       ROUND(
           100.0 * SUM(merchandise_revenue_brl)
           / NULLIF(MAX(total.total_revenue_brl), 0),
           2
       ) AS top_10_revenue_share_pct
FROM ranked_products
CROSS JOIN (
    SELECT SUM(merchandise_revenue_brl) AS total_revenue_brl
    FROM product_sales
) total
WHERE product_position <= 10;

-- Revenue-change overview: year-over-year comparison. A partial year remains
-- visible and must not be interpreted as a full-year growth comparison.
WITH annual_sales AS (
    SELECT EXTRACT(YEAR FROM o.purchased_at)::INTEGER AS revenue_year,
           SUM(oi.price_brl) AS merchandise_revenue_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY EXTRACT(YEAR FROM o.purchased_at)::INTEGER
),
annual_comparison AS (
    SELECT revenue_year, merchandise_revenue_brl,
           LAG(merchandise_revenue_brl) OVER (ORDER BY revenue_year)
               AS previous_year_revenue_brl
    FROM annual_sales
)
SELECT revenue_year, merchandise_revenue_brl, previous_year_revenue_brl,
       ROUND(
           100.0 * (merchandise_revenue_brl - previous_year_revenue_brl)
           / NULLIF(previous_year_revenue_brl, 0),
           2
       ) AS yoy_growth_pct
FROM annual_comparison
ORDER BY revenue_year;

-- Phase 7: exploratory SQL using the normalized staging layer.
-- Run from the repository root:
-- docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/01_exploration.sql

-- Dataset size: row counts for the main business entities and supporting data.
SELECT 'customers' AS entity, COUNT(*) AS row_count FROM staging.customers
UNION ALL
SELECT 'orders', COUNT(*) FROM staging.orders
UNION ALL
SELECT 'products', COUNT(*) FROM staging.products
UNION ALL
SELECT 'sellers', COUNT(*) FROM staging.sellers
UNION ALL
SELECT 'order_items', COUNT(*) FROM staging.order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM staging.order_payments
UNION ALL
SELECT 'reviews', COUNT(*) FROM staging.order_reviews
UNION ALL
SELECT 'geolocation rows', COUNT(*) FROM staging.geolocation
ORDER BY entity;

-- Time range for orders.
SELECT
    MIN(purchase_date) AS first_order_date,
    MAX(purchase_date) AS last_order_date,
    MIN(purchased_at) AS first_purchase_timestamp,
    MAX(purchased_at) AS last_purchase_timestamp
FROM staging.orders;

-- Orders per month; months without orders are not generated as zero rows.
SELECT purchase_month,
       COUNT(*) AS order_count,
       COUNT(DISTINCT customer_id) AS ordering_customer_accounts
FROM staging.orders
GROUP BY purchase_month
ORDER BY purchase_month;

-- HAVING filters aggregated groups; surface months with at least 5,000 orders.
SELECT purchase_month, COUNT(*) AS order_count
FROM staging.orders
GROUP BY purchase_month
HAVING COUNT(*) >= 5000
ORDER BY order_count DESC, purchase_month;

-- Orders per year.
SELECT EXTRACT(YEAR FROM purchased_at)::INTEGER AS order_year,
       COUNT(*) AS order_count
FROM staging.orders
GROUP BY EXTRACT(YEAR FROM purchased_at)::INTEGER
ORDER BY order_year;

-- Status distribution with a presentation-friendly label and share of orders.
SELECT
    CASE status
        WHEN 'delivered' THEN 'Delivered'
        WHEN 'canceled' THEN 'Cancelled'
        WHEN 'unavailable' THEN 'Unavailable'
        WHEN 'processing' THEN 'Processing'
        WHEN 'shipped' THEN 'Shipped'
        WHEN 'invoiced' THEN 'Invoiced'
        WHEN 'created' THEN 'Created'
        WHEN 'approved' THEN 'Approved'
        ELSE 'Other'
    END AS order_status,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
FROM staging.orders
GROUP BY status
ORDER BY order_count DESC, order_status;

-- Customer accounts and distinct person-level customers by customer state.
SELECT state,
       COUNT(*) AS customer_accounts,
       COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM staging.customers
GROUP BY state
ORDER BY unique_customers DESC, state;

-- Sellers by seller state.
SELECT state,
       COUNT(*) AS seller_count
FROM staging.sellers
GROUP BY state
ORDER BY seller_count DESC, state;

-- Delivered merchandise revenue by customer state.
-- Revenue here is item price (BRL), excluding freight, payments, and non-delivered
-- orders. This is a descriptive merchandise-sales measure, not accounting revenue.
SELECT c.state AS customer_state,
       COUNT(DISTINCT o.order_id) AS delivered_orders,
       COUNT(*) AS delivered_order_items,
       SUM(oi.price_brl) AS merchandise_revenue_brl
FROM staging.orders o
JOIN staging.customers c ON c.customer_id = o.customer_id
JOIN staging.order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'delivered'
GROUP BY c.state
ORDER BY merchandise_revenue_brl DESC, customer_state;

-- Delivered merchandise revenue by seller state, at order-item grain.
SELECT s.state AS seller_state,
       COUNT(DISTINCT o.order_id) AS delivered_orders,
       COUNT(*) AS delivered_order_items,
       SUM(oi.price_brl) AS merchandise_revenue_brl
FROM staging.orders o
JOIN staging.order_items oi ON oi.order_id = o.order_id
JOIN staging.sellers s ON s.seller_id = oi.seller_id
WHERE o.status = 'delivered'
GROUP BY s.state
ORDER BY merchandise_revenue_brl DESC, seller_state;

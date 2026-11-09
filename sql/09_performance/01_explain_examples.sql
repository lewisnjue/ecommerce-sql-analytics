-- Phase 19 benchmark query: monthly delivered merchandise sales.
-- Run once before and once after creating the measured index:
-- sql/08_indexes/01_analytical_indexes.sql
EXPLAIN (ANALYZE, BUFFERS, TIMING ON)
SELECT SUM(oi.price_brl) AS merchandise_revenue_brl
FROM staging.orders o
JOIN staging.order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'delivered'
  AND o.purchase_month = DATE '2018-08-01';

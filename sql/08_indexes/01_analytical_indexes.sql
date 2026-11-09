-- Phase 19: indexes selected from the measured plan in
-- sql/09_performance/01_explain_examples.sql.
-- This composite index supports delivered-order month filtering and supplies
-- order_id for the subsequent order-items join.
CREATE INDEX IF NOT EXISTS idx_stg_orders_status_month_order
    ON staging.orders (status, purchase_month, order_id);

-- Phase 19 assertions: the indexed benchmark preserves its result and the
-- intended composite index is present.
DO $$
DECLARE
    benchmark_revenue NUMERIC;
    view_revenue NUMERIC;
    benchmark_index_exists BOOLEAN;
BEGIN
    SELECT SUM(oi.price_brl)
    INTO benchmark_revenue
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
      AND o.purchase_month = DATE '2018-08-01';

    SELECT merchandise_revenue_brl
    INTO view_revenue
    FROM analytics.monthly_revenue
    WHERE revenue_month = DATE '2018-08-01';

    SELECT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE schemaname = 'staging'
          AND indexname = 'idx_stg_orders_status_month_order'
    )
    INTO benchmark_index_exists;

    IF benchmark_revenue IS DISTINCT FROM view_revenue
       OR NOT benchmark_index_exists THEN
        RAISE EXCEPTION 'Performance benchmark result or index check failed';
    END IF;
END
$$;

SELECT 'Performance checks passed' AS result;

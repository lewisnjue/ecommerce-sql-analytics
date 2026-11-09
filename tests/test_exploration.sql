-- Phase 7 assertions: aggregation outputs must reconcile to their source grain.
DO $$
BEGIN
    IF (SELECT SUM(order_count) FROM (
            SELECT COUNT(*) AS order_count
            FROM staging.orders
            GROUP BY purchase_month
        ) monthly_orders) <> (SELECT COUNT(*) FROM staging.orders) THEN
        RAISE EXCEPTION 'Monthly order counts do not reconcile to staged orders';
    END IF;

    IF (SELECT SUM(order_count) FROM (
            SELECT COUNT(*) AS order_count
            FROM staging.orders
            GROUP BY EXTRACT(YEAR FROM purchased_at)
        ) yearly_orders) <> (SELECT COUNT(*) FROM staging.orders) THEN
        RAISE EXCEPTION 'Yearly order counts do not reconcile to staged orders';
    END IF;

    IF (SELECT SUM(order_count) FROM (
            SELECT COUNT(*) AS order_count
            FROM staging.orders
            GROUP BY status
        ) status_counts) <> (SELECT COUNT(*) FROM staging.orders) THEN
        RAISE EXCEPTION 'Status counts do not reconcile to staged orders';
    END IF;

    IF (SELECT SUM(merchandise_revenue_brl) FROM (
            SELECT c.state, SUM(oi.price_brl) AS merchandise_revenue_brl
            FROM staging.orders o
            JOIN staging.customers c ON c.customer_id = o.customer_id
            JOIN staging.order_items oi ON oi.order_id = o.order_id
            WHERE o.status = 'delivered'
            GROUP BY c.state
        ) customer_state_revenue)
       <> (SELECT SUM(oi.price_brl)
           FROM staging.orders o
           JOIN staging.order_items oi ON oi.order_id = o.order_id
           WHERE o.status = 'delivered') THEN
        RAISE EXCEPTION 'Customer-state revenue does not reconcile to delivered items';
    END IF;

    IF (SELECT SUM(merchandise_revenue_brl) FROM (
            SELECT s.state, SUM(oi.price_brl) AS merchandise_revenue_brl
            FROM staging.orders o
            JOIN staging.order_items oi ON oi.order_id = o.order_id
            JOIN staging.sellers s ON s.seller_id = oi.seller_id
            WHERE o.status = 'delivered'
            GROUP BY s.state
        ) seller_state_revenue)
       <> (SELECT SUM(oi.price_brl)
           FROM staging.orders o
           JOIN staging.order_items oi ON oi.order_id = o.order_id
           WHERE o.status = 'delivered') THEN
        RAISE EXCEPTION 'Seller-state revenue does not reconcile to delivered items';
    END IF;
END
$$;

SELECT 'Exploration aggregation checks passed' AS result;

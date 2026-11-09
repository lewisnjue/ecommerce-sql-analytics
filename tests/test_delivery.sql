-- Phase 15 checks: delivery population is bounded by delivered orders and
-- on-time/late groups reconcile to eligible reviewed orders.
DO $$
DECLARE
    eligible_deliveries BIGINT;
    reviewed_eligible_orders BIGINT;
    reviewed_delivery_groups BIGINT;
BEGIN
    SELECT COUNT(*) INTO eligible_deliveries
    FROM staging.orders
    WHERE status = 'delivered'
      AND customer_delivered_at IS NOT NULL
      AND delivery_duration_hours >= 0;

    IF eligible_deliveries = 0
       OR eligible_deliveries > (SELECT COUNT(*) FROM staging.orders
                                 WHERE status = 'delivered') THEN
        RAISE EXCEPTION 'Eligible delivery population is invalid';
    END IF;

    SELECT COUNT(DISTINCT o.order_id), COUNT(DISTINCT o.order_id)
        FILTER (WHERE o.is_late_delivery IS NOT NULL)
    INTO reviewed_eligible_orders, reviewed_delivery_groups
    FROM staging.orders o
    JOIN staging.order_reviews r ON r.order_id = o.order_id
    WHERE o.status = 'delivered'
      AND o.delivery_duration_hours >= 0;

    IF reviewed_eligible_orders <> reviewed_delivery_groups THEN
        RAISE EXCEPTION 'Some reviewed eligible deliveries lack an on-time/late classification';
    END IF;
END
$$;

SELECT 'Delivery analysis checks passed' AS result;

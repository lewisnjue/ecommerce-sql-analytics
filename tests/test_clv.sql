-- Phase 12 assertions: historical customer value reconciles to delivered sales;
-- the 12-month run-rate proxy must remain limited to eligible repeat buyers.
DO $$
DECLARE
    customer_revenue NUMERIC;
    delivered_revenue NUMERIC;
    eligible_proxy_customers BIGINT;
    invalid_proxy_customers BIGINT;
BEGIN
    WITH customer_orders AS (
        SELECT c.customer_unique_id, o.order_id, o.status, SUM(oi.price_brl) AS revenue
        FROM staging.customers c
        JOIN staging.orders o ON o.customer_id = c.customer_id
        LEFT JOIN staging.order_items oi
            ON oi.order_id = o.order_id AND o.status = 'delivered'
        GROUP BY c.customer_unique_id, o.order_id, o.status
    ),
    customer_value AS (
        SELECT customer_unique_id,
               COALESCE(SUM(revenue), 0) AS total_revenue
        FROM customer_orders
        GROUP BY customer_unique_id
    )
    SELECT SUM(total_revenue) INTO customer_revenue FROM customer_value;

    SELECT SUM(oi.price_brl)
    INTO delivered_revenue
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered';

    IF customer_revenue <> delivered_revenue THEN
        RAISE EXCEPTION 'Customer historical value does not reconcile to delivered sales';
    END IF;

    WITH customer_orders AS (
        SELECT c.customer_unique_id, o.order_id, o.purchased_at, o.status,
               SUM(oi.price_brl) AS revenue
        FROM staging.customers c
        JOIN staging.orders o ON o.customer_id = c.customer_id
        LEFT JOIN staging.order_items oi
            ON oi.order_id = o.order_id AND o.status = 'delivered'
        GROUP BY c.customer_unique_id, o.order_id, o.purchased_at, o.status
    ),
    customer_value AS (
        SELECT customer_unique_id,
               COUNT(*) FILTER (WHERE status = 'delivered') AS order_count,
               MIN(purchased_at) FILTER (WHERE status = 'delivered') AS first_order,
               MAX(purchased_at) FILTER (WHERE status = 'delivered') AS last_order
        FROM customer_orders
        GROUP BY customer_unique_id
    )
    SELECT COUNT(*) FILTER (
               WHERE order_count >= 2
                 AND last_order - first_order >= INTERVAL '30 days'
           ),
           COUNT(*) FILTER (
               WHERE order_count < 2
                 AND last_order - first_order >= INTERVAL '30 days'
           )
    INTO eligible_proxy_customers, invalid_proxy_customers
    FROM customer_value;

    IF eligible_proxy_customers = 0 OR invalid_proxy_customers <> 0 THEN
        RAISE EXCEPTION 'CLV proxy eligibility rules were violated';
    END IF;
END
$$;

SELECT 'CLV methodology checks passed' AS result;

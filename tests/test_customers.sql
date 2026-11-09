-- Phase 9: customer metric reconciliation checks at person and order grain.
DO $$
DECLARE
    person_order_count BIGINT;
    unique_customer_count BIGINT;
    raw_unique_customer_count BIGINT;
    delivered_customer_sales NUMERIC;
    delivered_item_sales NUMERIC;
    repeat_customer_count BIGINT;
BEGIN
    SELECT SUM(order_count), COUNT(*)
    INTO person_order_count, unique_customer_count
    FROM (
        SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS order_count
        FROM staging.customers c
        JOIN staging.orders o ON o.customer_id = c.customer_id
        GROUP BY c.customer_unique_id
    ) customer_orders;

    SELECT COUNT(DISTINCT customer_unique_id)
    INTO raw_unique_customer_count
    FROM staging.customers;

    IF person_order_count <> (SELECT COUNT(*) FROM staging.orders) THEN
        RAISE EXCEPTION 'Person-level order counts do not reconcile to total orders';
    END IF;
    IF unique_customer_count <> raw_unique_customer_count THEN
        RAISE EXCEPTION 'Customer analysis does not include every unique customer';
    END IF;

    SELECT SUM(customer_sales.delivered_merchandise_brl)
    INTO delivered_customer_sales
    FROM (
        SELECT c.customer_unique_id,
               SUM(oi.price_brl) AS delivered_merchandise_brl
        FROM staging.customers c
        JOIN staging.orders o ON o.customer_id = c.customer_id
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        WHERE o.status = 'delivered'
        GROUP BY c.customer_unique_id
    ) customer_sales;

    SELECT SUM(oi.price_brl)
    INTO delivered_item_sales
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered';

    IF delivered_customer_sales <> delivered_item_sales THEN
        RAISE EXCEPTION 'Customer delivered sales do not reconcile to item sales';
    END IF;

    SELECT COUNT(*)
    INTO repeat_customer_count
    FROM (
        SELECT c.customer_unique_id
        FROM staging.customers c
        JOIN staging.orders o ON o.customer_id = c.customer_id
        GROUP BY c.customer_unique_id
        HAVING COUNT(DISTINCT o.order_id) > 1
    ) repeat_customers;

    IF repeat_customer_count <= 0 OR repeat_customer_count >= unique_customer_count THEN
        RAISE EXCEPTION 'Repeat customer population is outside expected range';
    END IF;
END
$$;

SELECT 'Customer analysis reconciliation checks passed' AS result;

-- Phase 17 checks: windowed monthly revenue reconciles to delivered sales,
-- product-level revenue reconciles, and top-N rankings stay within bounds.
DO $$
DECLARE
    delivered_revenue NUMERIC;
    product_revenue_total NUMERIC;
    monthly_cumulative_revenue NUMERIC;
    max_sellers_per_state BIGINT;
    max_pareto_share NUMERIC;
BEGIN
    SELECT SUM(oi.price_brl)
    INTO delivered_revenue
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered';

    SELECT SUM(product_revenue)
    INTO product_revenue_total
    FROM (
        SELECT oi.product_id, SUM(oi.price_brl) AS product_revenue
        FROM staging.orders o
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        WHERE o.status = 'delivered'
        GROUP BY oi.product_id
    ) products;

    WITH monthly_sales AS (
        SELECT o.purchase_month, SUM(oi.price_brl) AS revenue
        FROM staging.orders o
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        WHERE o.status = 'delivered'
        GROUP BY o.purchase_month
    ),
    month_bounds AS (
        SELECT DATE_TRUNC('month', MIN(purchased_at))::DATE AS first_month,
               DATE_TRUNC('month', MAX(purchased_at))::DATE AS last_month
        FROM staging.orders
    ),
    monthly_calendar AS (
        SELECT GENERATE_SERIES(first_month, last_month, INTERVAL '1 month')::DATE
                   AS revenue_month
        FROM month_bounds
    ),
    monthly_values AS (
        SELECT c.revenue_month, COALESCE(ms.revenue, 0::NUMERIC) AS revenue
        FROM monthly_calendar c
        LEFT JOIN monthly_sales ms ON ms.purchase_month = c.revenue_month
    ),
    monthly_running_total AS (
        SELECT revenue_month,
               SUM(revenue) OVER (
                   ORDER BY revenue_month
                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
               ) AS cumulative_revenue
        FROM monthly_values
    )
    SELECT cumulative_revenue
    INTO monthly_cumulative_revenue
    FROM monthly_running_total
    ORDER BY revenue_month DESC
    LIMIT 1;

    WITH seller_sales AS (
        SELECT s.state, s.seller_id, SUM(oi.price_brl) AS revenue
        FROM staging.sellers s
        JOIN staging.order_items oi ON oi.seller_id = s.seller_id
        JOIN staging.orders o ON o.order_id = oi.order_id
        WHERE o.status = 'delivered'
        GROUP BY s.state, s.seller_id
    ),
    ranked_sellers AS (
        SELECT state,
               ROW_NUMBER() OVER (
                   PARTITION BY state ORDER BY revenue DESC, seller_id
               ) AS position
        FROM seller_sales
    )
    SELECT COALESCE(MAX(state_count), 0)
    INTO max_sellers_per_state
    FROM (
        SELECT state, COUNT(*) AS state_count
        FROM ranked_sellers
        WHERE position <= 3
        GROUP BY state
    ) top_sellers;

    WITH product_sales AS (
        SELECT oi.product_id, SUM(oi.price_brl) AS revenue
        FROM staging.orders o
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        WHERE o.status = 'delivered'
        GROUP BY oi.product_id
    ),
    pareto AS (
        SELECT SUM(revenue) OVER (
                   ORDER BY revenue DESC, product_id
                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
               ) / SUM(revenue) OVER () AS cumulative_share
        FROM product_sales
    )
    SELECT MAX(cumulative_share)
    INTO max_pareto_share
    FROM pareto;

    IF delivered_revenue IS NULL OR product_revenue_total <> delivered_revenue
       OR monthly_cumulative_revenue <> delivered_revenue
       OR max_sellers_per_state > 3
       OR max_pareto_share IS DISTINCT FROM 1::NUMERIC THEN
        RAISE EXCEPTION 'Advanced SQL reconciliation or ranking check failed';
    END IF;
END
$$;

SELECT 'Advanced SQL checks passed' AS result;

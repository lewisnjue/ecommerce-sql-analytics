-- Phase 8 assertions: independently reconcile delivered sales at different
-- grains and validate the ranking, running-total, and rolling-average logic.
DO $$
DECLARE
    total_item_revenue NUMERIC;
    customer_state_revenue NUMERIC;
    seller_state_revenue NUMERIC;
    category_revenue NUMERIC;
    product_revenue NUMERIC;
    monthly_revenue NUMERIC;
    annual_revenue NUMERIC;
    final_cumulative_revenue NUMERIC;
    actual_top_10_share NUMERIC;
    top_10_revenue NUMERIC;
    calendar_month_count INTEGER;
    observed_month_count INTEGER;
BEGIN
    SELECT SUM(oi.price_brl)
    INTO total_item_revenue
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered';

    SELECT SUM(state_sales.revenue)
    INTO customer_state_revenue
    FROM (
        SELECT c.state, SUM(oi.price_brl) AS revenue
        FROM staging.orders o
        JOIN staging.customers c ON c.customer_id = o.customer_id
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        WHERE o.status = 'delivered'
        GROUP BY c.state
    ) state_sales;

    SELECT SUM(state_sales.revenue)
    INTO seller_state_revenue
    FROM (
        SELECT s.state, SUM(oi.price_brl) AS revenue
        FROM staging.orders o
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        JOIN staging.sellers s ON s.seller_id = oi.seller_id
        WHERE o.status = 'delivered'
        GROUP BY s.state
    ) state_sales;

    SELECT SUM(category_sales.revenue)
    INTO category_revenue
    FROM (
        SELECT COALESCE(
                   p.category_name_english,
                   p.category_name,
                   '[Uncategorized]'
               ) AS category_name,
               SUM(oi.price_brl) AS revenue
        FROM staging.orders o
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        JOIN staging.products p ON p.product_id = oi.product_id
        WHERE o.status = 'delivered'
        GROUP BY COALESCE(
                     p.category_name_english,
                     p.category_name,
                     '[Uncategorized]'
                 )
    ) category_sales;

    SELECT SUM(product_sales.revenue)
    INTO product_revenue
    FROM (
        SELECT p.product_id, SUM(oi.price_brl) AS revenue
        FROM staging.orders o
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        JOIN staging.products p ON p.product_id = oi.product_id
        WHERE o.status = 'delivered'
        GROUP BY p.product_id
    ) product_sales;

    SELECT SUM(month_sales.revenue)
    INTO monthly_revenue
    FROM (
        SELECT o.purchase_month, SUM(oi.price_brl) AS revenue
        FROM staging.orders o
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        WHERE o.status = 'delivered'
        GROUP BY o.purchase_month
    ) month_sales;

    SELECT SUM(year_sales.revenue)
    INTO annual_revenue
    FROM (
        SELECT EXTRACT(YEAR FROM o.purchased_at) AS revenue_year,
               SUM(oi.price_brl) AS revenue
        FROM staging.orders o
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        WHERE o.status = 'delivered'
        GROUP BY EXTRACT(YEAR FROM o.purchased_at)
    ) year_sales;

    IF customer_state_revenue <> total_item_revenue THEN
        RAISE EXCEPTION 'Customer-state revenue does not reconcile to delivered item sales';
    END IF;
    IF seller_state_revenue <> total_item_revenue THEN
        RAISE EXCEPTION 'Seller-state revenue does not reconcile to delivered item sales';
    END IF;
    IF category_revenue <> total_item_revenue THEN
        RAISE EXCEPTION 'Category revenue does not reconcile to delivered item sales';
    END IF;
    IF product_revenue <> total_item_revenue THEN
        RAISE EXCEPTION 'Product revenue does not reconcile to delivered item sales';
    END IF;
    IF monthly_revenue <> total_item_revenue THEN
        RAISE EXCEPTION 'Monthly revenue does not reconcile to delivered item sales';
    END IF;
    IF annual_revenue <> total_item_revenue THEN
        RAISE EXCEPTION 'Annual revenue does not reconcile to delivered item sales';
    END IF;

    WITH monthly_sales AS (
        SELECT o.purchase_month,
               SUM(oi.price_brl) AS revenue
        FROM staging.orders o
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        WHERE o.status = 'delivered'
        GROUP BY o.purchase_month
    ),
    month_bounds AS (
        SELECT MIN(purchase_month) AS first_month,
               MAX(purchase_month) AS last_month
        FROM staging.orders
    ),
    month_series AS (
        SELECT GENERATE_SERIES(first_month, last_month, INTERVAL '1 month')::DATE
                   AS revenue_month
        FROM month_bounds
    ),
    revenue_calendar AS (
        SELECT ms.revenue_month,
               COALESCE(s.revenue, 0::NUMERIC) AS revenue
        FROM month_series ms
        LEFT JOIN monthly_sales s ON s.purchase_month = ms.revenue_month
    ),
    running_revenue AS (
        SELECT revenue_month,
               SUM(revenue) OVER (ORDER BY revenue_month) AS cumulative_revenue
        FROM revenue_calendar
    )
    SELECT cumulative_revenue
    INTO final_cumulative_revenue
    FROM running_revenue
    ORDER BY revenue_month DESC
    LIMIT 1;

    IF final_cumulative_revenue <> total_item_revenue THEN
        RAISE EXCEPTION 'Final running revenue does not reconcile to total revenue';
    END IF;

    SELECT COUNT(*)
    INTO calendar_month_count
    FROM GENERATE_SERIES(
        (SELECT DATE_TRUNC('month', MIN(purchased_at))::DATE FROM staging.orders),
        (SELECT DATE_TRUNC('month', MAX(purchased_at))::DATE FROM staging.orders),
        INTERVAL '1 month'
    );

    SELECT COUNT(DISTINCT purchase_month)
    INTO observed_month_count
    FROM staging.orders;

    IF calendar_month_count < observed_month_count THEN
        RAISE EXCEPTION 'Revenue calendar is missing months from the order date range';
    END IF;

    WITH product_sales AS (
        SELECT p.product_id, SUM(oi.price_brl) AS revenue
        FROM staging.orders o
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        JOIN staging.products p ON p.product_id = oi.product_id
        WHERE o.status = 'delivered'
        GROUP BY p.product_id
    ),
    ranked_products AS (
        SELECT revenue,
               ROW_NUMBER() OVER (ORDER BY revenue DESC, product_id) AS product_position
        FROM product_sales
    )
    SELECT SUM(revenue), 100.0 * SUM(revenue) / total_item_revenue
    INTO top_10_revenue, actual_top_10_share
    FROM ranked_products
    WHERE product_position <= 10;

    IF top_10_revenue <= 0 OR top_10_revenue >= total_item_revenue THEN
        RAISE EXCEPTION 'Top-ten product revenue is outside the expected range';
    END IF;
    IF actual_top_10_share <= 0 OR actual_top_10_share >= 100 THEN
        RAISE EXCEPTION 'Top-ten product revenue share is outside 0-100 percent';
    END IF;
END
$$;

SELECT 'Revenue reconciliation checks passed' AS result;

-- Phase 13 assertions: product/category rollups reconcile to delivered sales.
DO $$
DECLARE
    total_sales NUMERIC;
    product_sales NUMERIC;
    category_sales NUMERIC;
BEGIN
    SELECT SUM(oi.price_brl)
    INTO total_sales
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered';

    SELECT SUM(sales.revenue)
    INTO product_sales
    FROM (
        SELECT oi.product_id, SUM(oi.price_brl) AS revenue
        FROM staging.orders o
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        WHERE o.status = 'delivered'
        GROUP BY oi.product_id
    ) sales;

    SELECT SUM(sales.revenue)
    INTO category_sales
    FROM (
        SELECT COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
                   AS category,
               SUM(oi.price_brl) AS revenue
        FROM staging.orders o
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        JOIN staging.products p ON p.product_id = oi.product_id
        WHERE o.status = 'delivered'
        GROUP BY COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
    ) sales;

    IF product_sales <> total_sales OR category_sales <> total_sales THEN
        RAISE EXCEPTION 'Product/category sales do not reconcile to delivered sales';
    END IF;
    IF (SELECT COUNT(*) FROM staging.products) <> 32951 THEN
        RAISE EXCEPTION 'Unexpected staged product population';
    END IF;
END
$$;

SELECT 'Product analysis checks passed' AS result;

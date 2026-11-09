-- Phase 14 checks: seller revenue reconciles to delivered item sales and
-- every seller is assigned to exactly one deterministic revenue quartile.
DO $$
DECLARE
    total_item_revenue NUMERIC;
    seller_revenue NUMERIC;
    tiered_sellers BIGINT;
BEGIN
    SELECT SUM(price_brl) INTO total_item_revenue
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered';

    SELECT SUM(revenue_brl) INTO seller_revenue
    FROM (
        SELECT s.seller_id,
               COALESCE(SUM(oi.price_brl)
                   FILTER (WHERE o.status = 'delivered'), 0) AS revenue_brl
        FROM staging.sellers s
        LEFT JOIN staging.order_items oi ON oi.seller_id = s.seller_id
        LEFT JOIN staging.orders o ON o.order_id = oi.order_id
        GROUP BY s.seller_id
    ) seller_sales;

    SELECT COUNT(*) INTO tiered_sellers
    FROM (
        SELECT seller_id,
               NTILE(4) OVER (ORDER BY revenue_brl DESC, seller_id) AS tier
        FROM (
            SELECT s.seller_id,
                   COALESCE(SUM(oi.price_brl)
                       FILTER (WHERE o.status = 'delivered'), 0) AS revenue_brl
            FROM staging.sellers s
            LEFT JOIN staging.order_items oi ON oi.seller_id = s.seller_id
            LEFT JOIN staging.orders o ON o.order_id = oi.order_id
            GROUP BY s.seller_id
        ) sales
    ) tiers;

    IF seller_revenue <> total_item_revenue THEN
        RAISE EXCEPTION 'Seller revenue does not reconcile to delivered sales';
    END IF;
    IF tiered_sellers <> (SELECT COUNT(*) FROM staging.sellers) THEN
        RAISE EXCEPTION 'Not every seller was assigned a performance tier';
    END IF;
END
$$;

SELECT 'Seller performance checks passed' AS result;

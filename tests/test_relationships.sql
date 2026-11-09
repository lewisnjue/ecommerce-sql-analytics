-- Phase 20 checks: staged primary/composite keys are unique and all expected
-- relationships resolve to their parent rows.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM staging.customers GROUP BY customer_id HAVING COUNT(*) > 1
    ) OR EXISTS (
        SELECT 1 FROM staging.products GROUP BY product_id HAVING COUNT(*) > 1
    ) OR EXISTS (
        SELECT 1 FROM staging.sellers GROUP BY seller_id HAVING COUNT(*) > 1
    ) OR EXISTS (
        SELECT 1 FROM staging.orders GROUP BY order_id HAVING COUNT(*) > 1
    ) OR EXISTS (
        SELECT 1 FROM staging.order_items
        GROUP BY order_id, order_item_id HAVING COUNT(*) > 1
    ) OR EXISTS (
        SELECT 1 FROM staging.order_payments
        GROUP BY order_id, payment_sequential HAVING COUNT(*) > 1
    ) OR EXISTS (
        SELECT 1 FROM staging.order_reviews
        GROUP BY review_id, order_id HAVING COUNT(*) > 1
    ) OR EXISTS (
        SELECT 1 FROM staging.product_category_translations
        GROUP BY category_name HAVING COUNT(*) > 1
    ) OR EXISTS (
        SELECT 1 FROM staging.geolocation
        GROUP BY source_geolocation_id HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'A staged primary or composite key is not unique';
    END IF;

    IF EXISTS (
        SELECT 1 FROM staging.orders o
        LEFT JOIN staging.customers c ON c.customer_id = o.customer_id
        WHERE c.customer_id IS NULL
    ) OR EXISTS (
        SELECT 1 FROM staging.order_items oi
        LEFT JOIN staging.orders o ON o.order_id = oi.order_id
        WHERE o.order_id IS NULL
    ) OR EXISTS (
        SELECT 1 FROM staging.order_items oi
        LEFT JOIN staging.products p ON p.product_id = oi.product_id
        WHERE p.product_id IS NULL
    ) OR EXISTS (
        SELECT 1 FROM staging.order_items oi
        LEFT JOIN staging.sellers s ON s.seller_id = oi.seller_id
        WHERE s.seller_id IS NULL
    ) OR EXISTS (
        SELECT 1 FROM staging.order_payments op
        LEFT JOIN staging.orders o ON o.order_id = op.order_id
        WHERE o.order_id IS NULL
    ) OR EXISTS (
        SELECT 1 FROM staging.order_reviews r
        LEFT JOIN staging.orders o ON o.order_id = r.order_id
        WHERE o.order_id IS NULL
    ) THEN
        RAISE EXCEPTION 'A staged foreign-key relationship is unresolved';
    END IF;
END
$$;

SELECT 'Primary-key and relationship checks passed' AS result;

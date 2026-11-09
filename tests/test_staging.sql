-- Phase 6 validation: compare staged row counts with their raw sources and
-- assert that key investigated data-quality issues remain visible in staging.
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM staging.customers)
       <> (SELECT COUNT(*) FROM public.customers) THEN
        RAISE EXCEPTION 'Staging customer count does not match raw customer count';
    END IF;
    IF (SELECT COUNT(*) FROM staging.product_category_translations)
       <> (SELECT COUNT(*) FROM public.product_category_name_translation) THEN
        RAISE EXCEPTION 'Staging category translation count does not match raw count';
    END IF;
    IF (SELECT COUNT(*) FROM staging.sellers)
       <> (SELECT COUNT(*) FROM public.sellers) THEN
        RAISE EXCEPTION 'Staging seller count does not match raw seller count';
    END IF;
    IF (SELECT COUNT(*) FROM staging.geolocation)
       <> (SELECT COUNT(*) FROM public.geolocation) THEN
        RAISE EXCEPTION 'Staging geolocation count does not match raw count';
    END IF;
    IF (SELECT COUNT(*) FROM staging.products)
       <> (SELECT COUNT(*) FROM public.products) THEN
        RAISE EXCEPTION 'Staging product count does not match raw product count';
    END IF;
    IF (SELECT COUNT(*) FROM staging.orders)
       <> (SELECT COUNT(*) FROM public.orders) THEN
        RAISE EXCEPTION 'Staging order count does not match raw order count';
    END IF;
    IF (SELECT COUNT(*) FROM staging.order_items)
       <> (SELECT COUNT(*) FROM public.order_items) THEN
        RAISE EXCEPTION 'Staging order item count does not match raw count';
    END IF;
    IF (SELECT COUNT(*) FROM staging.order_payments)
       <> (SELECT COUNT(*) FROM public.order_payments) THEN
        RAISE EXCEPTION 'Staging payment count does not match raw count';
    END IF;
    IF (SELECT COUNT(*) FROM staging.order_reviews)
       <> (SELECT COUNT(*) FROM public.order_reviews) THEN
        RAISE EXCEPTION 'Staging review count does not match raw review count';
    END IF;

    IF (SELECT COUNT(*) FROM staging.products WHERE category_name IS NOT NULL
        AND category_name_english IS NULL) <> 13 THEN
        RAISE EXCEPTION 'Expected 13 untranslated product rows to remain visible';
    END IF;
    IF (SELECT COUNT(*) FROM staging.orders
        WHERE carrier_before_approval) <> 1359 THEN
        RAISE EXCEPTION 'Carrier-before-approval anomaly count changed in staging';
    END IF;
    IF (SELECT COUNT(*) FROM staging.orders
        WHERE delivery_before_carrier) <> 23 THEN
        RAISE EXCEPTION 'Delivery-before-carrier anomaly count changed in staging';
    END IF;
    IF (SELECT COUNT(*) FROM staging.orders
        WHERE carrier_before_purchase) <> 166 THEN
        RAISE EXCEPTION 'Carrier-before-purchase anomaly count changed in staging';
    END IF;
    IF (SELECT COUNT(*) FROM staging.orders
        WHERE delivered_status_missing_delivery) <> 8 THEN
        RAISE EXCEPTION 'Delivered-order missing-date anomaly count changed in staging';
    END IF;
    IF (SELECT COUNT(*) FROM staging.orders
        WHERE non_delivered_status_has_delivery) <> 6 THEN
        RAISE EXCEPTION 'Non-delivered-order date anomaly count changed in staging';
    END IF;
    IF (SELECT COUNT(*) FROM staging.order_payments
        WHERE has_invalid_installments) <> 2 THEN
        RAISE EXCEPTION 'Invalid installment rows were not preserved in staging';
    END IF;
    IF (SELECT COUNT(*) FROM staging.order_reviews
        WHERE created_before_purchase) <> 74 THEN
        RAISE EXCEPTION 'Review chronology anomaly count changed in staging';
    END IF;
    IF (SELECT COUNT(*) FROM staging.order_reviews
        WHERE comment_title IS NULL) <> 87658 THEN
        RAISE EXCEPTION 'Blank review titles were not normalized to NULL';
    END IF;
    IF (SELECT COUNT(*) FROM staging.order_reviews
        WHERE comment_message IS NULL) <> 58256 THEN
        RAISE EXCEPTION 'Blank review messages were not normalized to NULL';
    END IF;
END
$$;

SELECT 'customers' AS entity, COUNT(*) AS staged_rows FROM staging.customers
UNION ALL
SELECT 'product_category_translations', COUNT(*) FROM staging.product_category_translations
UNION ALL
SELECT 'sellers', COUNT(*) FROM staging.sellers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM staging.geolocation
UNION ALL
SELECT 'products', COUNT(*) FROM staging.products
UNION ALL
SELECT 'orders', COUNT(*) FROM staging.orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM staging.order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM staging.order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM staging.order_reviews
ORDER BY entity;

SELECT
    (SELECT COUNT(*) FROM staging.orders WHERE carrier_before_approval)
        AS carrier_before_approval,
    (SELECT COUNT(*) FROM staging.orders WHERE carrier_before_purchase)
        AS carrier_before_purchase,
    (SELECT COUNT(*) FROM staging.orders WHERE delivery_before_carrier)
        AS delivery_before_carrier,
    (SELECT COUNT(*) FROM staging.orders
     WHERE delivered_status_missing_delivery)
        AS delivered_without_delivery_timestamp,
    (SELECT COUNT(*) FROM staging.orders
     WHERE non_delivered_status_has_delivery)
        AS non_delivered_with_delivery_timestamp,
    (SELECT COUNT(*) FROM staging.order_reviews WHERE created_before_purchase)
        AS reviews_before_purchase,
    (SELECT COUNT(*) FROM staging.products
     WHERE category_name IS NOT NULL AND category_name_english IS NULL)
        AS untranslated_products,
    (SELECT COUNT(*) FROM staging.order_payments WHERE has_invalid_installments)
        AS invalid_installment_rows;

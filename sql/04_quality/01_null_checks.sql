-- Phase 5: profile nullable fields before deciding whether missing values need action.
WITH null_profile AS (
    SELECT 'orders.order_approved_at' AS column_name, COUNT(*) AS total_rows,
           COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS null_rows
    FROM orders
    UNION ALL
    SELECT 'orders.order_delivered_carrier_date', COUNT(*),
           COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL)
    FROM orders
    UNION ALL
    SELECT 'orders.order_delivered_customer_date', COUNT(*),
           COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL)
    FROM orders
    UNION ALL
    SELECT 'products.product_category_name', COUNT(*),
           COUNT(*) FILTER (WHERE product_category_name IS NULL)
    FROM products
    UNION ALL
    SELECT 'products.product_name_lenght', COUNT(*),
           COUNT(*) FILTER (WHERE product_name_lenght IS NULL)
    FROM products
    UNION ALL
    SELECT 'products.product_description_lenght', COUNT(*),
           COUNT(*) FILTER (WHERE product_description_lenght IS NULL)
    FROM products
    UNION ALL
    SELECT 'products.product_photos_qty', COUNT(*),
           COUNT(*) FILTER (WHERE product_photos_qty IS NULL)
    FROM products
    UNION ALL
    SELECT 'products.product_weight_g', COUNT(*),
           COUNT(*) FILTER (WHERE product_weight_g IS NULL)
    FROM products
    UNION ALL
    SELECT 'products.product_length_cm', COUNT(*),
           COUNT(*) FILTER (WHERE product_length_cm IS NULL)
    FROM products
    UNION ALL
    SELECT 'products.product_height_cm', COUNT(*),
           COUNT(*) FILTER (WHERE product_height_cm IS NULL)
    FROM products
    UNION ALL
    SELECT 'products.product_width_cm', COUNT(*),
           COUNT(*) FILTER (WHERE product_width_cm IS NULL)
    FROM products
    UNION ALL
    SELECT 'order_reviews.review_comment_title', COUNT(*),
           COUNT(*) FILTER (WHERE review_comment_title IS NULL)
    FROM order_reviews
    UNION ALL
    SELECT 'order_reviews.review_comment_message', COUNT(*),
           COUNT(*) FILTER (WHERE review_comment_message IS NULL)
    FROM order_reviews
)
SELECT column_name,
       total_rows,
       null_rows,
       ROUND(100.0 * null_rows / NULLIF(total_rows, 0), 2) AS null_pct
FROM null_profile
ORDER BY null_rows DESC, column_name;

-- Blank review text is distinct from SQL NULL; profile it separately.
SELECT
    COUNT(*) FILTER (WHERE review_comment_title IS NOT NULL
                     AND BTRIM(review_comment_title) = '') AS blank_titles,
    COUNT(*) FILTER (WHERE review_comment_message IS NOT NULL
                     AND BTRIM(review_comment_message) = '') AS blank_messages
FROM order_reviews;

-- Product attributes are missing in groups, so count fully incomplete profiles.
SELECT
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
          AND product_name_lenght IS NULL
          AND product_description_lenght IS NULL
          AND product_photos_qty IS NULL
    ) AS products_missing_category_and_descriptive_attributes,
    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
          AND product_length_cm IS NULL
          AND product_height_cm IS NULL
          AND product_width_cm IS NULL
    ) AS products_missing_all_shipping_dimensions
FROM products;

-- Missing milestone dates have different meanings depending on order status.
SELECT order_status,
       COUNT(*) AS status_rows,
       COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS missing_approval,
       COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS missing_carrier_handoff,
       COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS missing_customer_delivery
FROM orders
GROUP BY order_status
ORDER BY order_status;

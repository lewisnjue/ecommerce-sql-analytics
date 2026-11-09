-- Phase 5: independently check each declared foreign-key relationship and
-- the product-to-category translation relationship, which has no FK constraint.
SELECT 'orders.customer_id -> customers.customer_id' AS relationship,
       COUNT(*) AS orphan_rows
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'order_items.order_id -> orders.order_id', COUNT(*)
FROM order_items oi
LEFT JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'order_items.product_id -> products.product_id', COUNT(*)
FROM order_items oi
LEFT JOIN products p ON p.product_id = oi.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'order_items.seller_id -> sellers.seller_id', COUNT(*)
FROM order_items oi
LEFT JOIN sellers s ON s.seller_id = oi.seller_id
WHERE s.seller_id IS NULL
UNION ALL
SELECT 'order_payments.order_id -> orders.order_id', COUNT(*)
FROM order_payments op
LEFT JOIN orders o ON o.order_id = op.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'order_reviews.order_id -> orders.order_id', COUNT(*)
FROM order_reviews r
LEFT JOIN orders o ON o.order_id = r.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'products.product_category_name -> category translation', COUNT(*)
FROM products p
LEFT JOIN product_category_name_translation t
    ON t.product_category_name = p.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
ORDER BY relationship;

SELECT p.product_category_name, COUNT(*) AS affected_products
FROM products p
LEFT JOIN product_category_name_translation t
    ON t.product_category_name = p.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY affected_products DESC, p.product_category_name;

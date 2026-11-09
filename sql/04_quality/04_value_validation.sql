-- Phase 5: inspect values that are structurally valid but may be implausible.
-- Zero-value transactions and dimensions are reported separately from negatives.
SELECT 'order_items.price < 0' AS check_name, COUNT(*) AS affected_rows
FROM order_items WHERE price < 0
UNION ALL
SELECT 'order_items.price = 0', COUNT(*) FROM order_items WHERE price = 0
UNION ALL
SELECT 'order_items.freight_value < 0', COUNT(*) FROM order_items WHERE freight_value < 0
UNION ALL
SELECT 'order_items.freight_value = 0', COUNT(*) FROM order_items WHERE freight_value = 0
UNION ALL
SELECT 'order_payments.payment_value < 0', COUNT(*)
FROM order_payments WHERE payment_value < 0
UNION ALL
SELECT 'order_payments.payment_value = 0', COUNT(*)
FROM order_payments WHERE payment_value = 0
UNION ALL
SELECT 'order_payments.payment_installments < 1', COUNT(*)
FROM order_payments WHERE payment_installments < 1
UNION ALL
SELECT 'order_items.order_item_id < 1', COUNT(*)
FROM order_items WHERE order_item_id < 1
UNION ALL
SELECT 'order_payments.payment_sequential < 1', COUNT(*)
FROM order_payments WHERE payment_sequential < 1
UNION ALL
SELECT 'products.product_photos_qty < 0', COUNT(*)
FROM products WHERE product_photos_qty < 0
UNION ALL
SELECT 'products.product_weight_g < 0', COUNT(*)
FROM products WHERE product_weight_g < 0
UNION ALL
SELECT 'products.nonpositive dimensions', COUNT(*)
FROM products
WHERE product_length_cm <= 0 OR product_height_cm <= 0 OR product_width_cm <= 0
UNION ALL
SELECT 'order_reviews.review_score outside 1..5', COUNT(*)
FROM order_reviews WHERE review_score NOT BETWEEN 1 AND 5
UNION ALL
SELECT 'geolocation latitude outside -90..90', COUNT(*)
FROM geolocation WHERE geolocation_lat NOT BETWEEN -90 AND 90
UNION ALL
SELECT 'geolocation longitude outside -180..180', COUNT(*)
FROM geolocation WHERE geolocation_lng NOT BETWEEN -180 AND 180
UNION ALL
SELECT 'customer ZIP prefix not five digits', COUNT(*)
FROM customers WHERE BTRIM(customer_zip_code_prefix) !~ '^[0-9]{5}$'
UNION ALL
SELECT 'seller ZIP prefix not five digits', COUNT(*)
FROM sellers WHERE BTRIM(seller_zip_code_prefix) !~ '^[0-9]{5}$'
UNION ALL
SELECT 'geolocation ZIP prefix not five digits', COUNT(*)
FROM geolocation WHERE BTRIM(geolocation_zip_code_prefix) !~ '^[0-9]{5}$'
UNION ALL
SELECT 'customers with blank city/state', COUNT(*)
FROM customers WHERE BTRIM(customer_city) = '' OR BTRIM(customer_state) = ''
UNION ALL
SELECT 'sellers with blank city/state', COUNT(*)
FROM sellers WHERE BTRIM(seller_city) = '' OR BTRIM(seller_state) = ''
UNION ALL
SELECT 'geolocation with blank city/state', COUNT(*)
FROM geolocation WHERE BTRIM(geolocation_city) = '' OR BTRIM(geolocation_state) = ''
UNION ALL
SELECT 'customer state not a Brazilian UF', COUNT(*)
FROM customers
WHERE BTRIM(customer_state) NOT IN (
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
    'SP', 'SE', 'TO'
)
UNION ALL
SELECT 'seller state not a Brazilian UF', COUNT(*)
FROM sellers
WHERE BTRIM(seller_state) NOT IN (
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
    'SP', 'SE', 'TO'
)
UNION ALL
SELECT 'geolocation state not a Brazilian UF', COUNT(*)
FROM geolocation
WHERE BTRIM(geolocation_state) NOT IN (
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
    'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
    'SP', 'SE', 'TO'
)
ORDER BY check_name;

-- Return a few examples when zero/negative monetary values need interpretation.
SELECT 'order_items.price = 0' AS check_name, order_id, order_item_id,
       price::TEXT AS observed_value
FROM order_items
WHERE price = 0
ORDER BY order_id, order_item_id
LIMIT 10;

SELECT 'order_payments.payment_value = 0' AS check_name, order_id,
       payment_sequential AS row_sequence, payment_type, payment_installments,
       payment_value::TEXT AS observed_value
FROM order_payments
WHERE payment_value = 0
ORDER BY order_id, payment_sequential
LIMIT 10;

SELECT 'order_payments.payment_installments = 0' AS check_name, order_id,
       payment_sequential AS row_sequence, payment_type, payment_value::TEXT AS observed_value,
       payment_installments::TEXT AS observed_installments
FROM order_payments
WHERE payment_installments = 0
ORDER BY order_id, payment_sequential
LIMIT 10;

SELECT 'order_items.freight_value = 0' AS check_name, order_id, order_item_id,
       price::TEXT AS item_price, freight_value::TEXT AS freight_value
FROM order_items
WHERE freight_value = 0
ORDER BY order_id, order_item_id
LIMIT 10;

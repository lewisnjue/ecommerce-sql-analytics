-- Identify:
-- Missing values
-- Columns with unusually high NULL rates
-- Whether NULLs have business meaning

-- CUSTOMERS 

SELECT * FROM customers WHERE NOT (customer IS NOT NULL);
:::RESULTS:::

```
 customer_id | customer_unique_id | customer_zip_code_prefix | customer_city | customer_state
-------------+--------------------+--------------------------+---------------+----------------
(0 rows)

(END)
```
SELECT *  FROM geolocation WHERE NOT ( geolocation IS NOT NULL);
```
olist=#
 id | geolocation_zip_code_prefix | geolocation_lat | geolocation_lng | geolocation_city | geolocation_state
----+-----------------------------+-----------------+-----------------+------------------+-------------------
(0 rows)
```

SELECT * FROM order_items WHERE NOT ( order_items IS NOT NULL);

```
 order_id | order_item_id | product_id | seller_id | shipping_limit_date | price | freight_value
----------+---------------+------------+-----------+---------------------+-------+---------------
(0 rows)

(END)
```

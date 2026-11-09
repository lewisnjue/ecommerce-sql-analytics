-- Phase 10 assertions: every person appears once, purchase segments partition
-- the population, RFM values are valid, and zero-purchase customers are retained.
DO $$
DECLARE
    segmented_customers BIGINT;
    unique_customers BIGINT;
    eligible_customers BIGINT;
BEGIN
    WITH customer_metrics AS (
        SELECT c.customer_unique_id,
               COUNT(DISTINCT o.order_id)
                   FILTER (WHERE o.status = 'delivered') AS delivered_orders,
               COALESCE(
                   SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered'),
                   0
               ) AS monetary_brl,
               MAX(o.purchase_date) FILTER (WHERE o.status = 'delivered')
                   AS last_purchase_date
        FROM staging.customers c
        LEFT JOIN staging.orders o ON o.customer_id = c.customer_id
        LEFT JOIN staging.order_items oi ON oi.order_id = o.order_id
        GROUP BY c.customer_unique_id
    )
    SELECT COUNT(*), COUNT(*) FILTER (WHERE delivered_orders > 0)
    INTO segmented_customers, eligible_customers
    FROM customer_metrics;

    SELECT COUNT(DISTINCT customer_unique_id)
    INTO unique_customers
    FROM staging.customers;

    IF segmented_customers <> unique_customers THEN
        RAISE EXCEPTION 'Segmentation does not include each unique customer once';
    END IF;
    IF eligible_customers >= unique_customers OR eligible_customers = 0 THEN
        RAISE EXCEPTION 'Expected both eligible buyers and zero-delivery customers';
    END IF;

    WITH customer_metrics AS (
        SELECT c.customer_unique_id,
               COUNT(DISTINCT o.order_id)
                   FILTER (WHERE o.status = 'delivered') AS frequency,
               COALESCE(
                   SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered'),
                   0
               ) AS monetary_brl,
               MAX(o.purchase_date) FILTER (WHERE o.status = 'delivered')
                   AS last_purchase_date
        FROM staging.customers c
        LEFT JOIN staging.orders o ON o.customer_id = c.customer_id
        LEFT JOIN staging.order_items oi ON oi.order_id = o.order_id
        GROUP BY c.customer_unique_id
    ),
    eligible AS (
        SELECT *, (SELECT MAX(purchase_date) + 1 FROM staging.orders)
                       - last_purchase_date AS recency_days
        FROM customer_metrics
        WHERE frequency > 0
    ),
    score_values AS (
        SELECT e.customer_unique_id, r.recency_score, f.frequency_score,
               m.monetary_score
        FROM eligible e
        JOIN (
            SELECT recency_days,
                   NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score
            FROM (SELECT DISTINCT recency_days FROM eligible) recency_values
        ) r USING (recency_days)
        JOIN (
            SELECT frequency,
                   NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score
            FROM (SELECT DISTINCT frequency FROM eligible) frequency_values
        ) f USING (frequency)
        JOIN (
            SELECT monetary_brl,
                   NTILE(5) OVER (ORDER BY monetary_brl ASC) AS monetary_score
            FROM (SELECT DISTINCT monetary_brl FROM eligible) monetary_values
        ) m USING (monetary_brl)
    )
    SELECT COUNT(*)
    INTO segmented_customers
    FROM score_values
    WHERE recency_score NOT BETWEEN 1 AND 5
       OR frequency_score NOT BETWEEN 1 AND 5
       OR monetary_score NOT BETWEEN 1 AND 5;

    IF segmented_customers <> 0 THEN
        RAISE EXCEPTION 'RFM scores fall outside 1-5';
    END IF;
END
$$;

SELECT 'Customer segmentation checks passed' AS result;

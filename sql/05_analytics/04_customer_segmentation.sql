-- Phase 10: customer value tiers and tie-aware RFM segmentation.
-- RFM is based on delivered orders only. Reference date is one day after the
-- latest order purchase date in the dataset, not the current system date.
-- Run: docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/05_analytics/04_customer_segmentation.sql

WITH customer_metrics AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) FILTER (WHERE o.status = 'delivered')
               AS frequency,
           COALESCE(
               SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered'),
               0
           ) AS monetary_brl,
           MAX(o.purchase_date) FILTER (WHERE o.status = 'delivered')
               AS last_purchase_date,
           (SELECT MAX(purchase_date) + 1 FROM staging.orders)
               AS reference_date
    FROM staging.customers c
    LEFT JOIN staging.orders o ON o.customer_id = c.customer_id
    LEFT JOIN staging.order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_unique_id
),
customer_base AS (
    SELECT *,
           CASE WHEN last_purchase_date IS NOT NULL
                THEN reference_date - last_purchase_date
           END AS recency_days,
           CASE
               WHEN frequency = 0 THEN 'No delivered purchase'
               WHEN frequency = 1 THEN 'One-time'
               ELSE 'Repeat'
           END AS purchase_segment
    FROM customer_metrics
),
eligible_customers AS (
    SELECT * FROM customer_base WHERE frequency > 0
),
recency_values AS (
    SELECT DISTINCT recency_days
    FROM eligible_customers
),
recency_scores AS (
    SELECT recency_days,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score
    FROM recency_values
),
frequency_values AS (
    SELECT DISTINCT frequency
    FROM eligible_customers
),
frequency_scores AS (
    SELECT frequency,
           NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score
    FROM frequency_values
),
monetary_values AS (
    SELECT DISTINCT monetary_brl
    FROM eligible_customers
),
monetary_scores AS (
    SELECT monetary_brl,
           NTILE(5) OVER (ORDER BY monetary_brl ASC) AS monetary_score
    FROM monetary_values
),
rfm_customers AS (
    SELECT c.customer_unique_id, c.frequency, c.monetary_brl, c.recency_days,
           r.recency_score, f.frequency_score, m.monetary_score,
           CASE
               WHEN r.recency_score >= 4
                AND f.frequency_score >= 4
                AND m.monetary_score >= 4 THEN 'Champions'
               WHEN r.recency_score >= 3
                AND f.frequency_score >= 4 THEN 'Loyal Customers'
               WHEN r.recency_score >= 4
                AND f.frequency_score >= 2 THEN 'Potential Loyalists'
               WHEN r.recency_score <= 2
                AND f.frequency_score >= 3 THEN 'At Risk'
               WHEN r.recency_score <= 2
                AND f.frequency_score <= 2 THEN 'Hibernating'
               WHEN r.recency_score >= 4
                AND f.frequency_score = 1 THEN 'Recent One-time'
               ELSE 'Needs Attention'
           END AS rfm_segment
    FROM eligible_customers c
    JOIN recency_scores r USING (recency_days)
    JOIN frequency_scores f USING (frequency)
    JOIN monetary_scores m USING (monetary_brl)
)
SELECT rfm_segment,
       COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_buyers,
       ROUND(AVG(recency_days), 1) AS average_recency_days,
       ROUND(AVG(frequency), 2) AS average_delivered_orders,
       ROUND(AVG(monetary_brl), 2) AS average_delivered_spend_brl,
       ROUND(AVG(recency_score), 2) AS average_recency_score,
       ROUND(AVG(frequency_score), 2) AS average_frequency_score,
       ROUND(AVG(monetary_score), 2) AS average_monetary_score
FROM rfm_customers
GROUP BY rfm_segment
ORDER BY customers DESC, rfm_segment;

-- One-time/repeat/high-value/low-value distribution. Value tiers are based
-- on tie-preserving quintiles of distinct delivered-spend values among buyers.
WITH customer_metrics AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) FILTER (WHERE o.status = 'delivered')
               AS delivered_orders,
           COALESCE(
               SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered'),
               0
           ) AS delivered_spend_brl
    FROM staging.customers c
    LEFT JOIN staging.orders o ON o.customer_id = c.customer_id
    LEFT JOIN staging.order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_unique_id
),
spend_values AS (
    SELECT DISTINCT delivered_spend_brl
    FROM customer_metrics
    WHERE delivered_orders > 0
),
value_tiers AS (
    SELECT delivered_spend_brl,
           NTILE(5) OVER (ORDER BY delivered_spend_brl DESC) AS value_quintile
    FROM spend_values
)
SELECT CASE
           WHEN c.delivered_orders = 0 THEN 'No delivered purchase'
           WHEN c.delivered_orders = 1 THEN 'One-time'
           ELSE 'Repeat'
       END AS purchase_segment,
       CASE
           WHEN c.delivered_orders = 0 THEN 'No delivered spend'
           WHEN v.value_quintile = 1 THEN 'High value'
           WHEN v.value_quintile = 5 THEN 'Low value'
           ELSE 'Mid value'
       END AS value_segment,
       COUNT(*) AS customers,
       ROUND(AVG(c.delivered_spend_brl), 2) AS average_delivered_spend_brl
FROM customer_metrics c
LEFT JOIN value_tiers v USING (delivered_spend_brl)
GROUP BY purchase_segment, value_segment
ORDER BY purchase_segment, value_segment;

-- Inspect each metric's score boundaries and the reference date.
WITH customer_metrics AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) FILTER (WHERE o.status = 'delivered')
               AS frequency,
           COALESCE(SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered'), 0)
               AS monetary_brl,
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
scored AS (
    SELECT e.customer_unique_id, e.recency_days, e.frequency, e.monetary_brl,
           r.recency_score, f.frequency_score, m.monetary_score
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
SELECT customer_unique_id, recency_days, frequency, monetary_brl,
       recency_score, frequency_score, monetary_score
FROM scored
ORDER BY recency_score DESC, frequency_score DESC, monetary_score DESC,
         monetary_brl DESC, customer_unique_id
LIMIT 20;

-- Phase 18: reusable reporting views over the standardized staging layer.
CREATE SCHEMA IF NOT EXISTS analytics;

CREATE OR REPLACE VIEW analytics.customer_summary AS
WITH order_values AS (
    SELECT c.customer_unique_id, o.order_id, o.status, o.purchase_date,
           SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered')
               AS delivered_revenue_brl
    FROM staging.customers c
    JOIN staging.orders o ON o.customer_id = c.customer_id
    LEFT JOIN staging.order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_unique_id, o.order_id, o.status, o.purchase_date
)
SELECT c.customer_unique_id,
       COUNT(ov.order_id) AS total_orders,
       COUNT(ov.order_id) FILTER (WHERE ov.status = 'delivered')
           AS delivered_orders,
       COUNT(ov.order_id) FILTER (WHERE ov.status = 'canceled')
           AS canceled_orders,
       COALESCE(SUM(ov.delivered_revenue_brl), 0::NUMERIC)
           AS delivered_revenue_brl,
       ROUND(AVG(ov.delivered_revenue_brl)
             FILTER (WHERE ov.status = 'delivered'), 2)
           AS average_delivered_order_value_brl,
       MIN(ov.purchase_date) AS first_order_date,
       MAX(ov.purchase_date) AS last_order_date,
       MAX(ov.purchase_date) FILTER (WHERE ov.status = 'delivered')
           AS latest_delivered_purchase_date
FROM (
    SELECT DISTINCT customer_unique_id
    FROM staging.customers
) c
LEFT JOIN order_values ov USING (customer_unique_id)
GROUP BY c.customer_unique_id;

CREATE OR REPLACE VIEW analytics.product_summary AS
WITH product_sales AS (
    SELECT p.product_id,
           COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
               AS category,
           COUNT(oi.order_item_id) FILTER (WHERE o.status = 'delivered')
               AS delivered_item_rows,
           COUNT(DISTINCT o.order_id) FILTER (WHERE o.status = 'delivered')
               AS delivered_orders,
           COALESCE(SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered'), 0)
               AS delivered_revenue_brl,
           AVG(oi.price_brl) FILTER (WHERE o.status = 'delivered')
               AS average_selling_price_brl
    FROM staging.products p
    LEFT JOIN staging.order_items oi ON oi.product_id = p.product_id
    LEFT JOIN staging.orders o ON o.order_id = oi.order_id
    GROUP BY p.product_id,
             COALESCE(p.category_name_english, p.category_name, '[Uncategorized]')
),
product_reviews AS (
    SELECT product_id, AVG(review_score)::NUMERIC AS average_review_score,
           COUNT(*) AS review_count
    FROM (
        SELECT DISTINCT oi.product_id, r.review_id, r.order_id, r.review_score
        FROM staging.order_items oi
        JOIN staging.order_reviews r ON r.order_id = oi.order_id
    ) review_events
    GROUP BY product_id
)
SELECT ps.product_id, ps.category, ps.delivered_item_rows, ps.delivered_orders,
       ps.delivered_revenue_brl,
       ROUND(ps.average_selling_price_brl, 2) AS average_selling_price_brl,
       ROUND(pr.average_review_score, 3) AS average_review_score,
       COALESCE(pr.review_count, 0) AS review_count
FROM product_sales ps
LEFT JOIN product_reviews pr USING (product_id);

CREATE OR REPLACE VIEW analytics.seller_summary AS
WITH seller_orders AS (
    SELECT s.seller_id, s.state, o.order_id, o.status,
           o.delivery_duration_hours,
           SUM(oi.price_brl) FILTER (WHERE o.status = 'delivered')
               AS delivered_revenue_brl
    FROM staging.sellers s
    LEFT JOIN staging.order_items oi ON oi.seller_id = s.seller_id
    LEFT JOIN staging.orders o ON o.order_id = oi.order_id
    GROUP BY s.seller_id, s.state, o.order_id, o.status,
             o.delivery_duration_hours
),
seller_metrics AS (
    SELECT seller_id, state,
           COUNT(order_id) AS associated_orders,
           COUNT(order_id) FILTER (WHERE status = 'delivered')
               AS delivered_orders,
           COUNT(order_id) FILTER (WHERE status = 'canceled')
               AS canceled_orders,
           COALESCE(SUM(delivered_revenue_brl), 0::NUMERIC)
               AS delivered_revenue_brl,
           AVG(delivery_duration_hours)
               FILTER (WHERE status = 'delivered'
                       AND delivery_duration_hours >= 0)
               AS average_delivery_hours
    FROM seller_orders
    GROUP BY seller_id, state
),
seller_reviews AS (
    SELECT seller_id, AVG(review_score)::NUMERIC AS average_review_score,
           COUNT(*) AS review_count
    FROM (
        SELECT DISTINCT oi.seller_id, r.review_id, r.order_id, r.review_score
        FROM staging.order_items oi
        JOIN staging.order_reviews r ON r.order_id = oi.order_id
    ) review_events
    GROUP BY seller_id
)
SELECT sm.seller_id, sm.state, sm.associated_orders, sm.delivered_orders,
       sm.canceled_orders, sm.delivered_revenue_brl,
       ROUND(sm.average_delivery_hours::NUMERIC, 2) AS average_delivery_hours,
       ROUND(sr.average_review_score, 3) AS average_review_score,
       COALESCE(sr.review_count, 0) AS review_count
FROM seller_metrics sm
LEFT JOIN seller_reviews sr USING (seller_id);

CREATE OR REPLACE VIEW analytics.monthly_revenue AS
WITH order_values AS (
    SELECT o.order_id, o.purchase_month,
           SUM(oi.price_brl) AS merchandise_revenue_brl,
           SUM(oi.freight_brl) AS freight_brl
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY o.order_id, o.purchase_month
),
monthly_sales AS (
    SELECT purchase_month AS revenue_month,
           COUNT(*) AS delivered_orders,
           SUM(merchandise_revenue_brl) AS merchandise_revenue_brl,
           SUM(freight_brl) AS freight_brl,
           AVG(merchandise_revenue_brl) AS average_order_value_brl
    FROM order_values
    GROUP BY purchase_month
),
month_bounds AS (
    SELECT DATE_TRUNC('month', MIN(purchased_at))::DATE AS first_month,
           DATE_TRUNC('month', MAX(purchased_at))::DATE AS last_month
    FROM staging.orders
),
calendar AS (
    SELECT GENERATE_SERIES(first_month, last_month, INTERVAL '1 month')::DATE
               AS revenue_month
    FROM month_bounds
),
complete_months AS (
    SELECT c.revenue_month,
           COALESCE(ms.delivered_orders, 0) AS delivered_orders,
           COALESCE(ms.merchandise_revenue_brl, 0::NUMERIC)
               AS merchandise_revenue_brl,
           COALESCE(ms.freight_brl, 0::NUMERIC) AS freight_brl,
           ms.average_order_value_brl
    FROM calendar c
    LEFT JOIN monthly_sales ms USING (revenue_month)
)
SELECT revenue_month, delivered_orders, merchandise_revenue_brl, freight_brl,
       ROUND(average_order_value_brl, 2) AS average_order_value_brl,
       SUM(merchandise_revenue_brl) OVER (
           ORDER BY revenue_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS cumulative_revenue_brl,
       ROUND(AVG(merchandise_revenue_brl) OVER (
           ORDER BY revenue_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ), 2) AS rolling_three_month_revenue_brl
FROM complete_months;

CREATE OR REPLACE VIEW analytics.customer_rfm AS
WITH buyer_metrics AS (
    SELECT customer_unique_id, delivered_orders AS frequency,
           delivered_revenue_brl AS monetary_brl,
           (SELECT MAX(purchase_date) + 1 FROM staging.orders)
               - latest_delivered_purchase_date AS recency_days
    FROM analytics.customer_summary
    WHERE delivered_orders > 0
),
recency_scores AS (
    SELECT recency_days,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score
    FROM (SELECT DISTINCT recency_days FROM buyer_metrics) values_by_recency
),
frequency_scores AS (
    SELECT frequency,
           NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score
    FROM (SELECT DISTINCT frequency FROM buyer_metrics) values_by_frequency
),
monetary_scores AS (
    SELECT monetary_brl,
           NTILE(5) OVER (ORDER BY monetary_brl ASC) AS monetary_score
    FROM (SELECT DISTINCT monetary_brl FROM buyer_metrics) values_by_monetary
),
scored AS (
    SELECT bm.*, rs.recency_score, fs.frequency_score, ms.monetary_score
    FROM buyer_metrics bm
    JOIN recency_scores rs USING (recency_days)
    JOIN frequency_scores fs USING (frequency)
    JOIN monetary_scores ms USING (monetary_brl)
)
SELECT customer_unique_id, frequency AS delivered_orders, monetary_brl,
       recency_days, recency_score, frequency_score, monetary_score,
       CASE
           WHEN recency_score >= 4 AND frequency_score >= 4
            AND monetary_score >= 4 THEN 'Champions'
           WHEN recency_score >= 3 AND frequency_score >= 4
               THEN 'Loyal Customers'
           WHEN recency_score >= 4 AND frequency_score >= 2
               THEN 'Potential Loyalists'
           WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
           WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Hibernating'
           WHEN recency_score >= 4 AND frequency_score = 1 THEN 'Recent One-time'
           ELSE 'Needs Attention'
       END AS rfm_segment
FROM scored;

CREATE OR REPLACE VIEW analytics.customer_cohorts AS
WITH delivered_customer_month AS (
    SELECT c.customer_unique_id, o.purchase_month,
           SUM(oi.price_brl) AS delivered_revenue_brl
    FROM staging.orders o
    JOIN staging.customers c ON c.customer_id = o.customer_id
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY c.customer_unique_id, o.purchase_month
),
customer_cohorts AS (
    SELECT customer_unique_id, MIN(purchase_month) AS cohort_month
    FROM delivered_customer_month
    GROUP BY customer_unique_id
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
),
cohort_activity AS (
    SELECT cc.cohort_month, dcm.purchase_month,
           (
               (EXTRACT(YEAR FROM dcm.purchase_month)
                - EXTRACT(YEAR FROM cc.cohort_month)) * 12
               + EXTRACT(MONTH FROM dcm.purchase_month)
               - EXTRACT(MONTH FROM cc.cohort_month)
           )::INTEGER AS months_since_first_purchase,
           COUNT(DISTINCT dcm.customer_unique_id) AS active_customers,
           SUM(dcm.delivered_revenue_brl) AS delivered_revenue_brl
    FROM delivered_customer_month dcm
    JOIN customer_cohorts cc USING (customer_unique_id)
    GROUP BY cc.cohort_month, dcm.purchase_month
)
SELECT ca.cohort_month, ca.purchase_month, ca.months_since_first_purchase,
       cs.cohort_size, ca.active_customers,
       ROUND(100.0 * ca.active_customers / cs.cohort_size, 2) AS retention_pct,
       ca.delivered_revenue_brl
FROM cohort_activity ca
JOIN cohort_sizes cs USING (cohort_month);

CREATE OR REPLACE VIEW analytics.delivery_performance AS
SELECT o.order_id, o.purchase_date, c.customer_unique_id,
       c.state AS customer_state, o.status, o.delivery_duration_hours,
       o.is_late_delivery, o.estimated_delivery_at, o.customer_delivered_at
FROM staging.orders o
JOIN staging.customers c ON c.customer_id = o.customer_id
WHERE o.status = 'delivered';

CREATE OR REPLACE VIEW analytics.monthly_kpis AS
WITH monthly_delivery AS (
    SELECT purchase_month AS revenue_month,
           COUNT(*) FILTER (
               WHERE delivery_duration_hours >= 0
                 AND is_late_delivery IS NOT NULL
           ) AS classified_deliveries,
           COUNT(*) FILTER (
               WHERE delivery_duration_hours >= 0 AND is_late_delivery
           ) AS late_deliveries
    FROM staging.orders
    WHERE status = 'delivered'
    GROUP BY purchase_month
),
monthly_reviews AS (
    SELECT o.purchase_month AS revenue_month,
           COUNT(*) AS review_rows,
           AVG(r.review_score)::NUMERIC AS average_review_score
    FROM staging.orders o
    JOIN staging.order_reviews r ON r.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY o.purchase_month
)
SELECT mr.revenue_month, mr.delivered_orders,
       mr.merchandise_revenue_brl, mr.freight_brl,
       mr.average_order_value_brl,
       md.classified_deliveries, md.late_deliveries,
       ROUND(100.0 * md.late_deliveries
             / NULLIF(md.classified_deliveries, 0), 2) AS late_delivery_rate_pct,
       mrv.review_rows, ROUND(mrv.average_review_score, 3)
           AS average_review_score
FROM analytics.monthly_revenue mr
LEFT JOIN monthly_delivery md USING (revenue_month)
LEFT JOIN monthly_reviews mrv USING (revenue_month);

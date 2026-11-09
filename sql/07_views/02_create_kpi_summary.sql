-- Phase 21: one-row, consistently defined portfolio KPI layer.
CREATE OR REPLACE VIEW analytics.kpi_summary AS
WITH order_kpis AS (
    SELECT COUNT(*) AS all_orders,
           COUNT(*) FILTER (WHERE status = 'delivered') AS delivered_orders,
           COUNT(*) FILTER (WHERE status = 'canceled') AS canceled_orders,
           ROUND(
               100.0 * COUNT(*) FILTER (WHERE status = 'canceled')
               / NULLIF(COUNT(*), 0),
               2
           ) AS cancellation_rate_pct
    FROM staging.orders
),
customer_kpis AS (
    SELECT COUNT(*) AS total_customers,
           COUNT(*) FILTER (WHERE delivered_orders > 0) AS delivered_customers,
           COUNT(*) FILTER (WHERE delivered_orders > 1) AS repeat_customers,
           COALESCE(SUM(delivered_revenue_brl), 0::NUMERIC)
               AS total_revenue_brl,
           ROUND(AVG(delivered_revenue_brl)
                 FILTER (WHERE delivered_orders > 0), 2)
               AS average_revenue_per_delivered_customer_brl
    FROM analytics.customer_summary
),
delivery_kpis AS (
    SELECT COUNT(*) FILTER (
               WHERE delivery_duration_hours >= 0
                 AND is_late_delivery IS NOT NULL
           ) AS classified_deliveries,
           COUNT(*) FILTER (
               WHERE delivery_duration_hours >= 0 AND is_late_delivery
           ) AS late_deliveries,
           ROUND(AVG(delivery_duration_hours)
                 FILTER (WHERE delivery_duration_hours >= 0), 2)
               AS average_delivery_hours
    FROM analytics.delivery_performance
),
review_kpis AS (
    SELECT COUNT(*) AS review_rows,
           ROUND(AVG(review_score)::NUMERIC, 3) AS average_review_score
    FROM staging.order_reviews
),
cohort_sizes AS (
    SELECT DISTINCT cohort_month, cohort_size
    FROM analytics.customer_cohorts
    WHERE months_since_first_purchase = 0
),
last_observed_month AS (
    SELECT MAX(purchase_month) AS latest_month
    FROM staging.orders
),
month_one_retention AS (
    SELECT ROUND(
               100.0 * SUM(COALESCE(month_one.active_customers, 0))
               / NULLIF(SUM(cohort_sizes.cohort_size), 0),
               2
           ) AS customer_retention_rate_pct
    FROM cohort_sizes
    CROSS JOIN last_observed_month
    LEFT JOIN analytics.customer_cohorts month_one
        ON month_one.cohort_month = cohort_sizes.cohort_month
       AND month_one.months_since_first_purchase = 1
    WHERE cohort_sizes.cohort_month + INTERVAL '1 month'
          <= last_observed_month.latest_month
),
top_category AS (
    SELECT category
    FROM analytics.product_summary
    GROUP BY category
    ORDER BY SUM(delivered_revenue_brl) DESC, category
    LIMIT 1
),
top_customer_segment AS (
    SELECT rfm_segment
    FROM analytics.customer_rfm
    GROUP BY rfm_segment
    ORDER BY COUNT(*) DESC, rfm_segment
    LIMIT 1
),
snapshot_date AS (
    SELECT MAX(purchase_date) + 1 AS as_of_date
    FROM staging.orders
)
SELECT snapshot_date.as_of_date,
       order_kpis.all_orders,
       order_kpis.delivered_orders,
       customer_kpis.total_customers,
       customer_kpis.delivered_customers,
       customer_kpis.total_revenue_brl,
       ROUND(
           customer_kpis.total_revenue_brl
           / NULLIF(order_kpis.delivered_orders, 0),
           2
       ) AS average_order_value_brl,
       customer_kpis.average_revenue_per_delivered_customer_brl
           AS revenue_per_delivered_customer_brl,
       customer_kpis.repeat_customers,
       ROUND(
           100.0 * customer_kpis.repeat_customers
           / NULLIF(customer_kpis.delivered_customers, 0),
           2
       ) AS repeat_customer_rate_pct,
       month_one_retention.customer_retention_rate_pct,
       order_kpis.canceled_orders,
       order_kpis.cancellation_rate_pct,
       delivery_kpis.average_delivery_hours,
       delivery_kpis.late_deliveries,
       delivery_kpis.classified_deliveries,
       ROUND(
           100.0 * delivery_kpis.late_deliveries
           / NULLIF(delivery_kpis.classified_deliveries, 0),
           2
       ) AS late_delivery_rate_pct,
       review_kpis.review_rows,
       review_kpis.average_review_score,
       top_category.category AS top_product_category,
       top_customer_segment.rfm_segment AS top_customer_segment
FROM order_kpis
CROSS JOIN customer_kpis
CROSS JOIN delivery_kpis
CROSS JOIN review_kpis
CROSS JOIN month_one_retention
CROSS JOIN top_category
CROSS JOIN top_customer_segment
CROSS JOIN snapshot_date;

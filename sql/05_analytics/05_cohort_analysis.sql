-- Phase 11: monthly customer cohorts and delivered-sales activity.
-- Cohort = first month with a delivered order by customer_unique_id.
-- Retention is customers with >=1 delivered order in a cohort-relative month.
WITH delivered_customer_month AS (
    SELECT c.customer_unique_id, o.purchase_month,
           SUM(oi.price_brl) AS delivered_merchandise_brl
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
           SUM(dcm.delivered_merchandise_brl) AS delivered_merchandise_brl
    FROM delivered_customer_month dcm
    JOIN customer_cohorts cc USING (customer_unique_id)
    GROUP BY cc.cohort_month, dcm.purchase_month
)
SELECT ca.cohort_month, ca.purchase_month, ca.months_since_first_purchase,
       cs.cohort_size, ca.active_customers,
       ROUND(100.0 * ca.active_customers / cs.cohort_size, 2)
           AS retention_pct,
       ca.delivered_merchandise_brl
FROM cohort_activity ca
JOIN cohort_sizes cs USING (cohort_month)
ORDER BY ca.cohort_month, ca.months_since_first_purchase;

-- Cohort-level summary: initial size and repeat activity within available data.
WITH delivered_customer_month AS (
    SELECT c.customer_unique_id, o.purchase_month,
           SUM(oi.price_brl) AS revenue
    FROM staging.orders o
    JOIN staging.customers c ON c.customer_id = o.customer_id
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY c.customer_unique_id, o.purchase_month
),
cohorts AS (
    SELECT customer_unique_id, MIN(purchase_month) AS cohort_month
    FROM delivered_customer_month
    GROUP BY customer_unique_id
),
cohort_activity AS (
    SELECT c.cohort_month, d.purchase_month,
           COUNT(DISTINCT d.customer_unique_id) AS active_customers,
           SUM(d.revenue) AS revenue
    FROM delivered_customer_month d
    JOIN cohorts c USING (customer_unique_id)
    GROUP BY c.cohort_month, d.purchase_month
)
SELECT cohort_month,
       MAX(active_customers) FILTER (
           WHERE purchase_month = cohort_month
       ) AS cohort_size,
       SUM(active_customers) FILTER (
           WHERE purchase_month > cohort_month
       ) AS repeat_customer_months,
       SUM(revenue) AS cohort_delivered_revenue_brl,
       COUNT(*) AS observed_cohort_months
FROM cohort_activity
GROUP BY cohort_month
ORDER BY cohort_month;

-- Pooled month-one retention includes every cohort with a fully observable
-- month one, including cohorts with zero returning customers in that month.
WITH delivered_customer_month AS (
    SELECT c.customer_unique_id, o.purchase_month
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
month_one_activity AS (
    SELECT cc.cohort_month,
           COUNT(DISTINCT dcm.customer_unique_id) AS active_customers
    FROM customer_cohorts cc
    JOIN delivered_customer_month dcm
      ON dcm.customer_unique_id = cc.customer_unique_id
     AND dcm.purchase_month = cc.cohort_month + INTERVAL '1 month'
    GROUP BY cc.cohort_month
),
last_observed_month AS (
    SELECT MAX(purchase_month) AS latest_month
    FROM staging.orders
)
SELECT COUNT(*) AS eligible_cohorts,
       SUM(cs.cohort_size) AS eligible_customers,
       SUM(COALESCE(m1.active_customers, 0)) AS month_one_returning_customers,
       ROUND(
           100.0 * SUM(COALESCE(m1.active_customers, 0))
           / NULLIF(SUM(cs.cohort_size), 0),
           2
       ) AS pooled_month_one_retention_pct
FROM cohort_sizes cs
CROSS JOIN last_observed_month lom
LEFT JOIN month_one_activity m1 USING (cohort_month)
WHERE cs.cohort_month + INTERVAL '1 month' <= lom.latest_month;

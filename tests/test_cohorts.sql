-- Phase 11: cohort retention and revenue must reconcile to delivered activity.
DO $$
DECLARE
    delivered_revenue NUMERIC;
    cohort_revenue NUMERIC;
    invalid_month_zero BIGINT;
    invalid_retention BIGINT;
    eligible_cohorts BIGINT;
    eligible_cohort_customers BIGINT;
    month_one_customers BIGINT;
BEGIN
    SELECT SUM(oi.price_brl)
    INTO delivered_revenue
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered';

    WITH customer_month AS (
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
        FROM customer_month
        GROUP BY customer_unique_id
    ),
    activity AS (
        SELECT h.cohort_month, m.purchase_month,
               COUNT(DISTINCT m.customer_unique_id) AS active_customers,
               SUM(m.revenue) AS revenue
        FROM customer_month m
        JOIN cohorts h USING (customer_unique_id)
        GROUP BY h.cohort_month, m.purchase_month
    ),
    sizes AS (
        SELECT cohort_month, COUNT(*) AS cohort_size
        FROM cohorts
        GROUP BY cohort_month
    )
    SELECT SUM(revenue),
           COUNT(*) FILTER (
               WHERE purchase_month = cohort_month
                 AND active_customers <> cohort_size
           ),
           COUNT(*) FILTER (
               WHERE active_customers > cohort_size
                  OR active_customers < 0
           )
    INTO cohort_revenue, invalid_month_zero, invalid_retention
    FROM activity
    JOIN sizes USING (cohort_month);

    IF cohort_revenue <> delivered_revenue THEN
        RAISE EXCEPTION 'Cohort revenue does not reconcile to delivered sales';
    END IF;
    IF invalid_month_zero <> 0 OR invalid_retention <> 0 THEN
        RAISE EXCEPTION 'Cohort month zero or retention counts are invalid';
    END IF;

    WITH customer_month AS (
        SELECT c.customer_unique_id, o.purchase_month
        FROM staging.orders o
        JOIN staging.customers c ON c.customer_id = o.customer_id
        JOIN staging.order_items oi ON oi.order_id = o.order_id
        WHERE o.status = 'delivered'
        GROUP BY c.customer_unique_id, o.purchase_month
    ),
    cohorts AS (
        SELECT customer_unique_id, MIN(purchase_month) AS cohort_month
        FROM customer_month
        GROUP BY customer_unique_id
    ),
    sizes AS (
        SELECT cohort_month, COUNT(*) AS cohort_size
        FROM cohorts
        GROUP BY cohort_month
    ),
    month_one AS (
        SELECT h.cohort_month,
               COUNT(DISTINCT m.customer_unique_id) AS active_customers
        FROM cohorts h
        JOIN customer_month m
          ON m.customer_unique_id = h.customer_unique_id
         AND m.purchase_month = h.cohort_month + INTERVAL '1 month'
        GROUP BY h.cohort_month
    ),
    latest_month AS (
        SELECT MAX(purchase_month) AS latest_month
        FROM staging.orders
    )
    SELECT COUNT(*), SUM(s.cohort_size),
           SUM(COALESCE(m1.active_customers, 0))
    INTO eligible_cohorts, eligible_cohort_customers, month_one_customers
    FROM sizes s
    CROSS JOIN latest_month lm
    LEFT JOIN month_one m1 USING (cohort_month)
    WHERE s.cohort_month + INTERVAL '1 month' <= lm.latest_month;

    IF eligible_cohorts = 0 OR eligible_cohort_customers = 0
       OR month_one_customers > eligible_cohort_customers THEN
        RAISE EXCEPTION 'Pooled month-one cohort denominator is invalid';
    END IF;
END
$$;

SELECT 'Cohort reconciliation checks passed' AS result;

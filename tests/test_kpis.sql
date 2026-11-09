-- Phase 21 checks: KPI definitions reconcile to the underlying views/tables
-- and all percentage KPIs remain within 0-100.
DO $$
DECLARE
    kpi RECORD;
    expected_revenue NUMERIC;
    expected_average_order_value NUMERIC;
    expected_retention NUMERIC;
    expected_late_rate NUMERIC;
BEGIN
    SELECT * INTO kpi FROM analytics.kpi_summary;

    SELECT SUM(merchandise_revenue_brl)
    INTO expected_revenue
    FROM analytics.monthly_revenue;

    SELECT ROUND(
               expected_revenue
               / NULLIF((SELECT COUNT(*) FROM staging.orders
                         WHERE status = 'delivered'), 0),
               2
           )
    INTO expected_average_order_value;

    SELECT ROUND(
               100.0 * SUM(COALESCE(month_one.active_customers, 0))
               / NULLIF(SUM(cohorts.cohort_size), 0),
               2
           )
    INTO expected_retention
    FROM (
        SELECT DISTINCT cohort_month, cohort_size
        FROM analytics.customer_cohorts
        WHERE months_since_first_purchase = 0
          AND cohort_month + INTERVAL '1 month'
              <= (SELECT MAX(purchase_month) FROM staging.orders)
    ) cohorts
    LEFT JOIN analytics.customer_cohorts month_one
      ON month_one.cohort_month = cohorts.cohort_month
     AND month_one.months_since_first_purchase = 1;

    SELECT ROUND(
               100.0 * COUNT(*) FILTER (
                   WHERE delivery_duration_hours >= 0 AND is_late_delivery
               )
               / NULLIF(COUNT(*) FILTER (
                   WHERE delivery_duration_hours >= 0
                     AND is_late_delivery IS NOT NULL
               ), 0),
               2
           )
    INTO expected_late_rate
    FROM analytics.delivery_performance;

    IF kpi.total_revenue_brl <> expected_revenue
       OR kpi.average_order_value_brl <> expected_average_order_value
       OR kpi.customer_retention_rate_pct
            IS DISTINCT FROM expected_retention
       OR kpi.late_delivery_rate_pct IS DISTINCT FROM expected_late_rate THEN
        RAISE EXCEPTION 'KPI layer does not reconcile to source metrics';
    END IF;

    IF kpi.repeat_customer_rate_pct NOT BETWEEN 0 AND 100
       OR kpi.customer_retention_rate_pct NOT BETWEEN 0 AND 100
       OR kpi.cancellation_rate_pct NOT BETWEEN 0 AND 100
       OR kpi.late_delivery_rate_pct NOT BETWEEN 0 AND 100
       OR kpi.top_product_category IS NULL
       OR kpi.top_customer_segment IS NULL THEN
        RAISE EXCEPTION 'KPI rate or ranking bounds are invalid';
    END IF;
END
$$;

SELECT 'KPI layer checks passed' AS result;

-- Phase 18 assertions for view coverage, grain, and revenue reconciliation.
DO $$
DECLARE
    expected_customers BIGINT;
    summarized_customers BIGINT;
    expected_products BIGINT;
    summarized_products BIGINT;
    expected_sellers BIGINT;
    summarized_sellers BIGINT;
    delivered_revenue NUMERIC;
    customer_revenue NUMERIC;
    product_revenue NUMERIC;
    seller_revenue NUMERIC;
    monthly_revenue NUMERIC;
    monthly_kpi_revenue NUMERIC;
    monthly_count BIGINT;
    monthly_kpi_count BIGINT;
    cohort_month_zero_mismatches BIGINT;
    invalid_rfm_scores BIGINT;
    invalid_retention BIGINT;
    invalid_kpi_rates BIGINT;
    delivery_orders BIGINT;
BEGIN
    SELECT COUNT(DISTINCT customer_unique_id)
    INTO expected_customers
    FROM staging.customers;
    SELECT COUNT(*) INTO summarized_customers FROM analytics.customer_summary;

    SELECT COUNT(*) INTO expected_products FROM staging.products;
    SELECT COUNT(*) INTO summarized_products FROM analytics.product_summary;

    SELECT COUNT(*) INTO expected_sellers FROM staging.sellers;
    SELECT COUNT(*) INTO summarized_sellers FROM analytics.seller_summary;

    SELECT SUM(oi.price_brl)
    INTO delivered_revenue
    FROM staging.orders o
    JOIN staging.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered';

    SELECT SUM(delivered_revenue_brl)
    INTO customer_revenue
    FROM analytics.customer_summary;
    SELECT SUM(delivered_revenue_brl)
    INTO product_revenue
    FROM analytics.product_summary;
    SELECT SUM(delivered_revenue_brl)
    INTO seller_revenue
    FROM analytics.seller_summary;
    SELECT SUM(merchandise_revenue_brl)
    INTO monthly_revenue
    FROM analytics.monthly_revenue;
    SELECT SUM(merchandise_revenue_brl), COUNT(*)
    INTO monthly_kpi_revenue, monthly_kpi_count
    FROM analytics.monthly_kpis;
    SELECT COUNT(*) INTO monthly_count FROM analytics.monthly_revenue;

    SELECT COUNT(*)
    INTO cohort_month_zero_mismatches
    FROM analytics.customer_cohorts
    WHERE months_since_first_purchase = 0
      AND active_customers <> cohort_size;

    SELECT COUNT(*)
    INTO invalid_rfm_scores
    FROM analytics.customer_rfm
    WHERE recency_score NOT BETWEEN 1 AND 5
       OR frequency_score NOT BETWEEN 1 AND 5
       OR monetary_score NOT BETWEEN 1 AND 5;

    SELECT COUNT(*)
    INTO invalid_retention
    FROM analytics.customer_cohorts
    WHERE retention_pct < 0 OR retention_pct > 100;

    SELECT COUNT(*)
    INTO invalid_kpi_rates
    FROM analytics.monthly_kpis
    WHERE late_delivery_rate_pct < 0 OR late_delivery_rate_pct > 100;

    SELECT COUNT(*) INTO delivery_orders
    FROM analytics.delivery_performance;

    IF expected_customers <> summarized_customers
       OR expected_products <> summarized_products
       OR expected_sellers <> summarized_sellers THEN
        RAISE EXCEPTION 'Analytics summary views have incomplete entity coverage';
    END IF;

    IF delivered_revenue <> customer_revenue
       OR delivered_revenue <> product_revenue
       OR delivered_revenue <> seller_revenue
       OR delivered_revenue <> monthly_revenue
       OR delivered_revenue <> monthly_kpi_revenue
       OR monthly_count <> monthly_kpi_count THEN
        RAISE EXCEPTION 'Analytics view revenue does not reconcile';
    END IF;

    IF cohort_month_zero_mismatches <> 0 OR invalid_rfm_scores <> 0
       OR invalid_retention <> 0 OR invalid_kpi_rates <> 0
       OR delivery_orders = 0 THEN
        RAISE EXCEPTION 'Analytics view cohort, RFM, or delivery check failed';
    END IF;
END
$$;

SELECT 'Analytics view checks passed' AS result;

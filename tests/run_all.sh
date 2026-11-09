#!/usr/bin/env bash
set -euo pipefail

run_sql() {
    docker compose exec -T db psql -X -P pager=off -U user -d olist \
        -v ON_ERROR_STOP=1 < "$1"
}

run_sql sql/07_views/01_create_analytics_views.sql
run_sql sql/07_views/02_create_kpi_summary.sql
run_sql sql/08_indexes/01_analytical_indexes.sql

run_sql tests/test_staging.sql
run_sql tests/test_data_quality.sql
run_sql tests/test_relationships.sql
run_sql tests/test_exploration.sql
run_sql tests/test_revenue.sql
run_sql tests/test_customers.sql
run_sql tests/test_customer_segmentation.sql
run_sql tests/test_cohorts.sql
run_sql tests/test_clv.sql
run_sql tests/test_products.sql
run_sql tests/test_sellers.sql
run_sql tests/test_delivery.sql
run_sql tests/test_customer_satisfaction.sql
run_sql tests/test_advanced_sql.sql
run_sql tests/test_analytics_views.sql
run_sql tests/test_performance.sql
run_sql tests/test_kpis.sql

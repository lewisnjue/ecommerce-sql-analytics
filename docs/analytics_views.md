# Phase 18 — Analytical Views

The eight reusable reporting views are created in the `analytics` schema by
[sql/07_views/01_create_analytics_views.sql](../sql/07_views/01_create_analytics_views.sql).
They are regular PostgreSQL views over `staging`, so they reflect the current
staging rows and do not require a separate refresh. Create or replace them
after the staging schema has been created and loaded.

| View | Grain and purpose |
|---|---|
| `analytics.customer_summary` | One row per `customer_unique_id`; order counts, delivered merchandise value, order-value average, and date bounds. |
| `analytics.product_summary` | One row per product; delivered item/order sales and distinct product/review associations. |
| `analytics.seller_summary` | One row per seller; order-grain sales, delivery and distinct review associations. |
| `analytics.monthly_revenue` | One row per calendar month; delivered merchandise revenue, freight, order value, cumulative revenue, and trailing three-month revenue average. Zero-sales months are retained. |
| `analytics.customer_rfm` | One row per customer with a delivered order; recency/frequency/monetary values, tie-preserving scores, and segment. |
| `analytics.customer_cohorts` | One row per observed cohort/activity month; cohort size, active customers, retention, and delivered revenue. Missing activity months are not zero-filled. |
| `analytics.delivery_performance` | One row per delivered order; delivery duration/classification, date fields, and customer destination state. Missing delivery values are retained. |
| `analytics.monthly_kpis` | One row per calendar month, combining sales, classified late-delivery rate, and delivered-order review averages by purchase month. |

Primary sales measures use delivered item `price_brl` and exclude freight;
freight is a separate measure. Review metrics use review rows, and multivalue
associations are deduplicated at review/product or review/seller grain. RFM
scoring and cohort definitions follow the methods documented in their
respective analysis reports.

Create and validate the views:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/07_views/01_create_analytics_views.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_analytics_views.sql
```

`tests/test_analytics_views.sql` passed. It verifies entity coverage and
reconciles delivered merchandise revenue across customer, product, seller,
monthly revenue, and KPI views. It also checks cohort month-zero retention,
RFM score bounds, retention percentages, late-rate bounds, and delivery-view
coverage.

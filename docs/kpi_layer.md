# Phase 21 — KPI Layer

The consistent snapshot KPI view is `analytics.kpi_summary`, created by
[sql/07_views/02_create_kpi_summary.sql](../sql/07_views/02_create_kpi_summary.sql).
It is a one-row view over the Phase 18 analytical views and staging data.
The monthly time-series interface remains `analytics.monthly_kpis`.

## Definitions, SQL outputs, and interpretation

| KPI | Definition / view field | Business interpretation |
|---|---|---|
| Total revenue | `total_revenue_brl`: delivered item `price_brl`, excluding freight | Historical merchandise sales fulfilled as delivered; not gross payment volume or profit. |
| Total orders | `all_orders`; `delivered_orders` is reported separately | All orders describe workload; delivered orders are the denominator for AOV. |
| Total customers | Distinct `customer_unique_id` in `analytics.customer_summary` | Person-level customer count; not order-specific `customer_id`. |
| Average order value | `total_revenue_brl / delivered_orders` | Average delivered merchandise sales per delivered order; freight excluded. |
| Revenue per delivered customer | `revenue_per_delivered_customer_brl` | Average delivered merchandise sales among customers with at least one delivered order. |
| Repeat customer rate | Delivered buyers with more than one delivered order / delivered buyers | A delivered-order repeat rate; differs from Phase 9's repeat rate, which counts all orders. |
| Customer retention rate | Pooled Month 1 active customers / customers in cohorts whose Month 1 is observable | Weighted first-follow-up-month return rate; eligible cohorts with zero activity remain in the denominator. |
| Cancellation rate | Canceled orders / all orders | Order-level cancellation share across the full dataset. |
| Average delivery time | Mean non-negative purchase-to-delivery hours for delivered orders | Elapsed time, not business days; rows without a valid duration are excluded. |
| Late delivery rate | Late deliveries / deliveries with a valid duration and known on-time/late classification | Share of classifiable deliveries recorded later than the estimate. |
| Average review score | Mean across all available review rows | Review-level satisfaction measure; an order can have multiple review rows. |
| Top product category | Category with highest delivered merchandise sales | Historical sales leader, not the most profitable or highest-rated category. |
| Top customer segment | Largest RFM segment by buyer count | Most common segment under the documented RFM scoring rules, not a value ranking. |

The snapshot reference date is one day after the last purchase date in the
dataset, **2018-10-18**. This makes recency and KPI reproduction stable rather
than dependent on the current system date.

## Current database results

| KPI | Result |
|---|---:|
| All orders / delivered orders | 99,441 / 96,478 |
| Total customers / delivered customers | 96,096 / 93,358 |
| Delivered merchandise revenue | R$ 13,221,498.11 |
| Average delivered order value | R$ 137.04 |
| Revenue per delivered customer | R$ 141.62 |
| Repeat delivered customers / rate | 2,801 / 3.00% |
| Pooled Month 1 retention | 421 / 93,358 customers across 23 eligible cohorts (0.45%) |
| Canceled orders / rate | 625 / 0.63% |
| Average delivery time | 301.40 hours |
| Late deliveries / rate | 7,826 / 96,470 classifiable deliveries (8.11%) |
| Review rows / average score | 99,224 / 4.086 out of 5 |
| Top product category | `health_beauty`, R$ 1,233,131.72 |
| Largest customer segment | `Recent One-time`, 51,751 customers |

Phase 9's 3.12% repeat rate uses all order statuses; the KPI's 3.00% specifically
requires repeat delivered orders. The Month 1 figure uses the corrected
zero-activity-inclusive cohort denominator described in
[docs/cohort_analysis.md](cohort_analysis.md); the prior 0.48% calculation
excluded eligible cohorts that had no observed Month 1 return.

Create and validate the KPI view:

```bash
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < sql/07_views/02_create_kpi_summary.sql
docker compose exec -T db psql -X -U user -d olist -v ON_ERROR_STOP=1 < tests/test_kpis.sql
docker compose exec -T db psql -X -U user -d olist -c "SELECT * FROM analytics.kpi_summary"
```

`tests/test_kpis.sql` passed. It reconciles revenue, AOV, retention, and late
rate to their source views, and checks that percentage KPIs and ranked labels
are valid.
